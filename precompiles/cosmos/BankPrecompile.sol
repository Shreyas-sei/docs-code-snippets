// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BankPrecompile
/// @notice Demonstrates native Cosmos token operations using the Sei bank
///         precompile — sending tokens, querying balances, and reading supply.
///
/// @dev The bank precompile is at 0x0000000000000000000000000000000000001002.
///      It exposes Cosmos SDK bank module functionality to EVM contracts,
///      allowing interaction with IBC tokens and native Cosmos denoms.
interface IBank {
    /// @notice A coin with denom and amount.
    struct Coin {
        uint256 amount;
        string denom;
    }

    /// @notice Send Cosmos tokens to a recipient.
    /// @param toAddress Recipient bech32 Sei address (sei1...).
    /// @param denom     Token denomination (e.g. "usei", "uusdc").
    /// @param amount    Amount to send (denom native precision).
    /// @return success  True on success.
    function send(
        string memory toAddress,
        string memory denom,
        uint256 amount
    ) external returns (bool success);

    /// @notice Query a Cosmos-side token balance for a bech32 address.
    /// @param acc   Bech32 address (sei1...).
    /// @param denom Token denomination.
    /// @return amount Balance in the token's native precision.
    function balance(string memory acc, string memory denom)
        external
        view
        returns (uint256 amount);

    /// @notice Query all Cosmos-side token balances for a bech32 address.
    /// @param acc Bech32 address (sei1...).
    /// @return coins Array of Coin (denom + amount).
    function all_balances(string memory acc)
        external
        view
        returns (Coin[] memory coins);

    /// @notice Query the total on-chain supply of a denomination.
    /// @param denom Token denomination.
    /// @return amount Total supply.
    function totalSupply(string memory denom) external view returns (uint256 amount);

    /// @notice Query the supply of all denominations.
    /// @return coins Array of Coin representing total supply per denom.
    function supply(string memory denom) external view returns (Coin[] memory coins);

    /// @notice Query token metadata for a denomination.
    /// @param denom Token denomination.
    /// @return name    Token name.
    /// @return symbol  Token symbol.
    /// @return decimals Token decimals.
    function decimals(string memory denom)
        external
        view
        returns (string memory name, string memory symbol, uint8 decimals);
}

/// @notice The Sei bank precompile instance.
IBank constant BANK_PRECOMPILE = IBank(0x0000000000000000000000000000000000001002);

/// @title BankOperations
/// @notice Contract demonstrating bank precompile usage for sending native
///         Cosmos tokens and querying balances.
contract BankOperations {
    // ─── Events ───────────────────────────────────────────────────────────────

    event TokensSent(string indexed toAddress, string denom, uint256 amount);
    event BalanceQueried(string indexed addr, string denom, uint256 balance);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error SendFailed();
    error ZeroAmount();

    // ─── Send Functions ───────────────────────────────────────────────────────

    /// @notice Send a Cosmos token to a bech32 recipient.
    /// @param toAddress Recipient sei1... address.
    /// @param denom     Token denomination.
    /// @param amount    Amount in the denomination's native precision.
    function sendToken(
        string calldata toAddress,
        string calldata denom,
        uint256 amount
    ) external {
        if (amount == 0) revert ZeroAmount();

        bool success = BANK_PRECOMPILE.send(toAddress, denom, amount);
        if (!success) revert SendFailed();

        emit TokensSent(toAddress, denom, amount);
    }

    // ─── Query Functions ──────────────────────────────────────────────────────

    /// @notice Query a single token balance for a bech32 address.
    function getBalance(string calldata acc, string calldata denom)
        external
        view
        returns (uint256)
    {
        return BANK_PRECOMPILE.balance(acc, denom);
    }

    /// @notice Query all token balances for a bech32 address.
    function getAllBalances(string calldata acc)
        external
        view
        returns (IBank.Coin[] memory)
    {
        return BANK_PRECOMPILE.all_balances(acc);
    }

    /// @notice Query the total supply of a denomination.
    function getTotalSupply(string calldata denom) external view returns (uint256) {
        return BANK_PRECOMPILE.totalSupply(denom);
    }

    /// @notice Query token metadata (name, symbol, decimals).
    function getTokenMetadata(string calldata denom)
        external
        view
        returns (string memory name, string memory symbol, uint8 tokenDecimals)
    {
        return BANK_PRECOMPILE.decimals(denom);
    }
}
