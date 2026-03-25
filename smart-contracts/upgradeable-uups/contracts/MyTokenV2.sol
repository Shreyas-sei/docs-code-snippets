// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title MyTokenV2 — UUPS upgradeable ERC20 token (Version 2) for Sei EVM
/// @notice Version 2: Adds capped supply and per-address transfer limits
/// @dev Upgrades MyTokenV1 via UUPS proxy pattern
contract MyTokenV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    // ─── New V2 Storage ────────────────────────────────────────────────────────
    // IMPORTANT: Never change the order or type of inherited storage slots.
    // Only append new variables at the end of the storage layout.

    /// @notice Maximum total supply cap (0 = no cap)
    uint256 public maxSupplyCap;

    /// @notice Per-address maximum transfer amount per transaction (0 = no limit)
    uint256 public transferLimit;

    event SupplyCapSet(uint256 newCap);
    event TransferLimitSet(uint256 newLimit);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Re-initializer for V2 upgrade — only runs once per upgrade
    /// @param _maxSupplyCap Maximum total supply (0 = uncapped)
    /// @param _transferLimit Per-tx transfer limit (0 = unlimited)
    function initializeV2(
        uint256 _maxSupplyCap,
        uint256 _transferLimit
    ) public reinitializer(2) {
        maxSupplyCap = _maxSupplyCap;
        transferLimit = _transferLimit;

        emit SupplyCapSet(_maxSupplyCap);
        emit TransferLimitSet(_transferLimit);
    }

    /// @notice Mint new tokens — respects supply cap
    function mint(address to, uint256 amount) public onlyOwner {
        if (maxSupplyCap > 0) {
            require(
                totalSupply() + amount <= maxSupplyCap,
                "MyTokenV2: supply cap exceeded"
            );
        }
        _mint(to, amount);
    }

    /// @notice Update the supply cap — only callable by owner
    function setMaxSupplyCap(uint256 newCap) public onlyOwner {
        maxSupplyCap = newCap;
        emit SupplyCapSet(newCap);
    }

    /// @notice Update per-transaction transfer limit — only callable by owner
    function setTransferLimit(uint256 newLimit) public onlyOwner {
        transferLimit = newLimit;
        emit TransferLimitSet(newLimit);
    }

    /// @notice Pause all token transfers — only callable by owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers — only callable by owner
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Returns the version of this contract implementation
    function version() public pure virtual returns (string memory) {
        return "V2";
    }

    /// @notice Authorize contract upgrades — only callable by owner
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // Required override for ERC20PausableUpgradeable
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        // Enforce per-transaction transfer limit (skip for mint/burn)
        if (transferLimit > 0 && from != address(0) && to != address(0)) {
            require(
                value <= transferLimit,
                "MyTokenV2: transfer exceeds per-tx limit"
            );
        }
        super._update(from, to, value);
    }
}
