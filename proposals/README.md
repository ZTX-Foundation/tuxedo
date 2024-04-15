# Proposals

## How to use Proposals simulator

### Integration Tests

#### Step 1: Create a zip file
Create a proposal file similiar to below zip:

```solidity
contract zip009 is Proposal, TimelockProposal {
    string public name = "ZIP009";
    string public description = "ZTX CGv1.3 MaxSupply updates";

    struct TokenIDMaxSupplySettings {
        uint256 maxSupply;
        uint256 tokenId;
    }

    TokenIDMaxSupplySettings[] private wearableTokenIDMaxSupplySettings;

    function setAndConfirmWearableData() private {
        // Wearable data
        string memory wearableData = string(
            abi.encodePacked(vm.readFile("./proposals/zips/zip009.json"))
        );

        bytes memory parsedJson = vm.parseJson(wearableData);

        TokenIDMaxSupplySettings[] memory wearablesDecoded = abi.decode(
            parsedJson,
            (TokenIDMaxSupplySettings[])
        );

        for (uint256 i = 0; i < wearablesDecoded.length; i++) {
            wearableTokenIDMaxSupplySettings.push(
                TokenIDMaxSupplySettings(
                    wearablesDecoded[i].maxSupply,
                    wearablesDecoded[i].tokenId
                )
            );
        }

        // sanity checks
        assertEq(wearableTokenIDMaxSupplySettings.length, 2, "Invalid wearableTokenIDMaxSupplySettings length");

        uint maxSupplyTotal = 0;

        // sum numbers from requrements sheet
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            maxSupplyTotal += wearableTokenIDMaxSupplySettings[i].maxSupply;
        }

        assertEq(maxSupplyTotal, 100_420, "Invalid maxSupplyTotal");
    }

    function _beforeDeploy(Addresses, address deployer) internal override {
        setAndConfirmWearableData();
    }

    function _deploy(Addresses addresses, address) internal override {}

    function _afterDeploy(Addresses addresses, address) internal override {}

    function _afterDeployOnChain(Addresses, address deployer) internal virtual override {}

    function _aferDeployForTestingOnly(Addresses, address deployer) internal virtual override {}

    function _teardown(Addresses addresses, address deployer) internal override {}

    function _build(Addresses addresses, address) internal override {
        /// Wearable config
        address wearables = addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES");
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            _pushTimelockAction(
                wearables,
                abi.encodeWithSignature(
                    "setSupplyCap(uint256,uint256)",
                    wearableTokenIDMaxSupplySettings[i].tokenId,
                    wearableTokenIDMaxSupplySettings[i].maxSupply
                ),
                string(
                    abi.encodePacked(
                        "Set wearable tokenId ",
                        wearableTokenIDMaxSupplySettings[i].tokenId,
                        " to max supply ",
                        wearableTokenIDMaxSupplySettings[i].maxSupply
                    )
                )
            );
        }
    }

    function _run(Addresses addresses, address) internal override {
        this.setDebug(true);

        _simulateTimelockActions(
            addresses.getAddress("ADMIN_TIMELOCK_CONTROLLER"),
            addresses.getAddress("ADMIN_MULTISIG"),
            addresses.getAddress("ADMIN_MULTISIG")
        );
    }

    function _validate(Addresses addresses, address) internal override {
        ERC1155MaxSupplyMintable wearable = ERC1155MaxSupplyMintable(
            addresses.getAddress("ERC1155_MAX_SUPPLY_MINTABLE_WEARABLES")
        );

        /// Verfiy Wearable
        for (uint256 i = 0; i < wearableTokenIDMaxSupplySettings.length; i++) {
            uint256 tokenId = wearableTokenIDMaxSupplySettings[i].tokenId;
            uint256 maxSupply = wearableTokenIDMaxSupplySettings[i].maxSupply;
            uint256 currentSupply = wearable.totalSupply(tokenId);

            assertEq(wearable.maxTokenSupply(tokenId), maxSupply, "Invalid maxTokenSupply for tokenId");
            assertEq(wearable.getMintAmountLeft(tokenId), maxSupply - currentSupply, "Invalid getMintAmountLeft for tokenId");
        }
    }

    function _validateOnChain(Addresses, address deployer) internal virtual override {}

    function _validateForTestingOnly(Addresses, address deployer) internal virtual override {}
}
```

#### Step 2: Add the zip in TestProposals.sol and test

1. Set ENVIRONMENT as 'mainnet', 'qa', 'devnet', 'localnet' or any other environment against which we want to run the integration tests.

2. Update the address json file as required for the new zip.

3. Import new zip in TestProposals.

4. If zip is already executed on the network, add it in `if` block and now you can run integration tests. If zip is not executed on mainnet, replace zipTest with the new zip contract and run integration tests to test the zip. 'localnet' represents anvil test network and all the zips are simulated when running integration tests against it.
Run:
```bash
forge test --match-contract IntegrationTest
```

### Scripts

#### DeployProposal Script
This script is used to mainly deploy the latest zip to mainnet. It deploys new contracts and logs proposal calldata for admin timelock controller to execute.
Import the latest zip in `deployProposal` to new zip and run script to deploy new contracts and get calldata for admin timelock controller.

Run:
```bash
forge script script/deploy/DeployProposal.s.sol:DeployProposal \
    -vvvv \
    --rpc-url $RPC_URL \
    --broadcast
```
Remove --broadcast if you want to try locally first, without paying any gas.

#### DeployTestnet script
This script is used to bootstrap a tesnet environment. It deploys all the contracts and executes all the actions in zips, finally resulting in a new instance of the entire contract ecosystem on testnet.

1. Create a new address json file in addresses folder. For example if a QA network is needed to be bootstraped, create a `qa.json` file and add all required addresses to it. Required addresses are:

```json
[
    {
        "name": "WETH",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "TREASURY_WALLET_MULTISIG",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "ADMIN_MULTISIG",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "GUARDIAN_MULTISIG",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "AUTOGRAPH_MINTER_PAYMENT_RECIPIENT",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "GAME_CONSUMER_PAYMENT_RECIPIENT",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "REVENUE_WALLET_MULTISIG01",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "REVENUE_WALLET_MULTISIG02",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "AUTOGRAPH_SERVICE_KMS_WALLET",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "FINANCE_GUARDIAN_MULTISIG",
        "chainid": ,
        "addr": "",
        "isContract":
    },
    {
        "name": "DEPLOYER",
        "chainid": ,
        "addr": "",
        "isContract":
    }
]
```

2. Set ENVIRONMENT, this is same as the name of the address json file created above.

Run:
```bash
forge script script/deploy/DeployTestnet.s.sol:DeployTestnet \
    -vvvv \
    --rpc-url $ETH_RPC_URL \
    --broadcast \
    --private-key <KEY>
```
Remove --broadcast and --private-key if you want to try locally first, without paying any gas.
