# ERC-8004 Glossary

A comprehensive glossary of terms used in the ERC-8004 standard and its ecosystem.

---

### A2A (Agent-to-Agent)

Google's Agent-to-Agent protocol for direct inter-agent communication. Agents register their A2A endpoint in the `services` array of their registration JSON.

### Active

A boolean field in the registration JSON indicating whether an agent is currently operational and accepting requests.

### Agent

An autonomous AI service registered on-chain through the ERC-8004 Identity Registry. Each agent is represented by an ERC-721 NFT.

### Agent ID

A unique sequential `uint256` identifier assigned to each agent upon registration. Agent IDs start from 1 and increment with each new registration.

### Agent Registry

The Identity Registry smart contract where agents are registered. Also referred to as the Identity Registry. Deployed at addresses prefixed with `0x8004A`.

### Agent URI

A URL pointing to a JSON document that describes an agent's metadata, services, capabilities, and configuration. Set during registration or updated via `setAgentURI`.

### Agent Wallet

An external wallet address linked to an agent via `setAgentWallet`. Requires an EIP-712 signature from the wallet to prove consent. Used for receiving payments or signing transactions on behalf of the agent.

### appendResponse

A function in the Reputation Registry that allows agent owners to respond to feedback left by clients.

### Arweave

A permanent, decentralized storage network. Can be used to host agent registration JSON files with guaranteed persistence.

### CAIP-10

Chain Agnostic Improvement Proposal 10 -- a standard format for identifying accounts across blockchains. Used in ERC-8004 for cross-chain agent identification: `eip155:<chainId>:<address>`.

### Capabilities

A free-form array of strings in the registration JSON that declares what an agent can do (e.g., `"text-generation"`, `"code-review"`, `"translation"`).

### Client

An address that interacts with an agent and may leave feedback. Feedback is indexed by `(agentId, clientAddress, feedbackIndex)`.

### CREATE2

An EVM opcode that deploys contracts to deterministic addresses based on the deployer, salt, and bytecode. Used to deploy ERC-8004 contracts at the same vanity addresses across all chains.

### Crypto-Economic Trust

A trust mechanism where validators stake tokens as collateral for honest evaluation. Dishonest validators risk losing their stake.

### Decimals (Value Decimals)

A `uint8` field that specifies how many decimal places a feedback value has. For example, a value of `9950` with `decimals=2` represents `99.50%`.

### DID (Decentralized Identifier)

A W3C standard for decentralized, self-sovereign identity. Agents can register a DID endpoint in their services array.

### EIP-712

An Ethereum standard for typed structured data signing. Used in ERC-8004's `setAgentWallet` function to require a signature from the new wallet proving consent.

### ENS (Ethereum Name Service)

A decentralized naming system on Ethereum that maps human-readable names (e.g., `myagent.eth`) to addresses. Agents can register an ENS endpoint in their services array.

### ERC-721

The Ethereum standard for non-fungible tokens (NFTs). Each registered ERC-8004 agent is an ERC-721 NFT owned by the registrant.

### ERC-8004

The Ethereum standard for Trustless Agent Services. Defines three on-chain registries (Identity, Reputation, Validation) for registering, discovering, and evaluating AI agents on EVM-compatible blockchains.

### ERC-8172

A companion standard to ERC-8004 that introduces on-chain agent attachments -- structured data such as documents, proofs, and certificates that can be attached to an agent's on-chain identity.

### Facilitator

An intermediary agent or service that helps users discover, filter, and route requests to suitable agents based on reputation, capabilities, and other criteria.

### Feedback

An on-chain record submitted through the Reputation Registry evaluating an agent's performance. Includes a value, decimal precision, tags, endpoint reference, and optional off-chain URI.

### Feedback Hash

A `bytes32` hash of off-chain feedback data, stored on-chain for integrity verification.

### Feedback Index

A sequential `uint64` identifier for each piece of feedback from a specific client to a specific agent. Used together with `agentId` and `clientAddress` to uniquely identify feedback entries.

### Feedback URI

A URL pointing to detailed off-chain feedback data (hosted on IPFS, Arweave, or HTTPS).

### getClients

A function in the Reputation Registry that returns all addresses that have given feedback to a specific agent.

### getMetadata

A function in the Identity Registry that retrieves arbitrary metadata stored for an agent by key.

### getSummary

A function available in both the Reputation and Validation Registries. Aggregates feedback or validation results, optionally filtered by client/validator addresses and tags.

### getValidationStatus

A function in the Validation Registry that returns the current state of a validation request, including the validator, response, and last update timestamp.

### giveFeedback

The primary function in the Reputation Registry for submitting feedback about an agent. Accepts value, decimals, tags, endpoint, URI, and hash parameters.

### Identity Registry

The first of the three ERC-8004 registries. Manages agent registration as ERC-721 NFTs, URI storage, metadata, and wallet linking. Deployed at addresses prefixed with `0x8004A`.

### Indexed Tag

The `tag1` field in feedback, which is indexed on-chain (`string indexed indexedTag1` in the event) for efficient filtering and querying.

### IPFS (InterPlanetary File System)

A decentralized, content-addressed file storage network. Commonly used to host agent registration JSON and feedback data.

### MCP (Model Context Protocol)

Anthropic's protocol for sharing tools, resources, and context with LLM-based agents. Agents register their MCP server endpoint in the services array.

### Metadata

Arbitrary key-value data stored on-chain for an agent via `setMetadata`. Keys are strings and values are raw bytes, allowing flexible use cases (model hashes, version info, configuration).

### NFT Owner

The Ethereum address that owns an agent's ERC-721 token. Only the NFT owner can modify the agent's URI, metadata, wallet, and respond to feedback.

### OASF (Open Agent Service Format)

An open standard for describing agent capabilities in a structured format. Agents can register an OASF descriptor endpoint in their services array.

### ownerOf

An ERC-721 function that returns the owner address of a specific agent NFT.

### readAllFeedback

A function in the Reputation Registry that returns all feedback for an agent, optionally filtered by client addresses, tags, and revocation status.

### readFeedback

A function in the Reputation Registry that reads a single feedback entry identified by `(agentId, clientAddress, feedbackIndex)`.

### register

The function in the Identity Registry that creates a new agent. Available in two forms: `register(string agentURI)` with a URI, or `register()` without one.

### Registration JSON

The JSON document pointed to by an agent's URI. Contains the agent's name, description, image, services, capabilities, trust mechanisms, and optional enriched metadata.

### Reputation Registry

The second of the three ERC-8004 registries. Manages on-chain feedback, ratings, and reputation summaries. Deployed at addresses prefixed with `0x8004B`.

### Request Hash

A `bytes32` identifier for a validation request in the Validation Registry. Used to link validation responses back to their original requests.

### Response (Validation)

A `uint8` value (0-255) submitted by a validator as their assessment of an agent in the Validation Registry.

### revokeFeedback

A function in the Reputation Registry that allows the original feedback author to revoke their feedback. Revoked feedback is marked but not deleted, and is excluded from summaries by default.

### Scanner

A service that continuously monitors registered agents for availability, performance, and correctness. Scanners submit their findings as feedback through the Reputation Registry.

### Self-Feedback Prevention

A security mechanism in the Reputation Registry that prevents an agent's NFT owner from giving feedback to their own agent.

### setAgentURI

A function in the Identity Registry that updates an agent's URI. Can only be called by the NFT owner.

### setAgentWallet

A function in the Identity Registry that links an external wallet to an agent. Requires an EIP-712 signature from the new wallet to prove consent.

### setMetadata

A function in the Identity Registry that stores arbitrary bytes indexed by a string key for an agent. Owner-only.

### Tag

A string label attached to feedback or validation entries for categorization. `tag1` is indexed on-chain for efficient filtering; `tag2` provides secondary categorization.

### TEE (Trusted Execution Environment)

A hardware-based secure enclave (e.g., Intel SGX, ARM TrustZone) that provides verifiable code integrity. Agents running in TEEs can provide attestation proofs.

### Token URI

The `tokenURI` function inherited from ERC-721 that returns the URI associated with an agent's NFT. In ERC-8004, this points to the agent's registration JSON.

### Validation Registry

The third of the three ERC-8004 registries. Manages third-party validation requests and responses. Deployed at addresses prefixed with `0x8004C`.

### validationRequest

A function in the Validation Registry that creates a request for a specific validator to evaluate a specific agent.

### validationResponse

A function in the Validation Registry that allows a designated validator to submit their assessment of an agent.

### Validator

An address designated to evaluate an agent's capabilities or output quality. Validators respond to validation requests through the Validation Registry.

### Value

An `int128` field in feedback representing the feedback score. Supports both positive and negative values, with precision controlled by `valueDecimals`.

### Vanity Address

A contract address with a recognizable pattern (e.g., `0x8004A...`, `0x8004B...`, `0x8004C...`). Achieved through CREATE2 deployment with specific salts.

### Web of Trust

A trust model where reputation is filtered by specific client addresses. By passing trusted addresses to `getSummary`, consumers can get reputation scores based only on feedback from sources they trust.

### x402

An HTTP-based micropayment protocol. Agents declare `x402Support: true` in their registration JSON to indicate they accept pay-per-request payments via HTTP 402 responses.

### zkML (Zero-Knowledge Machine Learning)

A validation method where a validator produces a zero-knowledge proof that a specific model produced a specific output, without revealing model weights or proprietary information.

---

*For the complete specification, see [specification.md](./specification.md).*
