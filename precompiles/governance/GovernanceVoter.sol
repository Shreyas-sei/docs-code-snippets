// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGovernance.sol";

/// @title GovernanceVoter
/// @notice A governance participation contract that casts votes and submits
///         proposals on behalf of its users via the Sei governance precompile.
///
/// @dev Uses the Sei Governance precompile at 0x0000000000000000000000000000000000001006.
///
/// Vote options (Cosmos SDK VoteOption):
///   1 = YES
///   2 = ABSTAIN
///   3 = NO
///   4 = NO_WITH_VETO
contract GovernanceVoter {
    // ─── Constants ────────────────────────────────────────────────────────────

    IGovernance constant GOVERNANCE =
        IGovernance(0x0000000000000000000000000000000000001006);

    int32 constant VOTE_YES          = 1;
    int32 constant VOTE_ABSTAIN      = 2;
    int32 constant VOTE_NO           = 3;
    int32 constant VOTE_NO_WITH_VETO = 4;

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;

    /// @notice Records how each address voted on each proposal.
    mapping(address => mapping(uint64 => int32)) public voteRecord;

    // ─── Events ───────────────────────────────────────────────────────────────

    event VoteCast(address indexed voter, uint64 proposalId, int32 option);
    event ProposalSubmitted(address indexed proposer, string title);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error VoteFailed();
    error ProposalFailed();
    error InvalidVoteOption();
    error NotOwner();

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─── Vote Functions ───────────────────────────────────────────────────────

    /// @notice Cast a vote on an active governance proposal.
    /// @param proposalId On-chain proposal ID.
    /// @param option     1=YES, 2=ABSTAIN, 3=NO, 4=NO_WITH_VETO.
    function castVote(uint64 proposalId, int32 option) external {
        if (option < 1 || option > 4) revert InvalidVoteOption();

        bool success = GOVERNANCE.vote(proposalId, option);
        if (!success) revert VoteFailed();

        voteRecord[msg.sender][proposalId] = option;
        emit VoteCast(msg.sender, proposalId, option);
    }

    /// @notice Vote YES on a proposal.
    function voteYes(uint64 proposalId) external {
        bool success = GOVERNANCE.vote(proposalId, VOTE_YES);
        if (!success) revert VoteFailed();
        voteRecord[msg.sender][proposalId] = VOTE_YES;
        emit VoteCast(msg.sender, proposalId, VOTE_YES);
    }

    /// @notice Vote NO on a proposal.
    function voteNo(uint64 proposalId) external {
        bool success = GOVERNANCE.vote(proposalId, VOTE_NO);
        if (!success) revert VoteFailed();
        voteRecord[msg.sender][proposalId] = VOTE_NO;
        emit VoteCast(msg.sender, proposalId, VOTE_NO);
    }

    /// @notice Vote ABSTAIN on a proposal.
    function voteAbstain(uint64 proposalId) external {
        bool success = GOVERNANCE.vote(proposalId, VOTE_ABSTAIN);
        if (!success) revert VoteFailed();
        voteRecord[msg.sender][proposalId] = VOTE_ABSTAIN;
        emit VoteCast(msg.sender, proposalId, VOTE_ABSTAIN);
    }

    /// @notice Vote NO_WITH_VETO on a proposal.
    function voteNoWithVeto(uint64 proposalId) external {
        bool success = GOVERNANCE.vote(proposalId, VOTE_NO_WITH_VETO);
        if (!success) revert VoteFailed();
        voteRecord[msg.sender][proposalId] = VOTE_NO_WITH_VETO;
        emit VoteCast(msg.sender, proposalId, VOTE_NO_WITH_VETO);
    }

    // ─── Proposal Submission ─────────────────────────────────────────────────

    /// @notice Submit a governance proposal with an initial deposit.
    /// @param title       Human-readable title (included in proposalJSON).
    /// @param proposalJSON Full JSON-encoded proposal content.
    function submitProposal(
        string calldata title,
        string calldata proposalJSON
    ) external payable onlyOwner {
        bool success = GOVERNANCE.submitProposal{value: msg.value}(proposalJSON);
        if (!success) revert ProposalFailed();
        emit ProposalSubmitted(msg.sender, title);
    }

    // ─── View Functions ───────────────────────────────────────────────────────

    /// @notice Returns how a given address voted on a proposal.
    ///         Returns 0 if the address has not voted through this contract.
    function getVote(address voter, uint64 proposalId) external view returns (int32) {
        return voteRecord[voter][proposalId];
    }

    // ─── Owner Functions ──────────────────────────────────────────────────────

    /// @notice Transfer contract ownership.
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    receive() external payable {}
}
