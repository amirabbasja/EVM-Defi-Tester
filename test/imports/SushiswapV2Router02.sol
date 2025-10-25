// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

import {UniswapV2Router02} from "../../lib/sushiswap-v2-core/contracts/UniswapV2Router02.sol";

contract SushiswapV2Router02 is UniswapV2Router02 {
    constructor(address _factory, address _WETH) UniswapV2Router02(_factory, _WETH) public {}
}