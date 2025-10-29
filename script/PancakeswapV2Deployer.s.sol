// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract PancakeswapV2Deployer is Script, StdCheats{
    function run() public {

        // Deploy the pancakeswap v2 factory
        deployCodeTo(
            "PancakeswapV2PancakeFactory.sol",
            abi.encode(address(85858585858585)),
            0x1097053Fd2ea711dad45caCcc45EfF7548fCB362 // ETH mainnet
        );

        // Deploy the pancakeswap v router02
        deployCodeTo(
            "PancakeswapV2PancakeRouter.sol",
            abi.encode(0x1097053Fd2ea711dad45caCcc45EfF7548fCB362, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // Factory:ETH, WETH:ETH
            0xEfF92A263d31888d860bD50809A8D171709b7b1c // WETH mainnet
        );
    }
}