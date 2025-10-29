//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MMockERC20} from "./Mocks/MMockERC20.sol";
import {Token} from "../src/Token.sol";

// Interfaces
import {IPancakeFactoryPancakeswapV2}  from "./interfaces/IPancakeFactoryPancakeswapV2.sol";
import {IPancakeRouter01PancakeswapV2} from "./interfaces/IPancakeRouter01PancakeswapV2.sol";
import {IPancakePairPancakeswapV2} from "./interfaces/IPancakePairPancakeswapV2.sol";
import {IMockWETH9} from "./interfaces/IMockWETH9.sol";
import {IMMockERC20} from "./interfaces/IMMockERC20.sol";

// Deployers
import {PancakeswapV2Deployer} from "../script/PancakeswapV2Deployer.s.sol";


contract PancakeswapV2Tester is Test {
    IPancakeFactoryPancakeswapV2 pancakeV2Factory = IPancakeFactoryPancakeswapV2(0x1097053Fd2ea711dad45caCcc45EfF7548fCB362);
    IPancakeRouter01PancakeswapV2 pancakeV2Router01 = IPancakeRouter01PancakeswapV2(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
    
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

        // Deploy Uniswap v2 - Factory and Router
        PancakeswapV2Deployer deployerPancakeV2 = new PancakeswapV2Deployer();
        deployerPancakeV2.run();
        
    }

    function test_uniswapFactory() public view {
        assert(pancakeV2Factory.feeToSetter() != address(0));
    }

    function test_WETHDeployementIsCorrect() public view {
        assert(0 < bytes(WETH.name()).length);
        assertEq(address(WETH), WETH_MAINNET);
    }

    function test_DeployedUniV2RouterCorrectly() public view {
        assertEq(pancakeV2Router01.WETH(), WETH_MAINNET);
    }

    function test_AddLiquidityToUniV2Pool() public {
        Token newToken = new Token();

        newToken.approve(address(pancakeV2Router01), type(uint256).max);

        IPancakeRouter01PancakeswapV2(address(pancakeV2Router01)).addLiquidityETH{value: 10 ether}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1000
        );

        // Get pair address 
        address pairAddress = pancakeV2Factory.getPair(address(newToken), WETH_MAINNET);
        assert(pairAddress != address(0));

        IPancakePairPancakeswapV2 pair = IPancakePairPancakeswapV2(pairAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
    }

    function test_SwapETHForTokens() public {
        Token newToken = new Token();

        newToken.approve(address(pancakeV2Router01), type(uint256).max);

        IPancakeRouter01PancakeswapV2(address(pancakeV2Router01)).addLiquidityETH{value: 10 ether}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1000
        );

        // Make a new address
        address swapper = makeAddr("swapper");
        vm.deal(swapper, 10 ether);
        uint256 walletBlanaceBefore = newToken.balanceOf(swapper);

        vm.startPrank(swapper);
        address[] memory path = new address[](2);
        path[0] = WETH_MAINNET;
        path[1] = address(newToken);
        IPancakeRouter01PancakeswapV2(address(pancakeV2Router01)).swapExactETHForTokens{value: 1 ether}(
            0,
            path,
            address(swapper),
            block.timestamp + 1000
        );
        vm.stopPrank();

        uint256 walletBlanaceAfter = newToken.balanceOf(swapper);

        assert(walletBlanaceBefore < walletBlanaceAfter);
    }

}