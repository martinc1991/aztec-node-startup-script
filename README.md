<h2 align=center>Aztec Sequencer Node Guide</h2>

Aztec is building a decentralized, privacy-focused network and the sequencer node is a key part of it. Running a sequencer helps produce and propose blocks using regular consumer hardware. This guide will walk you through setting one up on the testnet.

**Note : There’s no official confirmation of any rewards, airdrop, or incentives. This is purely for learning, contribution and being early in a cutting-edge privacy project.**

## 💻 System Requirements

| Component      | Specification             |
| -------------- | ------------------------- |
| CPU            | 8-core Processor          |
| RAM            | 16 GiB                    |
| Storage        | 1 TB SSD                  |
| Internet Speed | 25 Mbps Upload / Download |

> [!Note] > **You can start running this node on a `4-core CPU`, `6 GB of RAM` and `25 GB of storage`. However, as uptime increases, it's important to meet the recommended system requirements—otherwise, your node may eventually crash.**

## 🌐 Rent VPS

> [!Note] > **Renting VPS is not necessarily needed if your main goal is to take `Apprentice` role on Aztec Discord, You can run this node on WSL for 30 mins to get that role**

- Visit : [PQ Hosting](https://pq.hosting/?from=622403&lang=en) (high price but crypto payment supported) or [contabo](https://contabo.com/en) or [hetzner](https://www.hetzner.com/cloud) to rent a VPS
  > [!Tip] > **If you don't know what a VPS is or how to buy one, you should watch [this video](https://youtu.be/vNBlRMnHggA?si=G1huqYU3ylCGoTQE) on my YouTube channel.**

## ⚙️ Prerequisites

- You can use [Alchemy](https://dashboard.alchemy.com/apps) or [Infura](https://developer.metamask.io/register) to get Sepolia Ethereum RPC.
- You can use [Chainstack](https://chainstack.com/global-nodes) to get the Consensus URL (Beacon RPC URL).
- Create a new evm wallet and fund it with at least 2.5 Sepolia ETH if you want to register as Validator.

> [!IMPORTANT] > **If you're using the free version and reach the maximum request limit on either the Sepolia Ethereum RPC or the Sepolia Consensus (Beacon RPC) URL, you'll need to either upgrade to a premium plan or change the RPC endpoint each time you hit the limit.**

## 📥 Installation

> [!Tip] > **You can watch this [video](https://youtu.be/2mBIRmMPSEM?si=TG5MRwQyZ5XqcfLI) to learn how to set up aztec sequencer node very easily.**

### Option 1: Quick Setup (Original Method)

- Install `curl` and `wget` first

```bash
(command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1) || sudo apt-get update; command -v curl >/dev/null 2>&1 || sudo apt-get install -y curl; command -v wget >/dev/null 2>&1 || sudo apt-get install -y wget
```

- Execute either of the following commands to run your Aztec node

```
[ -f "aztec.sh" ] && rm aztec.sh; curl -sSL -o aztec.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/aztec.sh && chmod +x aztec.sh && ./aztec.sh
```

or

```
[ -f "aztec.sh" ] && rm aztec.sh; wget -q -O aztec.sh https://raw.githubusercontent.com/martinc1991/aztec-sequencer-node/main/aztec.sh && chmod +x aztec.sh && ./aztec.sh
```

### Option 2: Modular Setup (Recommended)

This approach splits the installation into two steps for better control and reusability:

**Step 1: Download and run setup (one-time installation):**

```bash
[ -f "setup.sh" ] && rm setup.sh; curl -sSL -o setup.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

**Step 2: Download and run node configuration:**

```bash
[ -f "configure-node.sh" ] && rm configure-node.sh; curl -sSL -o configure-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/configure-node.sh && chmod +x configure-node.sh && ./configure-node.sh
```

**Step 3 (Optional): Start node directly (if you already have .env configured):**

```bash
[ -f "start-node.sh" ] && rm start-node.sh; curl -sSL -o start-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/start-node.sh && chmod +x start-node.sh && ./start-node.sh
```

**Update environment configuration:**

```bash
[ -f "update-env.sh" ] && rm update-env.sh; curl -sSL -o update-env.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/update-env.sh && chmod +x update-env.sh && ./update-env.sh
```

**Register as validator (requires .env configuration):**

```bash
[ -f "register-validator.sh" ] && rm register-validator.sh; curl -sSL -o register-validator.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/register-validator.sh && chmod +x register-validator.sh && ./register-validator.sh
```

**Stop the node:**

```bash
[ -f "stop-node.sh" ] && rm stop-node.sh; curl -sSL -o stop-node.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/stop-node.sh && chmod +x stop-node.sh && ./stop-node.sh
```

#### 🔧 Environment Configuration

The modular setup supports flexible environment file configuration:

- **First run**: `configure-node.sh` will prompt for all required values and save them to `.env`
- **Subsequent runs**: `configure-node.sh` will load existing values from `.env` and only prompt for missing ones
- **Selective updates**: `update-env.sh` allows you to update specific variables while keeping others unchanged
- **Manual configuration**: Create a `.env` file with your values to skip prompts entirely
- **Direct start**: Use `start-node.sh` when you already have a configured `.env` file

Example `.env` file:

```bash
P2P_IP="your.server.ip"
ETHEREUM_HOSTS="https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
L1_CONSENSUS_HOST_URLS="https://nd-123-456-789.p2pify.com/YOUR_API_KEY"
VALIDATOR_PRIVATE_KEY="0x1234567890abcdef..."
COINBASE="0xYourWalletAddress"
```

#### 📋 Script Overview

- **`setup.sh`**: Installs Docker, dependencies, and Aztec toolkit (run once)
- **`configure-node.sh`**: Configures environment variables (creates `.env` file)
- **`start-node.sh`**: Starts the node directly (requires existing `.env` file)
- **`register-validator.sh`**: Registers as validator using environment variables from `.env` file
- **`update-env.sh`**: Updates existing environment variables selectively
- **`stop-node.sh`**: Stops the node, containers, and clears ports

## ⚡Commands

- You can use this command to check logs of your node

```
sudo docker logs -f --tail 100 $(docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)
```

- You can stop this node using this command

```
sudo docker stop $(docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)
```

## 🧩 Post-Installation

> [!Note] > **After running node, you should wait at least 10 to 20 mins before your run these commands**

- Use this command to get `block-number`

```
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'
```

- After running this code, you will get a block number like this : 66666

- Use that block number in the places of `block-number` in the below command to get `proof`

![Screenshot 2025-05-02 120017](https://github.com/user-attachments/assets/ed5ba08e-a1a9-48bc-8518-b23211ac7588)

```
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["block-number","block-number"],"id":67}' http://localhost:8080 | jq -r ".result"
```

- Now navigate to `operators | start-here` channel in [Aztec Discord Server](https://discord.com/invite/aztec)
- Use the following command to get `Apprentice` role

```
/operator start
```

- It will ask the `address` , `block-number` and `proof` , Enter all of them one by one and you will get `Apprentice` instantly

## 🚀 Register as Validator

> [!WARNING]
> You may see an error like `ValidatorQuotaFilledUntil` when trying to register as a validator, which means the daily quota has been reached—convert the provided Unix timestamp to local time to know when you can try again to register as Validator.

### Option 1: Automated Registration (Recommended)

If you have already configured your environment using `configure-node.sh`, you can use the automated registration script:

```bash
./register-validator.sh
```

This script will:

- Load your configuration from the `.env` file
- Verify all required environment variables are present
- Display the configuration that will be used
- Ask for confirmation before proceeding
- Execute the registration command automatically

### Option 2: Manual Registration

- Replace `SEPOLIA-RPC-URL` , `YOUR-PRIVATE-KEY` , `YOUR-VALIDATOR-ADDRESS` with actual value and then execute this command

```
aztec add-l1-validator \
  --l1-rpc-urls SEPOLIA-RPC-URL \
  --private-key YOUR-PRIVATE-KEY \
  --attester YOUR-VALIDATOR-ADDRESS \
  --proposer-eoa YOUR-VALIDATOR-ADDRESS \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```
