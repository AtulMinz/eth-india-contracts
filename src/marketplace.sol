// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title AI NFT Marketplace
/// @notice Users can mint NFTs with their own artwork or generated AI prompts, list NFTs for sale, buy NFTs, and swap NFTs.
contract AINFTMarketplace is ERC721URIStorage, Ownable {
    //////////////////////////////////////////////////////////
    //////////////////////  State Variables  /////////////////
    //////////////////////////////////////////////////////////
    uint256 private s_tokenIdCounter;
    uint256 private s_listingFee = 0.01 ether; // Listing fee for the marketplace
    mapping(uint256 => ListedNFT) private s_listedNFTs;
    mapping(uint256 => SwapOffer) private s_swapOffers;

    struct ListedNFT {
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool isListed;
    }

    struct SwapOffer {
        uint256 offeredTokenId;
        uint256 requestedTokenId;
        address offerer;
    }

    //////////////////////////////////////////////////////////
    //////////////////////  Events  //////////////////////////
    //////////////////////////////////////////////////////////
    event NFTMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event NFTListed(uint256 indexed tokenId, address indexed owner, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed owner);
    event SwapOfferCreated(
        uint256 indexed offeredTokenId,
        uint256 indexed requestedTokenId,
        address indexed offerer
    );
    event SwapCompleted(uint256 indexed offeredTokenId, uint256 indexed requestedTokenId, address indexed accepter);

    //////////////////////////////////////////////////////////
    //////////////////////  Constructor  /////////////////////
    //////////////////////////////////////////////////////////
    constructor() ERC721("AINFTMarketplace", "AINFT") Ownable(msg.sender) {}

    //////////////////////////////////////////////////////////
    //////////////////////  Modifiers  ///////////////////////
    //////////////////////////////////////////////////////////
    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert("Not token owner");
        _;
    }

    //////////////////////////////////////////////////////////
    //////////////////  External Functions  //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Mint a new NFT
    /// @param tokenURI The URI of the token metadata stored on decentralized storage
    function mintNFT(string calldata tokenURI) external {
        uint256 newTokenId = s_tokenIdCounter++;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        emit NFTMinted(newTokenId, msg.sender, tokenURI);
    }

    /// @notice List an NFT for sale
    /// @param tokenId The ID of the token to list
    /// @param price The price of the NFT in wei
    function listNFT(uint256 tokenId, uint256 price) external payable onlyTokenOwner(tokenId) {
        if (price == 0) revert("Price cannot be zero");
        if (msg.value != s_listingFee) revert("Listing fee required");

        s_listedNFTs[tokenId] = ListedNFT({
            tokenId: tokenId,
            owner: payable(msg.sender),
            price: price,
            isListed: true
        });

        _transfer(msg.sender, address(this), tokenId);

        emit NFTListed(tokenId, msg.sender, price);
    }

    /// @notice Buy an NFT
    /// @param tokenId The ID of the token to buy
    function buyNFT(uint256 tokenId) external payable {
        ListedNFT storage nft = s_listedNFTs[tokenId];
        if (!nft.isListed) revert("Token not for sale");
        if (msg.value != nft.price) revert("Incorrect payment amount");

        address payable seller = nft.owner;
        nft.owner = payable(msg.sender);
        nft.isListed = false;

        _transfer(address(this), msg.sender, tokenId);
        seller.transfer(msg.value);

        emit NFTSold(tokenId, msg.sender, seller, nft.price);
    }

    /// @notice Delist an NFT
    /// @param tokenId The ID of the token to delist
    function delistNFT(uint256 tokenId) external onlyTokenOwner(tokenId) {
        ListedNFT storage nft = s_listedNFTs[tokenId];
        if (!nft.isListed) revert("Token not listed");

        nft.isListed = false;
        _transfer(address(this), msg.sender, tokenId);

        emit NFTDelisted(tokenId, msg.sender);
    }

    /// @notice Propose an NFT swap
    /// @param offeredTokenId The ID of the NFT you are offering
    /// @param requestedTokenId The ID of the NFT you want
    function proposeSwap(uint256 offeredTokenId, uint256 requestedTokenId) external onlyTokenOwner(offeredTokenId) {
        s_swapOffers[requestedTokenId] = SwapOffer({
            offeredTokenId: offeredTokenId,
            requestedTokenId: requestedTokenId,
            offerer: msg.sender
        });

        emit SwapOfferCreated(offeredTokenId, requestedTokenId, msg.sender);
    }

    /// @notice Accept an NFT swap
    /// @param requestedTokenId The ID of the NFT requested in the swap
    function acceptSwap(uint256 requestedTokenId) external onlyTokenOwner(requestedTokenId) {
        SwapOffer storage offer = s_swapOffers[requestedTokenId];
        if (offer.offerer == address(0)) revert("No swap offer exists");

        uint256 offeredTokenId = offer.offeredTokenId;
        address offerer = offer.offerer;

        delete s_swapOffers[requestedTokenId];

        _transfer(msg.sender, offerer, requestedTokenId);
        _transfer(offerer, msg.sender, offeredTokenId);

        emit SwapCompleted(offeredTokenId, requestedTokenId, msg.sender);
    }

    //////////////////////////////////////////////////////////
    //////////////////////  View Functions  //////////////////
    //////////////////////////////////////////////////////////

    /// @notice Get details of a listed NFT
    /// @param tokenId The ID of the token
    function getListedNFT(uint256 tokenId) external view returns (ListedNFT memory) {
        return s_listedNFTs[tokenId];
    }

    /// @notice Get details of a swap offer
    /// @param requestedTokenId The ID of the token requested in the swap
    function getSwapOffer(uint256 requestedTokenId) external view returns (SwapOffer memory) {
        return s_swapOffers[requestedTokenId];
    }

    /// @notice Get the current listing fee
    function getListingFee() external view returns (uint256) {
        return s_listingFee;
    }

    /// @notice Update the listing fee (owner only)
    /// @param newFee The new listing fee in wei
    function updateListingFee(uint256 newFee) external onlyOwner {
        s_listingFee = newFee;
    }
}
