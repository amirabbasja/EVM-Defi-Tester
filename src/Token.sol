// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

// Import ERC20 token
import {MockERC20} from "../test/Mocks/MockERC20.sol";

contract Token is MockERC20("MoonerTooken", "MTKN", 18) {
    // Mint supply
    constructor() {
        mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}