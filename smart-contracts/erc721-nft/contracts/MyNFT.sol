// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @title MyNFT — ERC721 NFT contract example for Sei EVM
/// @notice Demonstrates a standard ERC721 NFT collection with enumerable, URI storage, and pause support
contract MyNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable,
    ERC721Burnable
{
    uint256 private _nextTokenId;

    uint256 public maxSupply;
    uint256 public mintPrice;
    string private _baseTokenURI;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string uri);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        string memory baseURI,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        _baseTokenURI = baseURI;
    }

    /// @notice Mint a new NFT — requires payment of mintPrice
    /// @param to Recipient address
    /// @param uri Metadata URI for this token
    function safeMint(address to, string memory uri) public payable {
        require(msg.value >= mintPrice, "MyNFT: insufficient payment");
        require(_nextTokenId < maxSupply, "MyNFT: max supply reached");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit NFTMinted(to, tokenId, uri);
    }

    /// @notice Owner can mint without payment (airdrop)
    /// @param to Recipient address
    /// @param uri Metadata URI for this token
    function ownerMint(address to, string memory uri) public onlyOwner {
        require(_nextTokenId < maxSupply, "MyNFT: max supply reached");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit NFTMinted(to, tokenId, uri);
    }

    /// @notice Update mint price — only callable by owner
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    /// @notice Update base URI — only callable by owner
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @notice Pause transfers — only callable by owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause transfers — only callable by owner
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Withdraw contract balance to owner
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "MyNFT: no funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "MyNFT: withdrawal failed");
    }

    /// @notice Returns the current total number of tokens minted
    function currentSupply() public view returns (uint256) {
        return _nextTokenId;
    }

    // ─── Required Overrides ────────────────────────────────────────────────────

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
