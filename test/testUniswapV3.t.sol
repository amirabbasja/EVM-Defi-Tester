// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MMockERC20} from "./Mocks/MMockERC20.sol";
import {Token} from "../src/Token.sol";
import {IMockWETH9} from "./Mocks/IMockWETH9.sol";
import {IMMockERC20} from "./Mocks/IMMockERC20.sol";

// Interfaces
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {ISwapRouter02} from "./interfaces/ISwapRouter02.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {INonfungibleTokenPositionDescriptor} from "./interfaces/INonfungibleTokenPositionDescriptor.sol";
import {IUniswapV3Pool} from "../lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// Deployers
import {UniswapV3Deployer} from "../script/UniswapV3Deployer.s.sol";

contract UniswapV3Tester is Test {
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_V3_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant UNISWAP_V3_POSITION_DESCRIPTOR = 0x91ae842A5Ffd8d12023116943e72A606179294f3;
    address constant UNISWAP_V3_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant UNISWAP_V3_NFTDESCRIPTOR = 0x42B24A95702b9986e82d421cC3568932790A48Ec;

    IUniswapV3Factory uniV3Factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
    INonfungiblePositionManager uniV3PositionManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);
    INonfungibleTokenPositionDescriptor uniV3PositionDescriptor = INonfungibleTokenPositionDescriptor(UNISWAP_V3_POSITION_DESCRIPTOR);
    ISwapRouter02 uniV3Router = ISwapRouter02(UNISWAP_V3_ROUTER);
    
    // Addresses
    address constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IMockWETH9 public WETH; // WETH - mainnet address: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    IMMockERC20 public USDT; // USDT - mainnet address: 0xdAC17F958D2ee523a2206206994597C13D831ec7

    function setUp() public {
        // Tokens -  Deploy to the mainnet addresses
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
        USDT = IMMockERC20(USDT_MAINNET);

        // Deploy Uniswap v3 stack
        UniswapV3Deployer deployerUniV3 = new UniswapV3Deployer();
        deployerUniV3.run();
    }

    function test_UniV3FactoryDeployment() public {
        // Check to see if there is code at the address
        assert(address(UNISWAP_V3_FACTORY).code.length > 0);

        // Check constructor deployment
        assertEq(uniV3Factory.feeAmountTickSpacing(500), 10);
    }

    function test_NonfungiblePositionManagerDeployment() public {
        // Check to see if there is code at the address
        assert(address(UNISWAP_V3_POSITION_MANAGER).code.length > 0);
    }

    function test_AddLiquidityToUniswapV3Pool() public {
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
        console.log("Pool address: ", pool);
        console.log(uniV3Factory.getPool(WETH_MAINNET, USDT_MAINNET, fee));
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

        // Assertions: position minted and pool has liquidity
        assert(tokenId != 0);
        assert(liquidity > 0);
        assert(amount0 > 0 && amount1 > 0);
        assert(IUniswapV3Pool(pool).liquidity() > 0);
    }
}