// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title MyToken — ERC20 token example for Sei EVM
/// @notice Demonstrates a standard ERC20 token with burn, pause, and permit extensions
contract MyToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply,
        address initialOwner
    )
        ERC20(name, symbol)
        Ownable(initialOwner)
        ERC20Permit(name)
    {
        _decimals = decimals_;
        _mint(initialOwner, initialSupply * (10 ** decimals_));
    }

    /// @notice Returns the number of decimals for this token
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Mint new tokens — only callable by owner
    /// @param to Recipient address
    /// @param amount Amount to mint (in base units)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Pause all token transfers — only callable by owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers — only callable by owner
    function unpause() public onlyOwner {
        _unpause();
    }

    // Required override for ERC20Pausable
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
