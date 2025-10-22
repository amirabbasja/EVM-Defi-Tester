// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract UniswapV3Deployer is Script, StdCheats{
    function run() public {
        // Deploy the uniswap v2 factory
        deployCodeTo(
            "UniswapV2Factory.sol",
            abi.encode(address(52555555555555555555)),
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f // ETH mainnet
        );

        // Deploy the uniswap v3 Factory
        deployCodeTo(
            "UniswapV3Factory.sol",
            0x1F98431c8aD98523631AE4a59f267346ea31F984 // ETH mainnet
        );

        // Deploy NFTDescriptor library (required by NonfungibleTokenPositionDescriptor)
        deployCodeTo(
            "NFTDescriptor.sol",
            0x42B24A95702b9986e82d421cC3568932790A48Ec // ETH mainnet
        );

        // Deploy the uniswap v3 NonfungibleTokenPositionDescriptor
        deployCodeTo(
            "NonfungibleTokenPositionDescriptor.sol",
            abi.encode(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, bytes32("ETH")),
            0x91ae842A5Ffd8d12023116943e72A606179294f3 // ETH mainnet
        );

        // Deploy the uniswap v3 NonfungiblePositionManager WITH constructor args
        deployCodeTo(
            "NonfungiblePositionManager.sol",
            abi.encode(
                0x1F98431c8aD98523631AE4a59f267346ea31F984, // v3 factory
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH9
                0x91ae842A5Ffd8d12023116943e72A606179294f3  // position descriptor
            ),
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88  // position manager address
        );

        // Deploy the uniswap v3 SwapRouter02
        deployCodeTo(
            "SwapRouter02.sol",
            abi.encode(
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, // Univ2Factory
                0x1F98431c8aD98523631AE4a59f267346ea31F984, // Univ3Factory
                0xC36442b4a4522E871399CD717aBDD847Ab11FE88, // NPM
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2  // WETH
            ),
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 // ETH mainnet
        );
    }
}