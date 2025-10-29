// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MMockERC20} from "./Mocks/MMockERC20.sol";
import {Token} from "../src/Token.sol";

// Interfaces
import {IPancakeV3Factory} from "./interfaces/IPancakeV3Factory.sol";
import {INonfungiblePositionManagerPancakeswapV3} from "./interfaces/INonfungiblePositionManagerPancakeswapV3.sol";
import {ISwapRouterPanckeswapV3} from "./interfaces/ISwapRouterPanckeswapV3.sol";
import {IMockWETH9} from "./interfaces/IMockWETH9.sol";
import {IMMockERC20} from "./interfaces/IMMockERC20.sol";

// Deployers
import {PancakeswapV3Deployer} from "../script/PancakeswapV3Deployer.s.sol";

contract PanckeswapV3Tester is Test {
    address constant PANCAKESWAP_V3_FACTORY = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
    address constant PANCAKESWAP_V3_POSITION_MANAGER = 0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
    address constant PANCAKESWAP_V3_ROUTER = 0x1b81D678ffb9C0263b24A97847620C99d213eB14;

    IPancakeV3Factory pancakeV3Factory = IPancakeV3Factory(PANCAKESWAP_V3_FACTORY);
    INonfungiblePositionManagerPancakeswapV3 pancakeswapV3PositionManager = INonfungiblePositionManagerPancakeswapV3(PANCAKESWAP_V3_POSITION_MANAGER);
    ISwapRouterPanckeswapV3 pancakeV3SwapRouter = ISwapRouterPanckeswapV3(PANCAKESWAP_V3_ROUTER);
    
    // Addresses
    address constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IMockWETH9 public WETH; // WETH - mainnet address: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    IMMockERC20 public USDT; // USDT - mainnet address: 0xdAC17F958D2ee523a2206206994597C13D831ec7

    // Struct for created pool's data
    struct PoolData {
        address pool;
        uint24 fee;
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

        // Create and initialize the WETH/USDT pool at 0.05% fee via NPM
        uint24 fee = 500;
        uint160 sqrtPriceX96 = uint160(2**96);
        address pool = pancakeswapV3PositionManager.createAndInitializePoolIfNecessary(
            WETH_MAINNET,
            USDT_MAINNET,
            fee,
            sqrtPriceX96
        );
        console.log("Pool address: ", pool);
        console.log(pancakeV3Factory.getPool(WETH_MAINNET, USDT_MAINNET, fee));
        assert(pool != address(0));
        assert(address(pool).code.length > 0);
        // Assert factory mapping agrees with the created pool
        assertEq(pancakeV3Factory.getPool(WETH_MAINNET, USDT_MAINNET, fee), pool);

        // Prepare tokens: wrap ETH to WETH and mint USDT to this contract
        uint256 amount0Desired = 1 ether;
        uint256 amount1Desired = 1 ether;
        WETH.deposit{value: amount0Desired}();
        USDT.mint(address(this), amount1Desired);

        // Approve position manager to pull tokens
        WETH.approve(address(pancakeswapV3PositionManager), type(uint256).max);
        USDT.approve(address(pancakeswapV3PositionManager), type(uint256).max);

        // Set a wide tick range based on factory tick spacing
        int24 spacing = pancakeV3Factory.feeAmountTickSpacing(fee);
        int24 tickLower = -spacing * 100;
        int24 tickUpper = spacing * 100;

        // Mint the position
        INonfungiblePositionManagerPancakeswapV3.MintParams memory params = INonfungiblePositionManagerPancakeswapV3.MintParams({
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

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = pancakeswapV3PositionManager.mint(params);
        _PoolData = PoolData({
            pool: pool,
            fee: fee,
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
        PancakeswapV3Deployer deployerPancakeV3 = new PancakeswapV3Deployer();
        deployerPancakeV3.run();
    }

    function test_pancakeV3FactoryDeployment() public view {
        // Check to see if there is code at the address
        assert(address(PANCAKESWAP_V3_FACTORY).code.length > 0);

        // Check constructor deployment
        assertEq(pancakeV3Factory.feeAmountTickSpacing(500), 10);
    }

    function test_NonfungiblePositionManagerDeployment() public view {
        // Check to see if there is code at the address
        assert(address(PANCAKESWAP_V3_POSITION_MANAGER).code.length > 0);
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
        WETH.approve(address(pancakeV3SwapRouter), type(uint256).max);
        console.log("Swapping 0.1 WETH for USDT...");
        console.log("WETH balance before swap: ", WETH.balanceOf(address(testAddr)));
    
        ISwapRouterPanckeswapV3.ExactInputSingleParams memory params = ISwapRouterPanckeswapV3.ExactInputSingleParams({
            tokenIn: WETH_MAINNET,
            tokenOut: USDT_MAINNET,
            fee: _PoolData.fee,          // uses the 500 fee pool you created
            recipient: testAddr,
            amountIn: 0.1 ether,
            deadline: block.timestamp + 1000,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        pancakeV3SwapRouter.exactInputSingle(params);
        vm.stopPrank();
        
        console.log("WETH balance after swap: ", WETH.balanceOf(address(testAddr)));
        console.log("USDT balance after swap: ", USDT.balanceOf(address(testAddr)));
    }
}