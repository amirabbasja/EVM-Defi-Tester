// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {SwapRouter} from "../../lib/pancakeswap-v3/projects/v3-periphery/contracts/SwapRouter.sol";

contract PancakeswapV3SwapRouter is SwapRouter {
    constructor(address _deployer, address _factory, address _WETH9) SwapRouter(_deployer, _factory, _WETH9) public {}
}