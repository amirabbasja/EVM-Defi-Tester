// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

// Import ERC20 token
import {MMockERC20} from "../test/Mocks/MMockERC20.sol";

contract Token is MMockERC20("MoonerTooken", "MTKN", 18) {
    // Mint supply
    constructor() {
        mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}