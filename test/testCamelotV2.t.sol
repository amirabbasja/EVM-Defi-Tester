//SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;
import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MMockERC20} from "./Mocks/MMockERC20.sol";
import {Token} from "../src/Token.sol";

// Interfaces
import {ICamelotFactory}  from "../lib/camelot-v2-core/contracts/interfaces/ICamelotFactory.sol";
import {ICamelotRouter} from "../lib/camelot-v2-periphery/contracts/interfaces/ICamelotRouter.sol";
import {ICamelotPair} from "../lib/camelot-v2-core/contracts/interfaces/ICamelotPair.sol";
import {IMockWETH9} from "./interfaces/IMockWETH9.sol";
import {IMMockERC20} from "./interfaces/IMMockERC20.sol";

// Deployers
import {CamelotV2Deployer} from "../script/CamelotV2Deployer.s.sol";


contract CamelotV2Tester is Test {
    ICamelotFactory camelotFactory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
    ICamelotRouter camelotV2Router = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    
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

        // Deploy Camelot v2 - Factory and Router
        CamelotV2Deployer deployerCamelotiV2 = new CamelotV2Deployer();
        deployerCamelotiV2.run();
        
    }

    function test_camelotFactory() public view {
        assert(camelotFactory.feeTo() != address(0));
    }

    function test_WETHDeployementIsCorrect() public view {
        assert(0 < bytes(WETH.name()).length);
        assertEq(address(WETH), WETH_MAINNET);
    }

    function test_DeployedCamelotV2RouterCorrectly() public view {
        assertEq(camelotV2Router.WETH(), WETH_MAINNET);
    }

    function test_AddLiquidityToCamelotV2Pool() public {
        Token newToken = new Token();

        newToken.approve(address(camelotV2Router), type(uint256).max);

        ICamelotRouter(address(camelotV2Router)).addLiquidityETH{value: 10 ether}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1000
        );

        // Get pair address 
        address pairAddress = camelotFactory.getPair(address(newToken), WETH_MAINNET);
        assert(pairAddress != address(0));

        ICamelotPair pair = ICamelotPair(pairAddress);
        (uint112 reserve0, uint112 reserve1,,) = pair.getReserves();
    }

    function test_SwapETHForTokens() public {
        Token newToken = new Token();

        newToken.approve(address(camelotV2Router), type(uint256).max);

        ICamelotRouter(address(camelotV2Router)).addLiquidityETH{value: 10 ether}(
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
        ICamelotRouter(address(camelotV2Router)).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 1 ether}(
            0,
            path,
            address(swapper),
            address(swapper),
            block.timestamp + 1000
        );
        vm.stopPrank();

        uint256 walletBlanaceAfter = newToken.balanceOf(swapper);

        assert(walletBlanaceBefore < walletBlanaceAfter);
    }

}