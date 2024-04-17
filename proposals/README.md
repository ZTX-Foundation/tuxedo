# Proposals

## How to use Proposals simulator

### Integration Tests

#### Step 1: Create a zip file
Create a proposal file. For reference, there are previously executed zips in [zips folder](./zips)

#### Step 2: Add the zip in TestProposals.sol and test

1. Set ENVIRONMENT as 'mainnet', 'qa', 'devnet', 'localnet' or any other environment against which we want to run the integration tests.

2. Update the address json file as required for the new zip.

3. Import new zip in TestProposals.

4. If zip is already executed on the network, add it in `if` block and now you can run integration tests. If zip is not executed on mainnet, replace zipTest with the new zip contract and run integration tests to test the zip. 'localnet' represents anvil test network and all the zips are simulated when running integration tests against it.
Run:
```bash
ENVIRONMENT=mainnet npm run test:integration
```

### Scripts

#### DeployProposal Script
This script is used to mainly deploy the latest zip to mainnet. It deploys new contracts and logs proposal calldata for admin timelock controller to execute.
Import the latest zip in `deployProposal` to new zip and run script to deploy new contracts and get calldata for admin timelock controller.

Run:
```bash
deploy:testnet:broadcast
```
If you want to try locally first, without paying any gas, run:
```bash
deploy:testnet
```

#### DeployTestnet script
This script is used to bootstrap a tesnet environment. It deploys all the contracts and executes all the actions in zips, finally resulting in a new instance of the entire contract ecosystem on testnet.

1. Create a new address json file in addresses folder. For example if a QA network is needed to be bootstraped, create a `qa.json` file and add all required addresses to it. Example: [localnet.json](./Addresses/localnet.json)

2. Set ENVIRONMENT, this is same as the name of the address json file created above.

Run:
```bash
bootstrap:testnet:bootstrap
```

If you want to try locally first, without paying any gas, run:
```bash
bootstrap:testnet
```
