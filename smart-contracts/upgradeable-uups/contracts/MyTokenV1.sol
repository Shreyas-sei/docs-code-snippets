// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title MyTokenV1 — UUPS upgradeable ERC20 token (Version 1) for Sei EVM
/// @notice Version 1: Standard ERC20 with mint, burn, pause, and permit
/// @dev Uses the UUPS (Universal Upgradeable Proxy Standard) upgrade pattern
contract MyTokenV1 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer replaces the constructor for upgradeable contracts
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param initialOwner Address that will own the contract
    function initialize(
        string memory name,
        string memory symbol,
        address initialOwner
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();

        // Mint initial supply of 1,000,000 tokens to deployer
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    /// @notice Mint new tokens — only callable by owner
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

    /// @notice Returns the version of this contract implementation
    function version() public pure virtual returns (string memory) {
        return "V1";
    }

    /// @notice Authorize contract upgrades — only callable by owner
    /// @dev Required by UUPSUpgradeable
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
        super._update(from, to, value);
    }
}
