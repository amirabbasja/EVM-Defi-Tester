// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract SushiswapV3Deployer is Script, StdCheats{
    function run() public {
        // Deploy the Sushiswap v3 Factory
        deployCodeTo(
            "SushiswapV3Factory.sol",
            0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F // ETH mainnet
        );

        // Deploy the sushiswap v3 NonfungibleTokenPositionDescriptor
        deployCodeTo(
            "SushiswapV3NonfungibleTokenPositionDescriptor.sol",
            abi.encode(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, bytes32("ETH")),
            0x1C4369df5732ccF317fef479B26A56e176B18ABb // ETH mainnet
        );

        // Deploy the sushiswap v3 NonfungiblePositionManager WITH constructor args
        deployCodeTo(
            "SushiswapV3NonfungiblePositionManager.sol",
            abi.encode(
                0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F, // v3 factory
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH9
                0x1C4369df5732ccF317fef479B26A56e176B18ABb  // position descriptor
            ),
            0x2214A42d8e2A1d20635c2cb0664422c528B6A432  // position manager address
        );

        // DeploySwapRouter
        deployCodeTo(
            "SushiswapV3SwapRouter.sol",
            abi.encode(
                0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F, 
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            ), // Sushiv3Factory:ETH, WETH:ETH
            0x2E6cd2d30aa43f40aa81619ff4b6E0a41479B13F // ETH mainnet
        );

    }
}