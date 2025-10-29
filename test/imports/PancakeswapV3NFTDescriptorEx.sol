// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {NFTDescriptorEx} from "../../lib/pancakeswap-v3/projects/v3-periphery/contracts/NFTDescriptorEx.sol";

contract PancakeswapV3NFTDescriptorEx is NFTDescriptorEx {
    constructor() NFTDescriptorEx() {}
}