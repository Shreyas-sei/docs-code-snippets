// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title ECDSA
/// @notice Shared ECDSA types used by the P256 library.
library ECDSA {
    /// @notice A P-256 (secp256r1) signature.
    struct Signature {
        bytes32 r;
        bytes32 s;
    }

    /// @notice An uncompressed P-256 public key.
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }
}
