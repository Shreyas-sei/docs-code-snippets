// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./P256.sol";
import "./ECDSA.sol";

/// @title P256Example
/// @notice Demonstrates P-256 (secp256r1) signature verification on Sei using
///         the EIP-7212 precompile at 0x0000000000000000000000000000000000000100.
///
/// Use cases:
/// - Passkey / WebAuthn authentication (browser-native P-256 signing)
/// - Hardware security key attestation
/// - Cross-chain signature verification for ecosystems using P-256
contract P256Example {
    using P256 for bytes32;

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Maps a public key hash to a registered owner address.
    mapping(bytes32 => address) public keyOwners;

    /// @notice Tracks used nonces to prevent signature replay.
    mapping(bytes32 => mapping(uint256 => bool)) public usedNonces;

    // ─── Events ───────────────────────────────────────────────────────────────

    event SignatureVerified(bytes32 indexed keyHash, bytes32 digest);
    event KeyRegistered(bytes32 indexed keyHash, address indexed owner);
    event AuthenticatedAction(bytes32 indexed keyHash, uint256 nonce);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error InvalidSignature();
    error NonceAlreadyUsed();
    error KeyNotRegistered();

    // ─── Core Verification ────────────────────────────────────────────────────

    /// @notice Verify a P-256 signature directly.
    /// @param digest    32-byte message hash that was signed.
    /// @param r         Signature r component.
    /// @param s         Signature s component.
    /// @param x         Public key x coordinate.
    /// @param y         Public key y coordinate.
    /// @return valid    True if the signature is valid for the given key.
    function verifySignature(
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y
    ) public view returns (bool valid) {
        ECDSA.Signature memory sig = ECDSA.Signature({ r: r, s: s });
        ECDSA.PublicKey memory pubKey = ECDSA.PublicKey({ x: x, y: y });
        return digest.verify(sig, pubKey);
    }

    /// @notice Verify and emit an event on success.
    /// @dev Reverts with InvalidSignature if the signature is invalid.
    function verifyAndEmit(
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y
    ) external {
        bool valid = verifySignature(digest, r, s, x, y);
        if (!valid) revert InvalidSignature();

        bytes32 keyHash = keccak256(abi.encode(x, y));
        emit SignatureVerified(keyHash, digest);
    }

    // ─── Key Registry ─────────────────────────────────────────────────────────

    /// @notice Register a P-256 public key and associate it with msg.sender.
    /// @param x Public key x coordinate.
    /// @param y Public key y coordinate.
    function registerKey(bytes32 x, bytes32 y) external {
        bytes32 keyHash = keccak256(abi.encode(x, y));
        keyOwners[keyHash] = msg.sender;
        emit KeyRegistered(keyHash, msg.sender);
    }

    // ─── Authenticated Actions ────────────────────────────────────────────────

    /// @notice Execute an authenticated action using a P-256 signature.
    ///         The signed digest must be keccak256(abi.encode(nonce, address(this))).
    ///         This ties the signature to the specific contract and nonce,
    ///         preventing replay attacks.
    ///
    /// @param x     Public key x coordinate.
    /// @param y     Public key y coordinate.
    /// @param r     Signature r component.
    /// @param s     Signature s component.
    /// @param nonce One-time-use nonce (caller must track off-chain).
    function authenticatedAction(
        bytes32 x,
        bytes32 y,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external {
        bytes32 keyHash = keccak256(abi.encode(x, y));

        if (keyOwners[keyHash] == address(0)) revert KeyNotRegistered();
        if (usedNonces[keyHash][nonce]) revert NonceAlreadyUsed();

        // Reconstruct the expected digest
        bytes32 digest = keccak256(abi.encode(nonce, address(this)));

        ECDSA.Signature memory sig = ECDSA.Signature({ r: r, s: s });
        ECDSA.PublicKey memory pubKey = ECDSA.PublicKey({ x: x, y: y });

        if (!digest.verify(sig, pubKey)) revert InvalidSignature();

        usedNonces[keyHash][nonce] = true;
        emit AuthenticatedAction(keyHash, nonce);
    }

    // ─── WebAuthn Helper ──────────────────────────────────────────────────────

    /// @notice Verify a WebAuthn / Passkey signature.
    ///         WebAuthn signs SHA-256(authenticatorData || SHA-256(clientDataJSON)).
    ///         Pass the pre-computed digest as `digest`.
    ///
    /// @param digest Pre-computed 32-byte hash as described above.
    /// @param r      Signature r component.
    /// @param s      Signature s component.
    /// @param x      Credential public key x coordinate.
    /// @param y      Credential public key y coordinate.
    /// @return valid True if the passkey signature is valid.
    function verifyPasskey(
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y
    ) external view returns (bool valid) {
        return verifySignature(digest, r, s, x, y);
    }
}
