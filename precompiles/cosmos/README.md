# Cosmos Precompiles

Solidity contracts for the Sei cosmos-layer precompiles that bridge the EVM
and Cosmos environments: address conversion, bank operations, CosmWasm
interaction, IBC transfers, and pointer registry management.

## Files

| File | Description | Precompile Address |
|------|-------------|-------------------|
| `AddrPrecompile.sol` | EVM ↔ bech32 address conversion | `0x...1004` |
| `BankPrecompile.sol` | Native Cosmos token send and balance queries | `0x...1002` |
| `CosmWasmPrecompile.sol` | Execute and query CosmWasm contracts | `0x...9001` |
| `IBCPrecompile.sol` | IBC token transfers to Cosmos chains | `0x...1009` |
| `PointerPrecompile.sol` | Create and resolve ERC-20/ERC-721 ↔ CW-20/CW-721 pointers | `0x...100A` / `0x...100B` |

## Precompile Addresses

| Precompile | Address |
|------------|---------|
| Addr | `0x0000000000000000000000000000000000001004` |
| Bank | `0x0000000000000000000000000000000000001002` |
| CosmWasm | `0x0000000000000000000000000000000000009001` |
| IBC Transfer | `0x0000000000000000000000000000000000001009` |
| Pointer (write) | `0x000000000000000000000000000000000000100A` |
| Pointer View (read) | `0x000000000000000000000000000000000000100B` |

## Usage Examples

### Address Conversion (Solidity)

```solidity
IAddr constant ADDR = IAddr(0x0000000000000000000000000000000000001004);

// EVM address → Sei bech32
string memory seiAddr = ADDR.getSeiAddr(0xYourAddress);

// Sei bech32 → EVM address
address evmAddr = ADDR.getEvmAddr("sei1...");
```

### Bank: Send Tokens (Solidity)

```solidity
IBank constant BANK = IBank(0x0000000000000000000000000000000000001002);

bool success = BANK.send("sei1recipient...", "usei", 1_000_000);
require(success, "Send failed");
```

### CosmWasm: Query a Contract (Solidity)

```solidity
ICosmWasm constant CW = ICosmWasm(0x0000000000000000000000000000000000009001);

bytes memory response = CW.query(
    "sei1contract...",
    bytes('{"balance":{"address":"sei1..."}}')
);
```

### IBC Transfer (Solidity)

```solidity
IIBC constant IBC = IIBC(0x0000000000000000000000000000000000001009);

bool success = IBC.transfer(
    "cosmos1recipient...",
    "transfer",
    "channel-0",
    "usei",
    1_000_000,
    1,          // revisionNumber
    10000000,   // revisionHeight (timeout block on destination)
    0,          // timeoutTimestamp (0 = use height)
    ""          // memo
);
```

### Pointer: Create ERC-20 for CW-20 Token (Solidity)

```solidity
IPointer constant POINTER = IPointer(0x000000000000000000000000000000000000100A);

address erc20Pointer = POINTER.addNativePointerForCw20("sei1cw20contract...");
```

## Deployment

```bash
npx hardhat run scripts/deploy.js --network sei-mainnet
```

## References

- [Addr Precompile Docs](https://docs.sei.io/evm/precompiles/addr)
- [Bank Precompile Docs](https://docs.sei.io/evm/precompiles/bank)
- [CosmWasm Precompile Docs](https://docs.sei.io/evm/precompiles/cosmwasm)
- [IBC Precompile Docs](https://docs.sei.io/evm/precompiles/ibc)
- [Pointer Precompile Docs](https://docs.sei.io/evm/precompiles/pointer)
- [Pointerview Precompile Docs](https://docs.sei.io/evm/precompiles/pointerview)
