// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {NonfungibleTokenPositionDescriptor} from "../../lib/camelot-v3/src/periphery/contracts/NonfungibleTokenPositionDescriptor.sol";

contract CamelotV3NonfungibleTokenPositionDescriptor is NonfungibleTokenPositionDescriptor {
    constructor(address _WNativeToken) NonfungibleTokenPositionDescriptor(_WNativeToken) {}
}
