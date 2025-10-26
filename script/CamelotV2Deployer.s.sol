// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Script} from "../lib/forge-std/src/Script.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract CamelotV2Deployer is Script, StdCheats{
    function run() public {

        // Deploy the uniswap v2 factory
        deployCodeTo(
            "CamelotFactory.sol",
            abi.encode(address(2233333)),
            0x6EcCab422D763aC031210895C81787E87B43A652 // ETH mainnet
        );

        // Deploy the uniswap v2 router02
        deployCodeTo(
            "CamelotRouter.sol",
            abi.encode(0x6EcCab422D763aC031210895C81787E87B43A652, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // Sushiv2Factory:ETH, WETH:ETH
            0xc873fEcbd354f5A56E00E710B90EF4201db2448d // WETH mainnet
        );
    }
}