// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract UniswapV2Deployer is Script, StdCheats{
    function run() public {

        // Deploy the uniswap v2 factory
        deployCodeTo(
            "UniswapV2Factory.sol",
            abi.encode(address(52555555555555555555)),
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f // ETH mainnet
        );

        // Deploy the uniswap v2 router02
        deployCodeTo(
            "UniswapV2Router02.sol",
            abi.encode(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // Univ2Factory:ETH, WETH:ETH
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // WETH mainnet
        );
    }
}