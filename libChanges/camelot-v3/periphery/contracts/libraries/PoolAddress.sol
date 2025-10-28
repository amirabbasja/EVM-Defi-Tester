// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '../../../core/contracts/AlgebraPool.sol';

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
library PoolAddress {
    // bytes32 internal constant POOL_INIT_CODE_HASH = 0xbce37a54eab2fcd71913a0d40723e04238970e7fc1159bfd58ad5b79531697e7;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Algebra factory (or pool deployer) contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        bytes32 initCodeHash = keccak256(type(AlgebraPool).creationCode);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1)),
                        initCodeHash
                    )
                )
            )
        );
    }
}
