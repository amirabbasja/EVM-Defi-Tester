// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMockWETH9 is IERC20, IERC20Metadata {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}