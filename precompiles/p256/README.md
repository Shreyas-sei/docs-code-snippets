# P256 Precompile (EIP-7212)

Solidity library and example contracts for verifying P-256 (secp256r1)
signatures on Sei using the EIP-7212 precompile. The primary use case is
WebAuthn / Passkey authentication.

**Precompile address:** `0x0000000000000000000000000000000000000100`

**EIP:** [EIP-7212](https://eips.ethereum.org/EIPS/eip-7212)

## Files

| File | Description |
|------|-------------|
| `P256Verify.sol` | Low-level interface to the EIP-7212 precompile |
| `ECDSA.sol` | Shared `Signature` and `PublicKey` struct types |
| `P256.sol` | High-level library wrapper (`P256.verify`) |
| `P256Example.sol` | Example contract with registry and WebAuthn helpers |

## How it Works

The precompile accepts 160 bytes of ABI-encoded input:

```
abi.encode(bytes32 hash, bytes32 r, bytes32 s, bytes32 x, bytes32 y)
```

It returns 32 bytes where `output[31] == 0x01` indicates a valid signature.

## Usage Examples

### Direct Verification (Solidity)

```solidity
import "./P256.sol";
import "./ECDSA.sol";

contract MyContract {
    using P256 for bytes32;

    function verify(
        bytes32 digest,
        bytes32 r, bytes32 s,
        bytes32 x, bytes32 y
    ) external view returns (bool) {
        ECDSA.Signature memory sig = ECDSA.Signature({ r: r, s: s });
        ECDSA.PublicKey memory pubKey = ECDSA.PublicKey({ x: x, y: y });
        return digest.verify(sig, pubKey);
    }
}
```

### WebAuthn / Passkey Flow

1. User signs a challenge with their device's P-256 credential.
2. Off-chain: compute `digest = SHA256(authenticatorData || SHA256(clientDataJSON))`.
3. Pass `digest`, `r`, `s`, `x`, `y` to `verifyPasskey()` on-chain.

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [P256 Precompile Docs](https://docs.sei.io/evm/precompiles/p256-precompile)
- [EIP-7212](https://eips.ethereum.org/EIPS/eip-7212)
