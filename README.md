# Pigeon-Envelop

## How to use?

### 1. install

Using `yarn install` command to install dependencies

### 2. compile

Using `yarn compile` command to compile pigeon envelope contract;

### 3. deploy

Config `tagAddress` and `tagClassAddress` in scripts/deploy.ts;

Using `yarn deploy` command to deploy pigeon-envelope contract to local chain or Using `yarn deploy_polygon` command to deploy pigeon-envelope contract to polygon;

Please don't forgot to config `POLYGON_URL` and `POLYGON_PRIVATE_KEY` args in hardhat.config.ts if you want to deploy to polygon.

### 4. test

Config `provider`, `wallet`, `walletOperator`, `walletUser` and `envelopeContractAddress` in src/envelope.ts;

Using `yarn start` command to run testcase.
