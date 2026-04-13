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

## Local node and state management

Foundry updates occasionally change the format of Anvil state files. To avoid `--load-state` errors after upgrading Foundry, always regenerate your state file with your current version rather than relying on a committed one.

### Step 1 — Start Anvil with dump-state

```bash
anvil --dump-state batchsend.json
```

> Anvil will automatically write the state to `batchsend.json` when you stop it with `Ctrl+C`.

### Step 2 — Deploy contracts

In a second terminal:

```bash
source .env
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url "$ANVIL_RPC_URL" \
  --broadcast \
  -vvvv
```

### Step 3 — Stop Anvil to save state

Press `Ctrl+C` in the Anvil terminal. The state file will be written on exit:

```
State saved to: batchsend.json
```

### Step 4 — Load state (next time)

Restart Anvil with the saved state:

```bash
anvil --load-state batchsend.json
```

Your contracts will be available at the same addresses without redeploying.

> **If you upgrade Foundry and `--load-state` breaks:** just repeat Steps 1–3 to regenerate `deployed-state.json` with your new version. The deployed addresses will be the same as long as you use the same private key and deploy order.

## Local Addresses (Anvil default)

These addresses are deterministic when deploying with Anvil's default account (`0xf39F...92266`):

| Contract  | Address                                        |
|-----------|------------------------------------------------|
| BatchSend | `0x5FbDB2315678afecb367f032d93F642f64180aa3`   |
| MockToken | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`   |

> The deployer wallet (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`) starts with **1,000 MTK** and `BatchSend` is pre-approved to spend it.

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

## Setup environment variables

Create a `.env` file in the root folder:

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=0xyour_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
ANVIL_RPC_URL=http://localhost:8545
```

> **NOTE: FOR DEVELOPMENT, PLEASE USE A PRIVATE KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.**

## Deployment to Sepolia

#### 1. Get Sepolia ETH

Use a faucet like [sepoliafaucet.com](https://sepoliafaucet.com) to fund your wallet.

#### 2. Deploy and verify

```bash
source .env
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

## Sepolia Addresses

| Contract  | Address                                        |
|-----------|------------------------------------------------|
| BatchSend | `0x03d9096C194dC2C0EEfaa790d75C4cD79530618C`   |
| MockToken | `0x50241E0A892cE02a3766a76974120eb023BD0f30`   |

Both contracts are verified on [Sepolia Etherscan](https://sepolia.etherscan.io).

## Supported Tokens on Sepolia

| Token     | Address                                       | Decimals | Faucet |
|-----------|-----------------------------------------------|----------|--------|
| USDC      | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | 6        | [faucet.circle.com](https://faucet.circle.com) |
| MockToken | `0x50241E0A892cE02a3766a76974120eb023BD0f30` | 18       | Minted on deploy |

> **Note:** Amounts must be entered in wei. For USDC (6 decimals), `1000000` = 1 USDC. For MockToken (18 decimals), `1000000000000000000` = 1 MTK.

## Connecting to the frontend

If you're using the [BatchSend frontend](https://github.com/nwachee/batchsend):

1. Copy the token address you want to use and paste it into the **Token Address** field on the app.
2. Confirm the chain entry in `src/constants/index.ts` matches your deployed `BatchSend` address.
3. Make sure your wallet (e.g. MetaMask) is connected to the correct network.

## Testing

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