// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@forge-std/Script.sol";
import {console2} from "@forge-std/console2.sol";
import {Token} from "@protocol/token/Token.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Core} from "@protocol/core/Core.sol";
import {GlobalReentrancyLock} from "@protocol/core/GlobalReentrancyLock.sol";
import {ERC1155MaxSupplyMintable} from "@protocol/nfts/ERC1155MaxSupplyMintable.sol";
import {ERC1155AdminMinter} from "@protocol/nfts/ERC1155AdminMinter.sol";
import {Roles} from "@protocol/core/Roles.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC20Splitter} from "@protocol/finance/ERC20Splitter.sol";
import {ERC1155AutoGraphMinter} from "@protocol/nfts/ERC1155AutoGraphMinter.sol";
import {GameConsumer} from "@protocol/game/GameConsumer.sol";
import {SeasonsTokenIdRegistry} from "@protocol/nfts/seasons/SeasonsTokenIdRegistry.sol";
import {ERC1155SeasonOne} from "@protocol/nfts/seasons/ERC1155SeasonOne.sol";
import {HashValidator} from "@protocol/nfts/HashValidator.sol";
import {BatchProcessor} from "@protocol/nfts/BatchProcessor.sol";
import {RateManager} from "@protocol/nfts/RateManager.sol";
import {WhitelistManager} from "@protocol/nfts/WhitelistManager.sol";

contract DeployToZkSync is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        string memory tokenName = vm.envString("TOKEN_NAME");
        string memory tokenSymbol = vm.envString("TOKEN_SYMBOL");

        // string memory environment = vm.envOr("ENVIRONMENT", string("localnet"));
        // string memory addressPath = string(abi.encodePacked("proposals/Addresses/", environment, ".json"));
        // Addresses addresses = new Addresses(addressPath);

        /// Token:                                  0x8c4B36F7ceEeE121b0723D31D92866736b067B75
        /// Core:                                   0x05f102e577C0ccBa029ea80EFB6e8d83152e8800
        /// GlobalReentrancyLock:                   0xc152d69DA77af4044e4F50c6bdEe367d0B2F0c42
        /// ERC1155MaxSupplyMintable (wearables):   0xEfEa0c8dEf5dB7442538e2C51e2dB92B44C62D3a
        /// ERC1155AdminMinter:                     0x68c459B77C31126faCDAAa87d60D00A727F10Cc7
        /// TimelockController:                     0x621A49e9d9C269BE3F8641585c17e7A320EfbdC6
        /// ERC1155MaxSupplyMintable (consumables): 0x16280Bb89C1d8812E9AA724D7E6cCA988be321C0
        /// ERC1155MaxSupplyMintable (placeables):  0x181EE014eA2fa80256F8E96a0f5Ef6147586F010
        /// ERC20Splitter:                          0x2200129856d586726AE66baCCcB691a2E77c28d8
        /// ERC1155AutoGraphMinter:                 0x452b8F974053e7670E3C2725fc464263FE7DE083
        /// GameConsumer:                           0x34b18ce4db673bB427F06410024efeAA62E11C49
        /// SeasonsTokenIdRegistry:                 0x36Ca4eAD84a0c778F6763b81cFf148BC666b46CD

        Core _core = Core(address(0x05f102e577C0ccBa029ea80EFB6e8d83152e8800));

        /// @dev zip000
        // vm.startBroadcast(deployerPrivateKey);

        // // Deploy your token
        // Token token = new Token(
        //     tokenName,
        //     tokenSymbol
        // );

        // console2.log("Token deployed at:", address(token));

        // vm.stopBroadcast();

        /// -----------------------------------------------------------------------------------------------

        /// @dev zip001

        // vm.startBroadcast(deployerPrivateKey);

        // Core _core = new Core();
        // console2.log("Core deployed at:", address(_core));

        // /// GlobalReentrancyLock
        // GlobalReentrancyLock globalReentrancyLock = new GlobalReentrancyLock(address(_core));
        // console2.log("GlobalReentrancyLock deployed at:", address(globalReentrancyLock));

        /// NTF contracts
        /// Setup metadata base uri
        // string memory _metadataBaseUri = string(
        //     abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), ".", vm.envString("DOMAIN"), "/")
        // );

        // /// Wearables NFT contract
        // ERC1155MaxSupplyMintable erc1155Wearables = new ERC1155MaxSupplyMintable(
        //     address(0xD04C79b879DE7cf0EF8CD3767847dD644E86293c),
        //     string(abi.encodePacked(_metadataBaseUri, "wearables/metadata/")),
        //     "ZTX Wearables",
        //     "ZTXW"
        // );

        // console2.log("ERC1155MaxSupplyMintable deployed at:", address(erc1155Wearables));

        // ERC1155AdminMinter minter = new ERC1155AdminMinter(address(_core));
        // console2.log("ERC1155AdminMinter deployed at:", address(minter));

        // // Setup ADMIN_MULTISIG
        // _core.grantRole(Roles.ADMIN, address(0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C));

        // /// Set global lock
        // _core.setGlobalLock(address(0xc152d69DA77af4044e4F50c6bdEe367d0B2F0c42));

        // /// Set LOCKER role for all NFT minting contracts
        // _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(erc1155Wearables));
        // _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(minter));

        // /// Set MINTER role for all NFT minting contracts
        // _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(erc1155Wearables));
        // _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(minter));

        // vm.stopBroadcast();

        /// -----------------------------------------------------------------------------------------------

        /// @dev zip002

        // vm.startBroadcast(deployerPrivateKey);

        // /// Admin timelock controller
        // address[] memory adminTimelockProposersExecutors = new address[](1);

        // adminTimelockProposersExecutors[0] = address(0x5Ec41e3a9c712D0BBC26d2CbA0E653c5d2cc982C);
        // TimelockController _adminTimelock = new TimelockController(
        //     0, // zero delay
        //     adminTimelockProposersExecutors,
        //     adminTimelockProposersExecutors,
        //     address(0) // No admin requried
        // );

        // console2.log("TimelockController deployed at:", address(_adminTimelock));
        
        // /// For the sake of testing, give the ADMIN role to the ADMIN_TIMELOCK_CONTROLLER.
        // /// This is not possible onchain as the deployer is not an Admin
        // _core.grantRole(Roles.ADMIN, address(_adminTimelock));
        
        // /// The ADMIN_MULTISIG now needs to give the ADMIN role to the ADMIN_TIMELOCK_CONTROLLER
        // console2.log("Please give Roles.Admin to the ADMIN_TIMELOCK_CONTROLLER from the ADMIN_MULTISIG");

        // vm.stopBroadcast();

        /// -----------------------------------------------------------------------------------------------

        /// @dev zip003

        vm.startBroadcast(deployerPrivateKey);

        /// NTF contracts
        /// Setup metadata base uri
        // string memory _metadataBaseUri = string(
        //     abi.encodePacked("https://meta.", vm.envString("ENVIRONMENT"), ".", vm.envString("DOMAIN"), "/")
        // );

        // /// Consumables NFT contract
        // ERC1155MaxSupplyMintable erc1155Consumables = new ERC1155MaxSupplyMintable(
        //     address(_core),
        //     string(abi.encodePacked(_metadataBaseUri, "consumables/metadata/")),
        //     "ZTX Consumables",
        //     "ZTXC"
        // );
        // console2.log("ERC1155MaxSupplyMintable deployed at:", address(erc1155Consumables));

        // /// Placeables NFT contract
        // ERC1155MaxSupplyMintable erc1155Placeables = new ERC1155MaxSupplyMintable(
        //     address(_core),
        //     string(abi.encodePacked(_metadataBaseUri, "placeables/metadata/")),
        //     "ZTX Placeables",
        //     "ZTXP"
        // );
        // console2.log("ERC1155MaxSupplyMintable deployed at:", address(erc1155Placeables));

        // /// ERC20Splitter allocation settings
        // ERC20Splitter.Allocation[] memory allocations = new ERC20Splitter.Allocation[](2);
        // allocations[0].deposit = address(0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9);
        // allocations[0].ratio = 5_000;
        // allocations[1].deposit = address(0x511d18d86e7BC44Dff06276F410d2CC24a1221A5);
        // allocations[1].ratio = 5_000;

        // /// ERC20Splitter consumable splitter contract
        // ERC20Splitter consumableSplitter = new ERC20Splitter(
        //     address(_core),
        //     address(0x8c4B36F7ceEeE121b0723D31D92866736b067B75),
        //     allocations
        // );
        // console2.log("ERC20Splitter deployed at:", address(consumableSplitter));

        /// *

        /// AutoGraphMinter contract
        address[] memory whitelistedContracts = new address[](3);
        whitelistedContracts[0] = address(0xEfEa0c8dEf5dB7442538e2C51e2dB92B44C62D3a); // wearables
        whitelistedContracts[1] = address(0x16280Bb89C1d8812E9AA724D7E6cCA988be321C0); // consumables
        whitelistedContracts[2] = address(0x181EE014eA2fa80256F8E96a0f5Ef6147586F010); // placeables
        
        // Deploy libraries first (they are linked automatically)
        console2.log("Deploying libraries...");
        
        // Deploy main contract
        ERC1155AutoGraphMinter erc1155AutoGraphMinter = new ERC1155AutoGraphMinter(
            address(0x05f102e577C0ccBa029ea80EFB6e8d83152e8800), // core
            whitelistedContracts,
            3, // replenish rate per second
            250_000, // buffer cap
            address(0x0e6aCa776b3d12dd85363Fd6050eE05A4a242be9), // payment recipient
            1 // expiry token hours valid
        );
        console2.log("ERC1155AutoGraphMinter deployed at:", address(erc1155AutoGraphMinter));

        /// Game consumer
        // GameConsumer gameConsumer = new GameConsumer(
        //     address(_core),
        //     address(0x0C8AD0e8349fd7662Db2EAC0cF4F1c7AB8558155),
        //     address(0x2200129856d586726AE66baCCcB691a2E77c28d8),
        //     address(0x34AF38Ec07708dBC01C5A814fc418D3840448fce)
        // );
        // console2.log("GameConsumer deployed at:", address(gameConsumer));

        // /// SeasonsTokenIdRegistry contract
        // SeasonsTokenIdRegistry seasonsTokenIdRegistry = new SeasonsTokenIdRegistry(address(_core));
        // console2.log("SeasonsTokenIdRegistry deployed at:", address(seasonsTokenIdRegistry));

        // /// Season contracts (Season 1)
        // ERC1155SeasonOne erc1155SeasonOne = new ERC1155SeasonOne(
        //     address(_core),
        //     address(0x16280Bb89C1d8812E9AA724D7E6cCA988be321C0),
        //     address(0x8c4B36F7ceEeE121b0723D31D92866736b067B75),
        //     address(seasonsTokenIdRegistry)
        // );
        // console2.log("ERC1155SeasonOne deployed at:", address(erc1155SeasonOne));

        // /// Grant the GUARDIAN role to the GUARDIAN_MULTISIG
        // _core.grantRole(Roles.GUARDIAN, address(0xc3c1D74048115316dCbd66baeDA8214D2CA83C35));
        
        // /// grant protocol Locker role
        // _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(0x16280Bb89C1d8812E9AA724D7E6cCA988be321C0));
        // _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(0x181EE014eA2fa80256F8E96a0f5Ef6147586F010));
        // _core.grantRole(Roles.LOCKER_PROTOCOL_ROLE, address(erc1155AutoGraphMinter));

        // /// grant protocol minter role
        // _core.grantRole(Roles.MINTER_PROTOCOL_ROLE, address(erc1155AutoGraphMinter));

        // /// grant registry operator role
        // _core.grantRole(Roles.REGISTRY_OPERATOR_PROTOCOL_ROLE, address(erc1155SeasonOne));

        // /// grant minter notary role
        // _core.grantRole(Roles.MINTER_NOTARY_PROTOCOL_ROLE, address(0x2526550D7c61559dF4f55fbcE69935c2d536F75E));

        // /// grant game consumer notary protocol role
        // _core.grantRole(Roles.GAME_CONSUMER_NOTARY_PROTOCOL_ROLE, address(0x2526550D7c61559dF4f55fbcE69935c2d536F75E));

        vm.stopBroadcast();

        /// @dev zip004

        /// @dev zip005

        /// @dev zip006

        /// @dev zip007

        /// @dev zip008

        /// @dev zip009

        /// @dev zip010

        /// @dev zip011

        /// @dev zip012

        /// @dev zip013

        /// @dev zip014

        /// @dev zip016

        /// @dev zip017

        /// @dev zip018

        /// @dev zip019
    }
}