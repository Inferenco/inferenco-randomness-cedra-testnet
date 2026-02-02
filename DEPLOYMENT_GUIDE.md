# Custom Randomness Module - Deployment Guide

## Overview

This guide details how to deploy the `inferenco_games` package to the Cedra testnet. This package provides a custom randomness module (`inferenco::randomness`) as a drop-in replacement for native randomness when VRF is unavailable.

## Directory Structure

```
inferenco-randomness/
├── Move.toml
├── sources/
│   └── inferenco_random.move
├── LICENSE
└── .gitignore
```

## Prerequisites

1.  **Install Rust & Node.js**: Required for the Cedra CLI.
2.  **Install Cedra CLI**: Follow the [official guide](https://docs.cedra.network/getting-started/cli).
    ```bash
    cedra --version
    ```
3.  **Initialize CLI Profile**:
    ```bash
    cedra init --profile testnet --network testnet
    ```

## Compilation

The `Move.toml` is configured with `inferenco = "_"`, enabling you to inject your address at compile/runtime.

```bash
cedra move compile --named-addresses inferenco=0xYourAddress
```

## Testing

Run the included test suite to verify functionality before deployment:

```bash
cedra move test --named-addresses inferenco=0x1
```

## Deployment

1.  **Fund your account**:
    ```bash
    cedra account fund-with-faucet --profile testnet
    ```

2.  **Publish the package**:
    ```bash
    cedra move publish --named-addresses inferenco=testnet --profile testnet
    ```

3.  **Initialize Randomness**:
    **CRITICAL**: Call `initialize` once after deployment. This must be called by the module deployer (`@inferenco`).

    ```bash
    cedra move run \
      --function-id 'YOUR_ADDRESS::randomness::initialize' \
      --profile testnet
    ```

## Verification

Check the deployment on the [Cedra Explorer](https://cedrascan.com) by searching for your account address.

## Deployed Addresses (Testnet)

| Contract | Address | Transaction |
|----------|---------|-------------|
| **Inferenco Randomness** | `0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403` | [`0xaa9d...`](https://cedrascan.com/txn/0xaa9d5d306891cbb0e525fe1e53f24284405f15480ea5ee508840b42609686d55?network=testnet) |
| **Initialization** | N/A | [`0xf882...`](https://cedrascan.com/txn/0xf882cd20bcd38217b69686f976bfec63ed3f94c9ccc10ffea877a0f114481c9a?network=testnet) |
