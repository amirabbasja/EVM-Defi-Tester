// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;

import {AlgebraFactory} from "../../lib/camelot-v3/src/core/contracts/AlgebraFactory.sol";

contract CamelotV3AlgebraFactory is AlgebraFactory {
    constructor(address _poolDeployer, address _vaultAddres) AlgebraFactory(_poolDeployer, _vaultAddres) {}
}