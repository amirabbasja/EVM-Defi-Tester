// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {NonfungiblePositionManager} from "../../lib/camelot-v3/src/periphery/contracts/NonfungiblePositionManager.sol"; 

contract CamelotV3NonfungiblePositionManager is NonfungiblePositionManager {
    constructor(address _factory, address _WNativeToken, address _tokenDescriptor_, address _poolDeployer) NonfungiblePositionManager(_factory, _WNativeToken, _tokenDescriptor_, _poolDeployer) {}
}
