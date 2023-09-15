pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Addresses} from "@test/proposals/Addresses.sol";
import {Proposal} from "@test/proposals/proposalTypes/Proposal.sol";

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {ERC1155SeasonOne, TokenIdRewardAmount} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {ERC1155SeasonTwo} from "@protocol/nfts/seasons/ERC1155SeasonTwo.sol";

contract zip001 is Proposal {
    string public name = "ZIP001";
    string public description = "Season 1 Capsules NFTs and logic contracts ";
    bool public mainnetDeployed = false;
    bool public testnetDeployed = false;

    function deploy(Addresses addresses, address) public {
        Core core = Core(addresses.getAddress("CORE"));

        /// ERC1155MaxSupplyMintable
        string memory _metadataBaseUri = string(
            abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), vm.envString("DOMAIN"), "/")
        );

        // SeasonOne ERC1155 setup
        ERC1155MaxSupplyMintable erc1155SeasonOneCapsules = new ERC1155MaxSupplyMintable(
            address(core),
            string(abi.encodePacked(_metadataBaseUri, "/seasons/1/capsules/metadata/")) //TODO confirm path
        );
        addresses.addAddress("ERC1155_SEASON_ONE_CAPSULES", address(erc1155SeasonOneCapsules));

        // TODO setSupplyCaps for some reason not working
        // set supply caps for the different season one tiers
        // erc1155SeasonOneCapsules.setSupplyCap(1, 4000); // TODO numbers?

        // Config tokenId to Reaward Amount
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, tokenSupply: 1000, rewardAmount: 400});
        tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, tokenSupply: 1000, rewardAmount: 1000});
        tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, tokenSupply: 1000, rewardAmount: 1600});

        // SeasonOne Logic contract setup
        ERC1155SeasonOne erc1155SeasonOne = new ERC1155SeasonOne(
            address(core),
            address(erc1155SeasonOneCapsules),
            addresses.getAddress("TOKEN")
            // tokenIdRewardAmounts //TODO config contract
        );
        addresses.addAddress("ERC1155_SEASON_ONE", address(erc1155SeasonOne));

        // SeasonTwo ERC1155 setup
        ERC1155MaxSupplyMintable erc1155SeasonTwoCapsules = new ERC1155MaxSupplyMintable(
            address(core),
            string(abi.encodePacked(_metadataBaseUri, "/seasons/2/capsules/metadata/")) //TODO confirm path
        );
        addresses.addAddress("ERC1155_SEASON_TWO_CAPSULES", address(erc1155SeasonTwoCapsules));

        // TODO setup supplyCaps for SeasonOne nft capsules
    }

    function afterDeploy(Addresses, address) external {}

    function build(Addresses) external {}

    function run(Addresses, address) external {}

    function teardown(Addresses, address) external {}

    function validate(Addresses, address) external {}
}
