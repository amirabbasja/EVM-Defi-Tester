// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {NonfungiblePositionManager} from "../../lib/pancakeswap-v3/projects/v3-periphery/contracts/NonfungiblePositionManager.sol";

contract PancakeswapV3NonfungiblePositionManager is NonfungiblePositionManager {
    constructor(address _deployer, address _factory,address _WETH9,address _tokenDescriptor_) NonfungiblePositionManager(_deployer, _factory, _WETH9, _tokenDescriptor_) {}
}