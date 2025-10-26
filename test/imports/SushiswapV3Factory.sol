// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;

import {UniswapV3Factory} from "../../lib/sushiswap-v3-core/contracts/UniswapV3Factory.sol";

contract SushiswapV3Factory is UniswapV3Factory {
    constructor() UniswapV3Factory() {}
}