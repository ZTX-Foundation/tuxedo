pragma solidity 0.8.18;

import {console} from "@forge-std/console.sol";
import {Core} from "@protocol/core/Core.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {Addresses} from "@test/proposals/Addresses.sol";
import {Proposal} from "@test/proposals/proposalTypes/Proposal.sol";

import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";

import {TokenIdRewardAmount} from "@protocol/nfts/seasons/SeasonsBase.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {ERC1155SeasonTwo} from "@protocol/nfts/seasons/ERC1155SeasonTwo.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";

contract zip001 is Proposal {
    string public name = "ZIP001";
    string public description = "Capsules NFTs and Seaon's One logic contracts ";
    bool public mainnetDeployed = false;
    bool public testnetDeployed = false;

    function deploy(Addresses addresses, address) public {
        Core core = Core(addresses.getAddress("CORE"));

        // SeasonsTokenIdRegistry setup
        SeasonsTokenIdRegistry seasonsTokenIdRegistry = new SeasonsTokenIdRegistry(address(core));
        addresses.addAddress("SEASONS_TOKENID_REGISTRY", address(seasonsTokenIdRegistry));

        /// ERC1155MaxSupplyMintable
        string memory _metadataBaseUri = string(
            abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), vm.envString("DOMAIN"), "/")
        );

        // CapsulesNFT ERC1155 setup
        ERC1155MaxSupplyMintable erc1155CapsulesNFT = new ERC1155MaxSupplyMintable(
            address(core),
            string(abi.encodePacked(_metadataBaseUri, "/seasons/1/capsules/metadata/")) //TODO confirm path
        );
        addresses.addAddress("ERC1155_CAPSULES_NFT", address(erc1155CapsulesNFT));

        // Config tokenId to Reaward Amount
        TokenIdRewardAmount[] memory tokenIdRewardAmounts = new TokenIdRewardAmount[](3);
        tokenIdRewardAmounts[0] = TokenIdRewardAmount({tokenId: 1, rewardAmount: 400});
        tokenIdRewardAmounts[1] = TokenIdRewardAmount({tokenId: 2, rewardAmount: 1000});
        tokenIdRewardAmounts[2] = TokenIdRewardAmount({tokenId: 3, rewardAmount: 1600});

        // SeasonOne Logic contract setup
        ERC1155SeasonOne erc1155SeasonOne = new ERC1155SeasonOne(
            address(core),
            address(erc1155CapsulesNFT),
            addresses.getAddress("TOKEN"),
            address(seasonsTokenIdRegistry)
        );
        addresses.addAddress("ERC1155_SEASON_ONE", address(erc1155SeasonOne));

        // TODO erc1155.setSupplyCap(1, 4000); needs to be called by admin before this?
        // erc1155SeasonOne.configSeasonDistribution(tokenIdRewardAmounts);
    }

    function afterDeploy(Addresses, address) external {
        // TODO give seasonOne contract the registry operator role?
    }

    function build(Addresses) external {}

    function run(Addresses, address) external {}

    function teardown(Addresses, address) external {}

    function validate(Addresses, address) external {}
}
