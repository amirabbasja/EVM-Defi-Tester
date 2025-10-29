// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract PancakeswapV3Deployer is Script, StdCheats{
    function run() public {
        address NFT_POSITION_DESCRIPTOR = makeAddr("NFT_POSITION_DESCRIPTOR");
        address NFT_DESCRIPTOR_EX = makeAddr("NFT_DESCRIPTOR_EX");

        // Deploy the uniswap v2 factory
        deployCodeTo(
            "PancakeswapV2PancakeFactory.sol",
            abi.encode(address(85858585858585)),
            0x1097053Fd2ea711dad45caCcc45EfF7548fCB362 // ETH mainnet
        );

        // Deploy the pancakeswap v3 pool deployer
        deployCodeTo(
            "PancakeswapV3PoolDeployer.sol",
            0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9 // ETH mainnet
        );

        // Deploy the pancakeswap v3 factory
        deployCodeTo(
            "PancakeswapV3Factory.sol",
            abi.encode(0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9), // pool deployer
            0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865 // ETH mainnet
        );

        // Wire PoolDeployer to Factory so onlyFactory passes
        (bool ok, ) = address(0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9).call(
            abi.encodeWithSignature("setFactoryAddress(address)", 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865)
        );
        require(ok, "pool deployer: setFactoryAddress failed");

        // Deploy the pancakeswap v3 NFT Token Position Descriptor
        deployCodeTo(
            "PancakeswapV3NonfungibleTokenPositionDescriptor.sol",
            abi.encode(
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                bytes32("ETH"),
                NFT_DESCRIPTOR_EX
            ),
            NFT_POSITION_DESCRIPTOR // ETH mainnet
        );

        // Deploy the pancakeswap v3 NFT DescriptorEx
        deployCodeTo(
            "PancakeswapV3NFTDescriptorEx.sol",
            NFT_DESCRIPTOR_EX // ETH mainnet
        );

        // Deploy the pancakeswap v3 NFT Position Descriptor
        deployCodeTo(
            "PancakeswapV3NonfungiblePositionManager.sol",
            abi.encode(
                0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9,
                0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                NFT_POSITION_DESCRIPTOR
            ),
            0x46A15B0b27311cedF172AB29E4f4766fbE7F4364 // ETH mainnet
        );

        // Deploy the pancakeswap v3 SwapRouter
        deployCodeTo(
            "PancakeswapV3SwapRouter.sol",
            abi.encode(
                0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9,
                0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            ),
            0x1b81D678ffb9C0263b24A97847620C99d213eB14 // ETH mainnet
        );
        
    }
}