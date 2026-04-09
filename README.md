# BatchSend

BatchSend is a gas-efficient Solidity utility for distributing ERC20 tokens to multiple recipients in a single on-chain transaction — no loops on the frontend, no repeated approvals.

Built with Foundry and OpenZeppelin, it includes a `MockToken` for local testing, a deploy script that works against both Anvil and live testnets, and a saved Anvil state file so you can spin up a pre-deployed environment instantly.

# Getting Started

## Prerequisites

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```bash
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

```bash
anvil
```

## Load pre-deployed state

To skip redeploying every time, load the included state snapshot:

```bash
anvil --load-state deployed-state.json
```

This gives you a ready-to-use Anvil instance with `BatchSend` and `MockToken` already deployed at the addresses below.

## Local Addresses (Anvil default)

These addresses are deterministic when deploying with Anvil's default account (`0xf39F...92266`):

| Contract  | Address                                        |
|-----------|------------------------------------------------|
| BatchSend | `0x5FbDB2315678afecb367f032d93F642f64180aa3`   |
| MockToken | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`   |

> The deployer wallet (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`) starts with **1,000,000 MTK** and `BatchSend` is pre-approved to spend it.

To verify balances at any time:

```bash
# Check MTK balance (returns wei)
cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
  "balanceOf(address)(uint256)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://127.0.0.1:8545

# Human-readable
cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
  "balanceOf(address)(uint256)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://127.0.0.1:8545 | xargs cast to-unit - ether
```

# Deployment

The deployment script deploys both `BatchSend` and `MockToken` (in that order) and prints their addresses.

## Local deployment

#### 1. Setup environment variables

Create a `.env` file in the root folder:

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_private_key_without_0x
ETHERSCAN_API_KEY=your_etherscan_api_key
ANVIL_RPC_URL=http://localhost:8545
```

> **NOTE: FOR DEVELOPMENT, PLEASE USE A PRIVATE KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.**

#### 2. Deploy

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url "$ANVIL_RPC_URL" --broadcast -vvvv
```

After deployment, the script logs the deployed addresses:

```
BatchSend deployed to: 0x...
MockToken deployed to: 0x...
```

#### 3. Save Anvil state (optional but recommended)

After deploying, dump the current state so you can reload it later without redeploying:

```bash
cast rpc anvil_dumpState > deployed-state.json
```

## Connecting to the frontend

If you're using the [BatchSend frontend](https://github.com/nwachee/batchsend):

1. Copy the `MockToken` address from the deploy output and paste it into the **Token Address** field on the app.
2. Confirm the `31337` entry in `src/constants/index.ts` matches your deployed `BatchSend` address.
3. Make sure your wallet (e.g. MetaMask) is connected to `localhost:8545` on chain ID `31337`.

## Deployment to a testnet

Use the `SEPOLIA_RPC_URL` from your `.env`:

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url "$SEPOLIA_RPC_URL" --broadcast --verify -vvvv
```

# Testing

```bash
forge test
```

## Format

```bash
forge fmt
```

## Gas snapshots (optional)

```bash
forge snapshot
```