//SPDX-License_identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {NFTMarketplace} from "src/marketplace.sol";

contract DeployNFTMarketPlace is Script {
    function run() external returns(NFTMarketplace) {
        vm.startBroadcast();

        NFTMarketplace nftMarketPlace = new NFTMarketplace();

        vm.stopBroadcast();

        return nftMarketPlace;
    }
}
