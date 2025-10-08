# BatchSend

BatchSend is a simple, auditable Solidity utility for batch-sending ERC20 tokens to multiple recipients in a single transaction. The project is built with Foundry and vendors OpenZeppelin contracts.

# Getting Started

## Prerequisites

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```js
git clone https://github.com/nwachee/test-batchsend.git
cd test-batchsend
forge build
```

# Usage

## OpenZeppelin

[OpenZeppelin Contracts Docs](https://docs.openzeppelin.com/contracts/4.x/)
<br><br>
[OpenZeppelin GitHub Repo](https://github.com/OpenZeppelin/openzeppelin-contracts)
<br>

### Installing OpenZeppelin Contracts Package

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

## Start a local node

```
anvil
```

# Deployment

The deployment script deploys both MockToken and BatchSend and prints their addresses.

## Deployment to a testnet or mainnet

#### 1. **Setup environment variables**

Create a `.env` file in the root folder:

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_private_key_without_0x
ETHERSCAN_API_KEY=your_etherscan_api_key
ANVIL_RPC_URL=http://localhost:8545
```

**NOTE: FOR DEVELOPMENT, PLEASE USE A PRIVATE KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.**

#### 2. **Deploy**

```
forge script script/Deploy.s.sol:DeployScript --rpc-url "$ANVIL_RPC_URL" --broadcast -vvvv
```

After deployment, the script logs the deployed addresses for MockToken and BatchSend.

## Test

```
forge test
```

## Format

```
forge fmt
```

## Gas snapshots (optional)

```
forge snapshot
```
