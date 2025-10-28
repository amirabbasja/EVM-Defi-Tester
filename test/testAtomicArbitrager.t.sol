// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {AtomicArbitrage} from "../src/AtomicArbitrage.sol";

// Exchange deployers
import {UniswapV2Deployer} from "../script/UniswapV2Deployer.s.sol";
import {UniswapV3Deployer} from "../script/UniswapV3Deployer.s.sol";
import {SushiswapV2Deployer} from "../script/SushiswapV2Deployer.s.sol";
import {SushiswapV3Deployer} from "../script/SushiswapV3Deployer.s.sol";
import {CamelotV2Deployer} from "../script/CamelotV2Deployer.s.sol";
import {CamelotV3Deployer} from "../script/CamelotV3Deployer.s.sol";


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

// Interfaces - Sushiswap v2
// (Sushiswap v2 uses the same interfaces as Uniswap v2)

// Interfaces - Sushiswap v3
// (Sushiswap v3 uses the same interfaces as Uniswap v3)
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";

// Interfaces - Camelot v2
import {ICamelotFactory}  from "../lib/camelot-v2-core/contracts/interfaces/ICamelotFactory.sol";
import {ICamelotRouter} from "../lib/camelot-v2-periphery/contracts/interfaces/ICamelotRouter.sol";
import {ICamelotPair} from "../lib/camelot-v2-core/contracts/interfaces/ICamelotPair.sol";

// Interfaces - Camelot v3
import {IAlgebraFactoryCamelotV3} from "./interfaces/IAlgebraFactoryCamelotV3.sol";
import {IAlgebraPoolCamelotV3} from "./interfaces/IAlgebraPoolCamelotV3.sol";
import {INonfungiblePositionManagerCamelotV3} from "./interfaces/INonfungiblePositionManagerCamelotV3.sol";
import {ISwapRouterCamelotV3} from "./interfaces/ISwapRouterCamelotV3.sol";

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

    // Addresses - Sushiswap v2
    address constant SUSHISWAP_V2_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address constant SUSHISWAP_V2_ROUTER02 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address sushiswapV2WETHUSDTPair;

    // Addresses - Sushiswap v3
    address constant SUSHISWAP_V3_FACTORY = 0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F;
    address constant SUSHISWAP_V3_POSITION_MANAGER = 0x2214A42d8e2A1d20635c2cb0664422c528B6A432;
    address constant SUSHISWAP_V3_ROUTER = 0x2E6cd2d30aa43f40aa81619ff4b6E0a41479B13F;
    address sushiswapV3WETHUSDTPair;

    // Addresses - Camelot V2
    address constant CAMELOT_V2_FACTORY = 0x6EcCab422D763aC031210895C81787E87B43A652;
    address constant CAMELOT_V2_ROUTER = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    address camelotV2WETHUSDTPair;

    // Addresses - Camelot V2
    address constant CAMELOT_V3_FACTORY = 0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B;
    address constant CAMELOT_V3_POSITION_MANAGER = 0x00c7f3082833e796A5b3e4Bd59f6642FF44DCD15;
    address constant CAMELOT_V3_ROUTER = 0x1F721E2E82F6676FCE4eA07A5958cF098D339e18;
    address camelotV3WETHUSDTPair;

    // Necessary variables
    AtomicArbitrage atomicArbitrager;

    // Tokens
    IMockWETH9 WETH;
    IMockERC20 USDT;

    // Modifiers
    // Modifiers - Uniswap v2 pool deployment
    modifier WithDeployedUniswapV2Pool() {
        vm.deal(address(this), 10 ether);
        // Ensure we have non-zero USDT explicitly for the first mint
        uint256 usdtAmount = 10_000 * 10 ** 6; // 10k USDT with 6 decimals
        USDT.mint(address(this), usdtAmount);
        USDT.approve(UNISWAP_V2_ROUTER02, type(uint256).max);
        IUniswapV2Router02(UNISWAP_V2_ROUTER02).addLiquidityETH{value: 10 ether}(
            address(USDT),
            usdtAmount,
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

    // Modifiers - Sushiswap v2 pool deployment
    modifier WithDeployedSushiswapV2Pool() {
        vm.deal(address(this), 10 ether);
        // Ensure we have non-zero USDT explicitly for the first mint
        uint256 usdtAmount = 10_000 * 10 ** 6; // 10k USDT with 6 decimals
        USDT.mint(address(this), usdtAmount);
        USDT.approve(SUSHISWAP_V2_ROUTER02, type(uint256).max);
        IUniswapV2Router02(SUSHISWAP_V2_ROUTER02).addLiquidityETH{value: 10 ether}(
            address(USDT),
            usdtAmount,
            0,
            0,
            address(this),
            block.timestamp + 1000
        );
        sushiswapV2WETHUSDTPair = IUniswapV2Factory(SUSHISWAP_V2_FACTORY).getPair(USDT_MAINNET, WETH_MAINNET);
        _;
    }

    // Modifiers - Sushiswap v3 pool deployment
    modifier WithDeployedSushiswapV3Pool() {
        IUniswapV3Factory sushiV3Factory = IUniswapV3Factory(SUSHISWAP_V3_FACTORY);
        INonfungiblePositionManager sushiV3PositionManager = INonfungiblePositionManager(SUSHISWAP_V3_POSITION_MANAGER);

        // Ensure we have ETH to wrap as WETH
        vm.deal(address(this), 100 ether);

        // Create and initialize the WETH/USDT pool at 0.05% fee via NPM
        uint24 fee = 500;
        uint160 sqrtPriceX96 = uint160(2**96);
        address pool = sushiV3PositionManager.createAndInitializePoolIfNecessary(
            WETH_MAINNET,
            USDT_MAINNET,
            fee,
            sqrtPriceX96
        );
        assert(pool != address(0));
        assert(address(pool).code.length > 0);
        // Assert factory mapping agrees with the created pool
        assertEq(sushiV3Factory.getPool(WETH_MAINNET, USDT_MAINNET, fee), pool);

        // Prepare tokens: wrap ETH to WETH and mint USDT to this contract
        uint256 amount0Desired = 1 ether;
        uint256 amount1Desired = 1 ether;
        WETH.deposit{value: amount0Desired}();
        USDT.mint(address(this), amount1Desired);

        // Approve position manager to pull tokens
        WETH.approve(address(sushiV3PositionManager), type(uint256).max);
        USDT.approve(address(sushiV3PositionManager), type(uint256).max);

        // Set a wide tick range based on factory tick spacing
        int24 spacing = sushiV3Factory.feeAmountTickSpacing(fee);
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

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = sushiV3PositionManager.mint(params);
        sushiswapV3WETHUSDTPair = pool;
        _;
    }

    // Modifiers - Camelot v2 pool deployment
    modifier WithDeployedCamelotV2Pool() {
        vm.deal(address(this), 10 ether);
        // Ensure we have non-zero USDT explicitly for the first mint
        uint256 usdtAmount = 10_000 * 10 ** 6; // 10k USDT with 6 decimals
        USDT.mint(address(this), usdtAmount);
        USDT.approve(CAMELOT_V2_ROUTER, type(uint256).max);
        ICamelotRouter(CAMELOT_V2_ROUTER).addLiquidityETH{value: 10 ether}(
            address(USDT),
            usdtAmount,
            0,
            0,
            address(this),
            block.timestamp + 1000
        );
        camelotV2WETHUSDTPair = ICamelotFactory(CAMELOT_V2_FACTORY).getPair(USDT_MAINNET, WETH_MAINNET);
        _;
    }

    // Modifiers - Camelot v3 pool deployment
    modifier WithDeployedCamelotV3Pool() {
        IAlgebraFactoryCamelotV3 camelotV3Factory = IAlgebraFactoryCamelotV3(CAMELOT_V3_FACTORY);
        INonfungiblePositionManagerCamelotV3 camelotV3PositionManager = INonfungiblePositionManagerCamelotV3(CAMELOT_V3_POSITION_MANAGER);

        // Ensure we have ETH to wrap as WETH
        vm.deal(address(this), 100 ether);

        // Create and initialize the WETH/USDT pool at 0.05% fee via NPM
        uint24 fee = 500;
        uint160 sqrtPriceX96 = uint160(2**96);
        address pool = camelotV3PositionManager.createAndInitializePoolIfNecessary(
            WETH_MAINNET,
            USDT_MAINNET,
            sqrtPriceX96
        );
        assert(pool != address(0));
        assert(address(pool).code.length > 0);
        // Assert factory mapping agrees with the created pool
        assertEq(camelotV3Factory.poolByPair(WETH_MAINNET, USDT_MAINNET), pool);

        // Prepare tokens: wrap ETH to WETH and mint USDT to this contract
        uint256 amount0Desired = 1 ether;
        uint256 amount1Desired = 1 ether;
        WETH.deposit{value: amount0Desired}();
        USDT.mint(address(this), amount1Desired);

        // Approve position manager to pull tokens
        WETH.approve(address(camelotV3PositionManager), type(uint256).max);
        USDT.approve(address(camelotV3PositionManager), type(uint256).max);

        // Set a wide tick range based on pool tick spacing (Algebra)
        int24 spacing = IAlgebraPoolCamelotV3(pool).tickSpacing();
        int24 tickLower = -spacing * 100;
        int24 tickUpper = spacing * 100;

        // Mint the position
        INonfungiblePositionManagerCamelotV3.MintParams memory params = INonfungiblePositionManagerCamelotV3.MintParams({
            token0: WETH_MAINNET,
            token1: USDT_MAINNET,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1000
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = camelotV3PositionManager.mint(params);
        camelotV3WETHUSDTPair = pool;
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

        // Deploy exchanges on anvil
        UniswapV2Deployer uniswapV2Deployer = new UniswapV2Deployer();
        uniswapV2Deployer.run();        
        UniswapV3Deployer uniswapV3Deployer = new UniswapV3Deployer();
        uniswapV3Deployer.run();
        SushiswapV2Deployer sushiswapV2Deployer = new SushiswapV2Deployer();
        sushiswapV2Deployer.run();
        SushiswapV3Deployer sushiswapV3Deployer = new SushiswapV3Deployer();
        sushiswapV3Deployer.run();
        CamelotV2Deployer camelotV2Deployer = new CamelotV2Deployer();
        camelotV2Deployer.run();

        // Deploy Arbitrager by impersonating TESTER_ADDRESS
        vm.startPrank(TESTER_ADDRESS);
        atomicArbitrager = new AtomicArbitrage(
            address(address(WETH)), // WETH9 address
            address(address(UNISWAP_V2_ROUTER02)),    // UniswapV2Router02    address
            address(address(UNISWAP_V3_ROUTER)),      // UniswapV3Router02    address
            address(address(SUSHISWAP_V2_ROUTER02)),  // SushiswapV2Router02  address
            address(address(SUSHISWAP_V3_ROUTER)),    // SushiswapV3Router    address
            address(address(CAMELOT_V2_ROUTER)),       // CamelotV2Router      address
            address(address(CAMELOT_V3_ROUTER))        // CamelotV3Router      address
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

    function test_MakeASingleSwapOnSushiswapV2() WithDeployedSushiswapV2Pool public {
        console.log("Sushiswap v2 WETH/USDT pool address:", sushiswapV2WETHUSDTPair);
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

        atomicArbitrager._swapSushiswapV2(swapParams);
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();
    }

    function test_MakeASingleSwapOnSushiswapV3() WithDeployedSushiswapV3Pool public {
        console.log("Sushiswap v3 WETH/USDT pool address:", sushiswapV3WETHUSDTPair);
        
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

        atomicArbitrager._swapSushiswapV3(swapParams);
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        console.log("USDT balance after swap:", USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();
    }

    function test_MakeASingleSwapOnCamelotV2() WithDeployedCamelotV2Pool public {
        console.log("Camelot v2 WETH/USDT pool address:", camelotV2WETHUSDTPair);
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

        atomicArbitrager._swapCamelotV2(swapParams);
        assert(0 < USDT.balanceOf(address(atomicArbitrager)));
        vm.stopPrank();
    }

    function test_makeSwap() public 
        WithDeployedUniswapV2Pool 
        WithDeployedUniswapV3Pool 
        WithDeployedSushiswapV2Pool
        WithDeployedSushiswapV3Pool
        WithDeployedCamelotV2Pool
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

        // Sushiswap v2
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        atomicArbitrager._makeSwap(
            2,
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

        // Sushiswap v3        
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        atomicArbitrager._makeSwap(
            3,
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

        // Camelot v2
        vm.startPrank(TESTER_ADDRESS);
        vm.deal(TESTER_ADDRESS, 10 ether);
        atomicArbitrager._wrapETH{value: 1 ether}(1 ether);
        atomicArbitrager._makeSwap(
            4,
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

    }
}