// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {SwapRouter} from "../../lib/camelot-v3/src/periphery/contracts/SwapRouter.sol";

contract CamelotV3SwapRouter is SwapRouter {
    constructor(address _factory,address _WNativeToken,address _poolDeployer) SwapRouter(_factory, _WNativeToken, _poolDeployer) {}
}
