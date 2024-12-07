// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/marketplace.sol";

contract AINFTMarketplaceTest is Test {
    AINFTMarketplace private marketplace;

    address private user1 = address(0x1);
    address private user2 = address(0x2);

    string private constant TOKEN_URI = "ipfs://sample-token-uri";

    function setUp() public {
        // Deploy the marketplace contract
        marketplace = new AINFTMarketplace();

        // Give user1 and user2 some Ether for testing
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testMintNFT() public {
        vm.startPrank(user1);

        // Mint an NFT
        uint256 tokenId = marketplace.mintNFT(TOKEN_URI);

        // Verify ownership and metadata
        assertEq(marketplace.ownerOf(tokenId), user1);
        assertEq(marketplace.tokenURI(tokenId), TOKEN_URI);

        vm.stopPrank();
    }

    function testListNFT() public {
        vm.startPrank(user1);

        // Mint and list an NFT
        uint256 tokenId = marketplace.mintNFT(TOKEN_URI);
        uint256 listingFee = marketplace.getListingFee();

        marketplace.listNFT{value: listingFee}(tokenId, 1 ether);

        // Verify listing
        AINFTMarketplace.ListedNFT memory listedNFT = marketplace.getListedNFT(tokenId);
        assertTrue(listedNFT.isListed);
        assertEq(listedNFT.price, 1 ether);
        assertEq(listedNFT.owner, user1);

        vm.stopPrank();
    }

    function testBuyNFT() public {
        vm.startPrank(user1);

        // Mint and list an NFT
        uint256 tokenId = marketplace.mintNFT(TOKEN_URI);
        uint256 listingFee = marketplace.getListingFee();
        marketplace.listNFT{value: listingFee}(tokenId, 1 ether);

        vm.stopPrank();

        vm.startPrank(user2);

        // Buy the NFT
        marketplace.buyNFT{value: 1 ether}(tokenId);

        // Verify ownership
        assertEq(marketplace.ownerOf(tokenId), user2);

        vm.stopPrank();
    }

    function testDelistNFT() public {
        vm.startPrank(user1);

        // Mint and list an NFT
        uint256 tokenId = marketplace.mintNFT(TOKEN_URI);
        uint256 listingFee = marketplace.getListingFee();
        marketplace.listNFT{value: listingFee}(tokenId, 1 ether);

        // Delist the NFT
        marketplace.delistNFT(tokenId);

        // Verify delisting
        AINFTMarketplace.ListedNFT memory listedNFT = marketplace.getListedNFT(tokenId);
        assertFalse(listedNFT.isListed);
        assertEq(marketplace.ownerOf(tokenId), user1);

        vm.stopPrank();
    }

    function testProposeAndAcceptSwap() public {
        vm.startPrank(user1);

        // Mint two NFTs
        uint256 tokenId1 = marketplace.mintNFT(TOKEN_URI);
        uint256 tokenId2 = marketplace.mintNFT(TOKEN_URI);

        vm.stopPrank();

        vm.startPrank(user2);

        // User1 proposes a swap
        marketplace.proposeSwap(tokenId1, tokenId2);

        // Verify swap offer
        // Replace with logic for proper swap offer validation in the contract

        vm.stopPrank();
    }
}
