// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IGovernance
/// @notice Interface for the Sei Governance precompile.
/// @dev Precompile address: 0x0000000000000000000000000000000000001006
interface IGovernance {
    // ─── Events ───────────────────────────────────────────────────────────────

    /// @notice Emitted when a vote is cast on a proposal.
    event Vote(address indexed voter, uint64 proposalId, int32 option);

    /// @notice Emitted when a new proposal is submitted.
    event SubmitProposal(address indexed proposer, uint64 proposalId);

    // ─── Write Methods ────────────────────────────────────────────────────────

    /// @notice Cast a vote on an active governance proposal.
    /// @param proposalId On-chain proposal ID.
    /// @param option     Vote option:
    ///                   1 = YES, 2 = ABSTAIN, 3 = NO, 4 = NO_WITH_VETO.
    /// @return success True on success.
    function vote(uint64 proposalId, int32 option) external returns (bool success);

    /// @notice Submit a new governance proposal.
    /// @param proposalJSON  JSON-encoded proposal content string.
    /// @return success True on success.
    function submitProposal(string memory proposalJSON)
        external
        payable
        returns (bool success);
}
