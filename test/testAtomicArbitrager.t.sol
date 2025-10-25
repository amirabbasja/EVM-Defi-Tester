// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {AtomicArbitrage} from "../src/AtomicArbitrage.sol";

// Exchange deployers
import {UniswapV2Deployer} from "../script/UniswapV2Deployer.s.sol";
import {UniswapV3Deployer} from "../script/UniswapV3Deployer.s.sol";

// Interfaces
import {IMockWETH9} from "./interfaces/IMockWETH9.sol";
import {IMockERC20} from "./interfaces/IMockERC20.sol";

// Interfaces - Uniswap v2
import {IUniswapV2Factory}  from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Router01} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {IUniswapV2Pair} from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// Interfaces - Uniswap v3
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {ISwapRouter02} from "./interfaces/ISwapRouter02.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {INonfungibleTokenPositionDescriptor} from "./interfaces/INonfungibleTokenPositionDescriptor.sol";
import {IUniswapV3Pool} from "../lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract AtomicArbitragerTester is Test {
    // Addresses
    // Addresses - General
    address constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address immutable TESTER_ADDRESS = makeAddr("tester"); // The owner of the AtomicArbitrager contract

    // Addresses - Uniswap V2
    address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant UNISWAP_V2_ROUTER02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address uniswapV2WETHUSDTPair;

    // Addresses - Uniswap V3
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_V3_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant UNISWAP_V3_POSITION_DESCRIPTOR = 0x91ae842A5Ffd8d12023116943e72A606179294f3;
    address constant UNISWAP_V3_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant UNISWAP_V3_NFTDESCRIPTOR = 0x42B24A95702b9986e82d421cC3568932790A48Ec;
    address uniswapV3WETHUSDTPair;

    // Necessary variables
    AtomicArbitrage atomicArbitrager;

    // Tokens
    IMockWETH9 WETH;
    IMockERC20 USDT;

    // Modifiers
    // Modifiers - Uniswap v2 pool deployment
    modifier WithDeployedUniswapV2Pool() {
        vm.deal(address(this), 10 ether);
        USDT.approve(UNISWAP_V2_ROUTER02, type(uint256).max);
        IUniswapV2Router02(UNISWAP_V2_ROUTER02).addLiquidityETH{value: 10 ether}(
            address(USDT),
            USDT.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1000
        );
        uniswapV2WETHUSDTPair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(USDT_MAINNET, WETH_MAINNET);
        _;
    }

    // Modifiers - Uniswap v3 pool deployment
    modifier WithDeployedUniswapV3Pool() {
        IUniswapV3Factory uniV3Factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        INonfungiblePositionManager uniV3PositionManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);

        // Ensure we have ETH to wrap as WETH
        vm.deal(address(this), 100 ether);

        // Create and initialize the WETH/USDT pool at 0.05% fee via NPM
        uint24 fee = 500;
        uint160 sqrtPriceX96 = uint160(2**96);
        address pool = uniV3PositionManager.createAndInitializePoolIfNecessary(
            WETH_MAINNET,
            USDT_MAINNET,
            fee,
            sqrtPriceX96
        );
        assert(pool != address(0));
        assert(address(pool).code.length > 0);
        // Assert factory mapping agrees with the created pool
        assertEq(uniV3Factory.getPool(WETH_MAINNET, USDT_MAINNET, fee), pool);

        // Prepare tokens: wrap ETH to WETH and mint USDT to this contract
        uint256 amount0Desired = 1 ether;
        uint256 amount1Desired = 1 ether;
        WETH.deposit{value: amount0Desired}();
        USDT.mint(address(this), amount1Desired);

        // Approve position manager to pull tokens
        WETH.approve(address(uniV3PositionManager), type(uint256).max);
        USDT.approve(address(uniV3PositionManager), type(uint256).max);

        // Set a wide tick range based on factory tick spacing
        int24 spacing = uniV3Factory.feeAmountTickSpacing(fee);
        int24 tickLower = -spacing * 100;
        int24 tickUpper = spacing * 100;

        // Mint the position
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: WETH_MAINNET,
            token1: USDT_MAINNET,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1000
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = uniV3PositionManager.mint(params);
        uniswapV3WETHUSDTPair = pool;
        _;
    }

    function setUp() public {
        // Deploy tokens
        // WETH
        deployCodeTo(
            "MockWETH9.sol",
            abi.encode("Wrapper Ether", "WETH", 18),
            WETH_MAINNET
        );
        WETH = IMockWETH9(WETH_MAINNET);
        // USDT
        deployCodeTo(
            "MockERC20.sol",
            abi.encode("Tether Usdt", "USDT", 6),
            USDT_MAINNET
        );
        USDT = IMockERC20(USDT_MAINNET);
        USDT.mint(address(this), 1_000_000 * 10 ** 6); // Add some intial balance to the tester contract

        // Deploy exchanges
        UniswapV2Deployer uniswapV2Deployer = new UniswapV2Deployer();
        UniswapV3Deployer uniswapV3Deployer = new UniswapV3Deployer();
        uniswapV2Deployer.run();        
        uniswapV3Deployer.run();

        // Deploy Arbitrager by impersonating TESTER_ADDRESS
        vm.startPrank(TESTER_ADDRESS);
        atomicArbitrager = new AtomicArbitrage(
            address(address(WETH)), // WETH9 address
            address(address(UNISWAP_V2_ROUTER02)), // UniswapV2Router02 address
            address(address(UNISWAP_V3_ROUTER))  // UniswapV3Router02 address
        );
        vm.stopPrank();
    }

    function test_WrapETHToWETH() public {
        // Note, ethereum is wrapped into the caller contract (AtomicArbitrager)
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        assertEq(WETH.balanceOf(address(atomicArbitrager)), 1 ether);
        vm.stopPrank();
    }

    function test_UnwrapWETHtoETH() public {
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);

        assertEq(address(TESTER_ADDRESS).balance, 9 ether);
        atomicArbitrager._unwrapETH(1 ether);
        assertEq(address(TESTER_ADDRESS).balance, 10 ether);
        vm.stopPrank();
    }

    function test_MakeASingleSwapOnUniswapV2() WithDeployedUniswapV2Pool public {
        console.log("Uniswp v2 WETH/USDT pool address:", uniswapV2WETHUSDTPair);
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        // Wrap 1 ETH to WETH
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        assertEq(WETH.balanceOf(address(atomicArbitrager)), 1 ether);

        // Make swap WETH -> USDT
        AtomicArbitrage.SwapParams memory swapParams = AtomicArbitrage.SwapParams({
            tokenIn: WETH_MAINNET,
            tokenOut: USDT_MAINNET,
            amountIn: 1 ether,
            recipient: address(atomicArbitrager),
            deadline: block.timestamp + 300,
            extra: abi.encode()
        });

        atomicArbitrager._swapUniswapV2(swapParams);
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();
    }

    function test_MakeASingleSwapOnUniswapV3() WithDeployedUniswapV3Pool public {
        console.log("Uniswp v3 WETH/USDT pool address:", uniswapV3WETHUSDTPair);
        
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        // Wrap 1 ETH to WETH
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        assertEq(WETH.balanceOf(address(atomicArbitrager)), 1 ether);

        // Make swap WETH -> USDT
        AtomicArbitrage.SwapParams memory swapParams = AtomicArbitrage.SwapParams({
            tokenIn: WETH_MAINNET,
            tokenOut: USDT_MAINNET,
            amountIn: 1 ether,
            recipient: address(atomicArbitrager),
            deadline: block.timestamp + 300,
            extra: abi.encode(500 ,0 ,0) // TODO: Made the fee fixed to 500. Make it modular later
        });

        atomicArbitrager._swapUniswapV3(swapParams);
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        console.log("USDT balance after swap:", USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();
    }

    function test_makSwapFunction() public 
        WithDeployedUniswapV2Pool 
        WithDeployedUniswapV3Pool 
    {
        // Uniswap v2
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        atomicArbitrager._makeSwap(
            0,
            AtomicArbitrage.SwapParams({
                tokenIn: WETH_MAINNET,
                tokenOut: USDT_MAINNET,
                amountIn: 1 ether,
                recipient: address(atomicArbitrager),
                deadline: block.timestamp + 300,
                extra: abi.encode()
            })
        );
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();

        // Uniswap v3        
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        atomicArbitrager._makeSwap(
            1,
            AtomicArbitrage.SwapParams({
                tokenIn: WETH_MAINNET,
                tokenOut: USDT_MAINNET,
                amountIn: 1 ether,
                recipient: address(atomicArbitrager),
                deadline: block.timestamp + 300,
                extra: abi.encode(500 ,0 ,0)
            })
        );
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();
    }
}