// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract SushiswapV2Deployer is Script, StdCheats{
    function run() public {

        // Deploy the uniswap v2 factory
        deployCodeTo(
            "SushiswapV2Factory.sol",
            abi.encode(address(111111)),
            0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac // ETH mainnet
        );

        // Deploy the uniswap v2 router02
        deployCodeTo(
            "SushiswapV2Router02.sol",
            abi.encode(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // Sushiv2Factory:ETH, WETH:ETH
            0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F // WETH mainnet
        );
    }
}