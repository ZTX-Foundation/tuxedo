# How to run a deployment

## Prepare

1. Update: `script/deploy/[EnvVar]/DeployIncrementalSystem.s.sol` with the next zip number to deploy
2. Update: `script/deploy/[EnvVar]/ValidateDeployment.s.sol` with the same zip number to deploy

## Deploy (TestNets)

1. Run: `npm run deploy:[EnvVar]:dryrun` to confirm everything will run ok
2. Run: `npm run deploy:[EnvVar]:boardcast` deploy and boardcast onchain
3. Update `Addresses.sol`
3. Run: `npm run deploy:[EnvVar]:validate` validate everything has worked onchain (Optional step)  

## Deploy (MainNet)

1. Run: `npm run deploy:mainnet:dryrun` to confirm everything will run ok
2. Run: `npm run deploy:mainnet:boardcast:verified` deploy, boardcast onchain and verify contracts on mainnet
3. Run: `npm run deploy:[EnvVar]:validate` validate everything has worked onchain (Optional step)  
