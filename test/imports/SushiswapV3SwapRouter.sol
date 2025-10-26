// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {SwapRouter} from "../../lib/sushiswap-v3-periphery/contracts/SwapRouter.sol";

contract SushiswapV3SwapRouter is SwapRouter {
    constructor(address _factory, address _WETH9) SwapRouter(_factory, _WETH9) {}
}