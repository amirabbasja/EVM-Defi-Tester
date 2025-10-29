// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.16;

import {PancakeFactory} from "../../lib/pancakeswap-v2-core/projects/exchange-protocol/contracts/PancakeFactory.sol";

contract PancakeswapV2PancakeFactory is PancakeFactory {
    constructor(address _feeToSetter) PancakeFactory(_feeToSetter) public {}
}