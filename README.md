# Decentralized Finance

This project showcases a Hardhat 3 Beta project using `mocha` for tests and the `ethers` library for Ethereum interactions.

## Project Overview

Making basic contracts for integrate with actual DeFi smart contract. For this we will need to use current standards and implementations.

We create a simple stablecoin, following the ERC20 standard and an oracle. Then we create a decentralized exchange that will allow us to exchange our stablecoin. Finally, we create the tests for this project.

## Usage

### Running Tests

To run all the tests in the project, execute the following command:

```shell
npm run test
```

### Make a deployment to localhost

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Sepolia.

To run the deployment to a local chain:

```shell
npm run deploy
```
