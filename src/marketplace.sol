// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;  // Token counter
    
    struct ListedNFT {
        uint256 price;
        bool isListed;
        address owner;
    }

    mapping(uint256 => ListedNFT) public listedNFTs;
    uint256 public listingFee = 0.01 ether;

    event NFTMinted(address indexed owner, uint256 tokenId, string tokenURI);
    event NFTListed(address indexed owner, uint256 tokenId, uint256 price);
    event NFTDelisted(address indexed owner, uint256 tokenId);
    event NFTSold(address indexed buyer, uint256 tokenId, uint256 price);
    event SwapProposed(address indexed proposer, uint256 offeredTokenId, uint256 requestedTokenId);
    event SwapAccepted(address indexed acceptor, uint256 tokenId1, uint256 tokenId2);

    constructor() ERC721("NFTMarketplace", "ETHIND") Ownable(msg.sender) {}

    function mintNFT(string memory tokenURI) external returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        emit NFTMinted(msg.sender, newTokenId, tokenURI);
        return newTokenId;
    }

    function listNFT(uint256 tokenId, uint256 price) external payable {
        require(msg.value == listingFee, "Listing fee required");
        require(ownerOf(tokenId) == msg.sender, "Only the owner can list this NFT");
        require(price > 0, "Price must be greater than zero");

        listedNFTs[tokenId] = ListedNFT(price, true, msg.sender);
        emit NFTListed(msg.sender, tokenId, price);
    }

    function buyNFT(uint256 tokenId) external payable {
        ListedNFT memory listedNFT = listedNFTs[tokenId];
        require(listedNFT.isListed, "NFT not listed for sale");
        require(msg.value == listedNFT.price, "Incorrect payment amount");

        address seller = listedNFT.owner;
        _transfer(seller, msg.sender, tokenId);

        payable(seller).transfer(msg.value);
        listedNFTs[tokenId].isListed = false;

        emit NFTSold(msg.sender, tokenId, listedNFT.price);
    }

    function delistNFT(uint256 tokenId) external {
        ListedNFT memory listedNFT = listedNFTs[tokenId];
        require(listedNFT.isListed, "NFT is not listed");
        require(listedNFT.owner == msg.sender, "Only the owner can delist the NFT");

        listedNFTs[tokenId].isListed = false;

        emit NFTDelisted(msg.sender, tokenId);
    }

    function proposeSwap(uint256 offeredTokenId, uint256 requestedTokenId) external {
        require(ownerOf(offeredTokenId) == msg.sender, "You must own the offered NFT");
        require(ownerOf(requestedTokenId) != msg.sender, "You can't propose a swap with your own NFT");
        emit SwapProposed(msg.sender, offeredTokenId, requestedTokenId);
    }

    function acceptSwap(uint256 offeredTokenId) external {
        uint256 requestedTokenId = 1234; // This is a simplified swap. A better implementation would use a mapping.
        address offerer = ownerOf(offeredTokenId);

        require(offerer != msg.sender, "You can't accept your own offer");

        _transfer(msg.sender, offerer, offeredTokenId);
        _transfer(offerer, msg.sender, requestedTokenId);
        emit SwapAccepted(msg.sender, offeredTokenId, requestedTokenId);
    }

    // Getter for total supply
    function totalSupply() external view returns (uint256) {
        return _tokenIds;
    }

    function getListingFee() external view returns (uint256) {
        return listingFee;
    }

    // Get the Listed NFT details by tokenId
    function getListedNFT(uint256 tokenId) external view returns (ListedNFT memory) {
        return listedNFTs[tokenId];
    }
}
