// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {AlgebraPoolDeployer} from "../../lib/camelot-v3/src/core/contracts/AlgebraPoolDeployer.sol";

contract CamelotV3AlgebraPoolDeployer is AlgebraPoolDeployer {
    constructor() AlgebraPoolDeployer() {}
}
