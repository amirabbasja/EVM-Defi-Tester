// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MMockERC20} from "./Mocks/MMockERC20.sol";
import {Token} from "../src/Token.sol";

// Interfaces
import {IAlgebraFactoryCamelotV3} from "./interfaces/IAlgebraFactoryCamelotV3.sol";
import {IAlgebraPoolCamelotV3} from "./interfaces/IAlgebraPoolCamelotV3.sol";
import {INonfungiblePositionManagerCamelotV3} from "./interfaces/INonfungiblePositionManagerCamelotV3.sol";
import {ISwapRouterCamelotV3} from "./interfaces/ISwapRouterCamelotV3.sol";
import {IMockWETH9} from "./interfaces/IMockWETH9.sol";
import {IMMockERC20} from "./interfaces/IMMockERC20.sol";

// Deployers
import {CamelotV3Deployer} from "../script/CamelotV3Deployer.s.sol";

contract CamelotV3Tester is Test {
    address constant CAMELOT_V3_FACTORY = 0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B;
    address constant CAMELOT_V3_POSITION_MANAGER = 0x00c7f3082833e796A5b3e4Bd59f6642FF44DCD15;
    address constant CAMELOT_V3_ROUTER = 0x1F721E2E82F6676FCE4eA07A5958cF098D339e18;

    IAlgebraFactoryCamelotV3 camelotV3Factory = IAlgebraFactoryCamelotV3(CAMELOT_V3_FACTORY);
    INonfungiblePositionManagerCamelotV3 camelotV3PositionManager = INonfungiblePositionManagerCamelotV3(CAMELOT_V3_POSITION_MANAGER);
    ISwapRouterCamelotV3 camelotV3SwapRouter = ISwapRouterCamelotV3(CAMELOT_V3_ROUTER);
    
    // Addresses
    address constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IMockWETH9 public WETH; // WETH - mainnet address: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    IMMockERC20 public USDT; // USDT - mainnet address: 0xdAC17F958D2ee523a2206206994597C13D831ec7

    // Struct for created pool's data
    struct PoolData {
        address pool;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 tokenId;
        uint256 deadline;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    PoolData internal _PoolData;


    modifier withWethUsdtPoolDefault() {
        // Ensure we have ETH to wrap as WETH
        vm.deal(address(this), 100 ether);

        // Create and initialize the WETH/USDT pool (Algebra has dynamic fee, no fee tier arg)
        uint160 sqrtPriceX96 = uint160(2**96);
        address pool = camelotV3PositionManager.createAndInitializePoolIfNecessary(
            WETH_MAINNET,
            USDT_MAINNET,
            sqrtPriceX96
        );
        console.log("Pool address: ", pool);
        console.log(camelotV3Factory.poolByPair(WETH_MAINNET, USDT_MAINNET));
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

        // Mint the position (no fee in MintParams for Algebra/Camelot v3)
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
        _PoolData = PoolData({
            pool: pool,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            deadline: params.deadline,
            tokenId: tokenId,
            liquidity: liquidity,
            amount0: amount0,
            amount1: amount1
        });

        _;
    }

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
        CamelotV3Deployer deployerCamelotV3 = new CamelotV3Deployer();
        deployerCamelotV3.run();
    }

    function test_camelotV3FactoryDeployment() public view {
        // Check to see if there is code at the address
        assert(address(CAMELOT_V3_FACTORY).code.length > 0);

        // Algebra/Camelot v3 factory has no fee tiers API; confirm no pool exists yet
        assertEq(camelotV3Factory.poolByPair(WETH_MAINNET, USDT_MAINNET), address(0));
    }

    function test_NonfungiblePositionManagerDeployment() public view {
        // Check to see if there is code at the address
        assert(address(CAMELOT_V3_POSITION_MANAGER).code.length > 0);
    }

    function test_AddLiquidityToUniswapV3Pool() public withWethUsdtPoolDefault {

        // Assertions: position minted and pool has liquidity
        console.log("Minted tokenId: ", _PoolData.tokenId);
        console.log("Liquidity: ", _PoolData.liquidity);
        console.log("Amount0: ", _PoolData.amount0);
        console.log("Amount1: ", _PoolData.amount1);
        assert(_PoolData.tokenId != 0);
        assert(_PoolData.liquidity > 0);
        assert(_PoolData.amount0 > 0 && _PoolData.amount1 > 0);
        assert(IAlgebraPoolCamelotV3(_PoolData.pool).liquidity() > 0);
    }

    function test_SwapTokensForTokens() public withWethUsdtPoolDefault {
        address testAddr = makeAddr("testAddr");
        address[] memory _path = new address[](2);
        _path[0] = WETH_MAINNET;
        _path[1] = USDT_MAINNET;
    
        // Fund the swapper with WETH and approve the router
        vm.startPrank(testAddr);
        vm.deal(testAddr, 1 ether);
        WETH.deposit{value: 0.1 ether}();
        WETH.approve(address(camelotV3SwapRouter), type(uint256).max);
        console.log("Swapping 0.1 WETH for USDT...");
        console.log("WETH balance before swap: ", WETH.balanceOf(address(testAddr)));
    
        ISwapRouterCamelotV3.ExactInputSingleParams memory params = ISwapRouterCamelotV3.ExactInputSingleParams({
            tokenIn: WETH_MAINNET,
            tokenOut: USDT_MAINNET,
            recipient: testAddr,
            amountIn: 0.1 ether,
            deadline: block.timestamp + 1000,
            amountOutMinimum: 0,
            limitSqrtPrice: 0
        });
        camelotV3SwapRouter.exactInputSingle(params);
        vm.stopPrank();
        
        console.log("WETH balance after swap: ", WETH.balanceOf(address(testAddr)));
        console.log("USDT balance after swap: ", USDT.balanceOf(address(testAddr)));
    }
}