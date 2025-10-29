// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.6;

import {PancakeRouter} from "../../lib/pancakeswap-v2-periphery/contracts/PancakeRouter.sol";

contract PancakeswapV2PancakeRouter is PancakeRouter {
    constructor(address _factory, address _WETH) PancakeRouter(_factory, _WETH) public {}
}