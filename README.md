<h2 align=center>Aztec Sequencer Node Guide</h2>

Aztec is building a decentralized, privacy-focused network and the sequencer node is a key part of it. Running a sequencer helps produce and propose blocks using regular consumer hardware. This guide will walk you through setting one up on the testnet.

**Note: There's no official confirmation of any rewards, airdrop, or incentives. This is purely for learning, contribution and being early in a cutting-edge privacy project.**

## 📋 Table of Contents

- [🚀 Quick Start (First Time Setup)](#-quick-start-first-time-setup)
- [🎯 Get Discord Apprentice Role](#-get-discord-apprentice-role)
- [🚀 Register as Validator](#-register-as-validator)
- [📋 Quick Reference Commands](#-quick-reference-commands)
- [📖 Detailed Guide](#-detailed-guide)
  - [Getting Apprentice Role on Discord](#getting-apprentice-role-on-discord)
  - [Validator Registration](#validator-registration-1)
  - [Environment Configuration](#environment-configuration)
  - [Script Overview](#script-overview)
  - [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start (First Time Setup)

> **Watch the [setup video](https://youtu.be/2mBIRmMPSEM?si=TG5MRwQyZ5XqcfLI) for a visual walkthrough**

### Prerequisites

**System Requirements:**

| Component      | Minimum Required          | Recommended               |
| -------------- | ------------------------- | ------------------------- |
| CPU            | 4-core Processor          | 8-core Processor          |
| RAM            | 6 GiB                     | 16 GiB                    |
| Storage        | 25 GB SSD                 | 1 TB SSD                  |
| Internet Speed | 25 Mbps Upload / Download | 25 Mbps Upload / Download |

> **Note:** You can start with minimum requirements, but upgrade to recommended specs for stable long-term operation.

**Before starting, you'll also need:**

- **RPC URLs**: Get Sepolia Ethereum RPC from [Alchemy](https://dashboard.alchemy.com/apps) or [Infura](https://developer.metamask.io/register)
- **Beacon URL**: Get Consensus URL from [Chainstack](https://chainstack.com/global-nodes)
- **Wallet**: Create a new EVM wallet and fund it with some Sepolia ETH (for validator registration)

### Installation Commands

Copy and paste these commands in order:

**1. Install dependencies and Aztec toolkit:**

```bash
[ -f "setup.sh" ] && rm setup.sh; curl -sSL -o setup.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

**2. Configure your node:**

```bash
[ -f "configure-node.sh" ] && rm configure-node.sh; curl -sSL -o configure-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/configure-node.sh && chmod +x configure-node.sh && ./configure-node.sh
```

**3. Start your node:**

```bash
[ -f "start-node.sh" ] && rm start-node.sh; curl -sSL -o start-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/start-node.sh && chmod +x start-node.sh && ./start-node.sh
```

That's it! Your node is now running. 🎉

**4. Register as validator (after ~20 min sync):**

Once your node is running, you can register as a validator to participate in block production:

> **⏱️ Important:** Wait approximately 20 minutes for your node to fully synchronize before registering as a validator. You can check the sync status by monitoring the logs.

```bash
[ -f "register-validator.sh" ] && rm register-validator.sh; curl -sSL -o register-validator.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/register-validator.sh && chmod +x register-validator.sh && ./register-validator.sh
```

> **Note:** There's a daily quota of 10 new validators per 24 hours. If you see a `ValidatorQuotaFilledUntil` error, you'll need to wait until the next quota period.

---

## 🎯 Get Discord Apprentice Role

After your node runs for 10-20 minutes:

**1. Get block number:**

```bash
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'
```

**2. Get proof (replace BLOCK_NUMBER with the number from step 1):**

```bash
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK_NUMBER","BLOCK_NUMBER"],"id":67}' http://localhost:8080 | jq -r ".result"
```

**3. Submit to Discord:**

- Join [Aztec Discord](https://discord.com/invite/aztec)
- Go to `#operators-start-here` channel
- Use command: `/operator start`
- Provide: wallet address, block number, and proof

---

## 🚀 Register as Validator

> **Warning:** Daily quota is 10 new validators per 24 hours. If you see `ValidatorQuotaFilledUntil` error, convert the Unix timestamp to know when to retry.

**Automated registration (recommended):**

```bash
[ -f "register-validator.sh" ] && rm register-validator.sh; curl -sSL -o register-validator.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/register-validator.sh && chmod +x register-validator.sh && ./register-validator.sh
```

---

## 📋 Quick Reference Commands

### Initial Setup

**Install dependencies and Aztec toolkit:**

```bash
[ -f "setup.sh" ] && rm setup.sh; curl -sSL -o setup.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

**Configure your node:**

```bash
[ -f "configure-node.sh" ] && rm configure-node.sh; curl -sSL -o configure-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/configure-node.sh && chmod +x configure-node.sh && ./configure-node.sh
```

**Start/Restart your node:**

```bash
[ -f "start-node.sh" ] && rm start-node.sh; curl -sSL -o start-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/start-node.sh && chmod +x start-node.sh && ./start-node.sh
```

### Node Management

**Check node logs:**

```bash
sudo docker logs -f --tail 100 $(docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)
```

**Update configuration:**

```bash
[ -f "update-env.sh" ] && rm update-env.sh; curl -sSL -o update-env.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/update-env.sh && chmod +x update-env.sh && ./update-env.sh
```

**Stop node:**

```bash
[ -f "stop-node.sh" ] && rm stop-node.sh; curl -sSL -o stop-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/stop-node.sh && chmod +x stop-node.sh && ./stop-node.sh
```

### Validator Registration

**Register as validator:**

```bash
[ -f "register-validator.sh" ] && rm register-validator.sh; curl -sSL -o register-validator.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/register-validator.sh && chmod +x register-validator.sh && ./register-validator.sh
```

### Discord Apprentice Role

**Get block number:**

```bash
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'
```

**Get proof (replace BLOCK_NUMBER):**

```bash
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK_NUMBER","BLOCK_NUMBER"],"id":67}' http://localhost:8080 | jq -r ".result"
```

---

## 📖 Detailed Guide

### Getting Apprentice Role on Discord

After your node runs for 10-20 minutes:

1. **Get block number:**

   ```bash
   curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'
   ```

2. **Get proof** (replace `BLOCK_NUMBER`):

   ```bash
   curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK_NUMBER","BLOCK_NUMBER"],"id":67}' http://localhost:8080 | jq -r ".result"
   ```

3. **Submit to Discord:**
   - Join [Aztec Discord](https://discord.com/invite/aztec)
   - Go to `#operators-start-here` channel
   - Use command: `/operator start`
   - Provide: wallet address, block number, and proof

### Validator Registration

> **Warning:** Daily quota is 10 new validators per 24 hours. If you see `ValidatorQuotaFilledUntil` error, convert the Unix timestamp to know when to retry.

**Option 1: Automated (Recommended)**

```bash
./register-validator.sh
```

**Option 2: Manual**
Replace the environment variables with actual values:

```bash
aztec add-l1-validator \
  --l1-rpc-urls ETHEREUM_HOSTS \
  --private-key VALIDATOR_PRIVATE_KEY \
  --attester COINBASE \
  --proposer-eoa COINBASE \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```

### Environment Configuration

The setup creates a `.env` file with your configuration:

```bash
P2P_IP="your.server.ip"
ETHEREUM_HOSTS="https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
L1_CONSENSUS_HOST_URLS="https://nd-123-456-789.p2pify.com/YOUR_API_KEY"
VALIDATOR_PRIVATE_KEY="0x1234567890abcdef..."
COINBASE="0xYourWalletAddress"
```

**Configuration Features:**

- **First run**: Prompts for all values and saves to `.env`
- **Subsequent runs**: Loads existing values, only prompts for missing ones
- **Selective updates**: Use `update-env.sh` to change specific variables
- **Manual setup**: Create `.env` file manually to skip prompts

### Script Overview

| Script                  | Purpose                                                     |
| ----------------------- | ----------------------------------------------------------- |
| `setup.sh`              | Installs Docker, dependencies, and Aztec toolkit (run once) |
| `configure-node.sh`     | Sets up environment variables (creates `.env` file)         |
| `start-node.sh`         | Starts the node (requires `.env` file)                      |
| `register-validator.sh` | Registers as validator using `.env` configuration           |
| `update-env.sh`         | Updates specific environment variables                      |
| `stop-node.sh`          | Stops node, containers, and clears ports                    |

### Troubleshooting

**RPC Rate Limits:**
If using free RPC services and hitting limits, either upgrade to premium or change endpoints.

**Node Issues:**

- Check logs: `sudo docker logs -f --tail 100 $(docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)`
- Restart node: Use the restart command from Quick Reference
- Check system resources meet minimum requirements
