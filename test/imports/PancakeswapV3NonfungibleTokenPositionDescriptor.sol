// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {NonfungibleTokenPositionDescriptor} from "../../lib/pancakeswap-v3/projects/v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol";

contract PancakeswapV3NonfungibleTokenPositionDescriptor is NonfungibleTokenPositionDescriptor {
    constructor(address _WETH9, bytes32 _nativeCurrencyLabelBytes, address _nftDescriptorEx) NonfungibleTokenPositionDescriptor(_WETH9, _nativeCurrencyLabelBytes, _nftDescriptorEx) {}
}