// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";
import {IAlgebraPoolDeployer} from "../lib/camelot-v3/src/core/contracts/interfaces/IAlgebraPoolDeployer.sol";

contract CamelotV3Deployer is Script, StdCheats{
    function run() public {
        address VAULT_ADDRESS = makeAddr("camelotV3VaultAddress");
        address POOL_DEPLOYER_ADDRESS = makeAddr("camelotV3PoolDeployerAddress");
        // address POSITION_DESCRIPTOR_ADDRESS = makeAddr("camelotV3PositionDescriptorAddress");

        // Deploy the Sushiswap v3 Factory
        deployCodeTo(
            "CamelotV3AlgebraPoolDeployer.sol",
            POOL_DEPLOYER_ADDRESS // ETH mainnet
        );

        // Deploy the Sushiswap v3 Factory
        deployCodeTo(
            "CamelotV3AlgebraFactory.sol",
            abi.encode(
                POOL_DEPLOYER_ADDRESS, 
                VAULT_ADDRESS
            ), 
            0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B // ETH mainnet
        );

        // Wire poolDeployer to factory for onlyFactory gating
        IAlgebraPoolDeployer(POOL_DEPLOYER_ADDRESS).setFactory(0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B);

        // Deploy the Camelot v3 NonfungiblePositionManager (descriptor set to address(0) for tests)
        deployCodeTo(
            "CamelotV3NonfungibleTokenPositionDescriptor.sol",
            abi.encode(
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            ),
            0xA914d0665DD9D846c973cA7C2Cb735F5D98C7d91       // Descriptor address
        );

        // Deploy the Camelot v3 NonfungiblePositionManager (descriptor set to address(0) for tests)
        deployCodeTo(
            "CamelotV3NonfungiblePositionManager.sol",
            abi.encode(
                0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B, // Factory
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WNativeToken
                0xA914d0665DD9D846c973cA7C2Cb735F5D98C7d91, // Token descriptor
                POOL_DEPLOYER_ADDRESS                       // Pool deployer
            ),
            0x00c7f3082833e796A5b3e4Bd59f6642FF44DCD15       // Position Manager address
        );

        // DeploySwapRouter
        deployCodeTo(
            "CamelotV3SwapRouter.sol",
            abi.encode(
                0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B, // Factory
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WNativeToken
                POOL_DEPLOYER_ADDRESS // Pool deployer 
            ), 
            0x1F721E2E82F6676FCE4eA07A5958cF098D339e18 // ARB mainnet
        );
    }
}