//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MockERC20} from "./Mocks/MockERC20.sol";
import {Token} from "../src/Token.sol";

// Interfaces
import {IUniswapV2Factory}  from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Router01} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {IMockWETH9} from "./Mocks/IMockWETH9.sol";
import {IMockERC20} from "./Mocks/IMockERC20.sol";

// Deployers
import {UniswapV2Deployer} from "../script/UniswapV2Deployer.s.sol";


contract UniswapDeployerTest is Test {
    IUniswapV2Factory uiV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 uniV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    // Addresses
    address constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IMockWETH9 public WETH; // WETH - mainnet address: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    IMockERC20 public USDT; // USDT - mainnet address: 0xdAC17F958D2ee523a2206206994597C13D831ec7

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
        USDT = IMockERC20(USDT_MAINNET);

        // Deploy Uniswap v2 - Factory and Router
        UniswapV2Deployer deployerUniV2 = new UniswapV2Deployer();
        deployerUniV2.run();
        
    }

    function test_uniswapFactory() public view {
        assert(uiV2Factory.feeToSetter() != address(0));
    }

    function test_WETHDeployementIsCorrect() public view {
        assert(0 < bytes(WETH.name()).length);
        assertEq(address(WETH), WETH_MAINNET);
    }

    function test_DeployedUniV2RouterCorrectly() public view {
        assertEq(uniV2Router02.WETH(), WETH_MAINNET);
    }

    function test_AddLiquidityToUniV2Pool() public {
        Token newToken = new Token();

        newToken.approve(address(uniV2Router02), type(uint256).max);

        IUniswapV2Router01(address(uniV2Router02)).addLiquidityETH{value: 10 ether}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1000
        );

    }

}