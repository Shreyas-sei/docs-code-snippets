// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyOFT
 * @notice Omnichain Fungible Token (OFT) using LayerZero V2.
 *         Enables native token bridging between Sei and other LayerZero-connected chains.
 *
 * @dev Inherits from LayerZero's OFT contract which handles:
 *   - Cross-chain `send` / `receive` via the LayerZero endpoint
 *   - Token minting on destination and burning on source
 *
 * LayerZero endpoint on Sei mainnet: 0x1a44076050125825900e736c501f859c50fE728c
 * Sei EID (Endpoint ID): 30280
 *
 * Full chain list: https://docs.layerzero.network/v2/deployments/deployed-contracts
 */
contract MyOFT is OFT {
    /**
     * @param _name       Token name (e.g. "My Token")
     * @param _symbol     Token symbol (e.g. "MTK")
     * @param _lzEndpoint LayerZero V2 endpoint address on the deployed chain
     * @param _delegate   Address that will own this OFT and can configure peers
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

    /**
     * @notice Mint tokens to an address (owner-only).
     * @dev Call this on the origin chain to seed supply before bridging.
     * @param _to     Recipient address
     * @param _amount Amount to mint (in wei, 18 decimals)
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}
