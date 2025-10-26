// SPDX-License_Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import {NonfungibleTokenPositionDescriptor} from "../../lib/sushiswap-v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol";

contract SushiswapV3NonfungibleTokenPositionDescriptor is NonfungibleTokenPositionDescriptor {
    constructor(address _WETH9, bytes32 _nativeCurrencyLabelBytes) NonfungibleTokenPositionDescriptor(_WETH9, _nativeCurrencyLabelBytes) {}
}