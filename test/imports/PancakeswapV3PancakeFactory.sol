// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;

import {PancakeV3Factory} from "../../lib/pancakeswap-v3/projects/v3-core/contracts/PancakeV3Factory.sol";

contract PancakeswapV3Factory is PancakeV3Factory {
    constructor(address _poolDeployer) PancakeV3Factory(_poolDeployer) {}
}