// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

import {UniswapV2Factory} from "../../lib/sushiswap-v2-core/contracts/UniswapV2Factory.sol";

contract SushiswapV2Factory is UniswapV2Factory {
    constructor(address _feeToSetter) UniswapV2Factory(_feeToSetter) public {}
}