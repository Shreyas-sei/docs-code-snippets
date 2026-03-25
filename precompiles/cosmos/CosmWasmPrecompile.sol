// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CosmWasmPrecompile
/// @notice Demonstrates calling and querying CosmWasm smart contracts from
///         Solidity using the Sei CosmWasm precompile.
///
/// @dev The CosmWasm precompile is at 0x0000000000000000000000000000000000001002.
///      Note: On Sei, this address is shared with the bank precompile for
///      query-only operations. The dedicated CosmWasm execute precompile
///      may differ — check the official docs for the latest addresses.
///
/// This contract lets EVM contracts:
///   - Execute CosmWasm contract entrypoints
///   - Query CosmWasm contract state
///   - Instantiate new CosmWasm contracts
interface ICosmWasm {
    /// @notice Execute a CosmWasm contract.
    /// @param contractAddress Bech32 CosmWasm contract address (sei1...).
    /// @param msg             JSON-encoded execute message.
    /// @param coins           Comma-separated coin string, e.g. "100usei" (or "" for none).
    /// @return response       Raw JSON response bytes from the contract.
    function execute(
        string memory contractAddress,
        bytes memory msg,
        bytes memory coins
    ) external payable returns (bytes memory response);

    /// @notice Query a CosmWasm contract's state (read-only).
    /// @param contractAddress Bech32 CosmWasm contract address.
    /// @param req             JSON-encoded query message.
    /// @return response       Raw JSON response bytes.
    function query(
        string memory contractAddress,
        bytes memory req
    ) external view returns (bytes memory response);

    /// @notice Instantiate a new CosmWasm contract from a code ID.
    /// @param codeID          Stored code ID.
    /// @param admin           Admin bech32 address (or "" for no admin).
    /// @param msg             JSON-encoded instantiate message.
    /// @param label           Human-readable contract label.
    /// @param coins           Comma-separated coin string for initial funds.
    /// @return contractAddr   Bech32 address of the newly instantiated contract.
    function instantiate(
        uint64 codeID,
        string memory admin,
        bytes memory msg,
        string memory label,
        bytes memory coins
    ) external payable returns (string memory contractAddr);
}

/// @notice The Sei CosmWasm precompile instance.
ICosmWasm constant COSMWASM_PRECOMPILE =
    ICosmWasm(0x0000000000000000000000000000000000009001);

/// @title CosmWasmCaller
/// @notice Demonstrates cross-VM calls between Solidity and CosmWasm contracts.
contract CosmWasmCaller {
    // ─── Events ───────────────────────────────────────────────────────────────

    event ContractExecuted(string indexed contractAddress, bytes response);
    event ContractQueried(string indexed contractAddress, bytes response);
    event ContractInstantiated(string indexed contractAddress, uint64 codeId);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ExecutionFailed();

    // ─── Execute ──────────────────────────────────────────────────────────────

    /// @notice Execute a CosmWasm contract entrypoint.
    /// @param contractAddress Bech32 contract address (sei1...).
    /// @param executeMsg      JSON-encoded execute message (e.g. '{"transfer":{"recipient":"sei1..."}}').
    function executeContract(
        string calldata contractAddress,
        bytes calldata executeMsg
    ) external payable returns (bytes memory response) {
        response = COSMWASM_PRECOMPILE.execute{value: msg.value}(
            contractAddress,
            executeMsg,
            ""
        );
        emit ContractExecuted(contractAddress, response);
    }

    /// @notice Execute a CosmWasm contract with attached native tokens.
    /// @param contractAddress Bech32 contract address.
    /// @param executeMsg      JSON-encoded execute message.
    /// @param coins           Coin string (e.g. "100usei,50uatom").
    function executeContractWithFunds(
        string calldata contractAddress,
        bytes calldata executeMsg,
        bytes calldata coins
    ) external payable returns (bytes memory response) {
        response = COSMWASM_PRECOMPILE.execute{value: msg.value}(
            contractAddress,
            executeMsg,
            coins
        );
        emit ContractExecuted(contractAddress, response);
    }

    // ─── Query ────────────────────────────────────────────────────────────────

    /// @notice Query a CosmWasm contract's state.
    /// @param contractAddress Bech32 contract address.
    /// @param queryMsg        JSON-encoded query message (e.g. '{"balance":{"address":"sei1..."}}').
    function queryContract(
        string calldata contractAddress,
        bytes calldata queryMsg
    ) external view returns (bytes memory response) {
        return COSMWASM_PRECOMPILE.query(contractAddress, queryMsg);
    }

    // ─── Instantiate ──────────────────────────────────────────────────────────

    /// @notice Instantiate a new CosmWasm contract.
    /// @param codeId    Stored code ID on Sei.
    /// @param admin     Admin bech32 address.
    /// @param initMsg   JSON-encoded instantiate message.
    /// @param label     Human-readable label for the contract.
    function instantiateContract(
        uint64 codeId,
        string calldata admin,
        bytes calldata initMsg,
        string calldata label
    ) external payable returns (string memory contractAddr) {
        contractAddr = COSMWASM_PRECOMPILE.instantiate{value: msg.value}(
            codeId,
            admin,
            initMsg,
            label,
            ""
        );
        emit ContractInstantiated(contractAddr, codeId);
    }

    receive() external payable {}
}
