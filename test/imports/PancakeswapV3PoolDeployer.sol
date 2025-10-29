// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;

import {PancakeV3PoolDeployer} from "../../lib/pancakeswap-v3/projects/v3-core/contracts/PancakeV3PoolDeployer.sol";

contract PancakeswapV3PoolDeployer is PancakeV3PoolDeployer {
    constructor() PancakeV3PoolDeployer() {}
}