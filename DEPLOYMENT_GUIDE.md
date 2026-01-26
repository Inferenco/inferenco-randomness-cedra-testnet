# Custom Randomness Module - Deployment Guide

## Overview

This guide details how to deploy the `inferenco_games` package to the Cedra testnet. This package provides a custom randomness module (`inferenco::random`) as a temporary alternative to native VRF, along with example game implementations.

## Directory Structure

Ensure your project looks like this:

```
inferenco-randomness/
├── Move.toml          # configured for CedraFramework
├── sources/
│   ├── inferenco_random.move
│   ├── game_examples.move
│   └── game_tests.move
├── LICENSE
└── .gitignore
```

## Prerequisites

1.  **Install Rust & Node.js**: Required for the Cedra CLI.
2.  **Install Cedra CLI**: Follow the [official guide](https://docs.cedra.network/getting-started/cli).
    ```bash
    # Verify installation
    cedra --version
    ```
3.  **Initialize CLI Profile**:
    ```bash
    cedra init --profile testnet --network testnet
    ```

## Compilation

The `Move.toml` is configured with `inferenco = "_"`, enabling you to inject your address at compile/runtime.

To compile the package using your profile (e.g., `default` or `testnet`):

```bash
# Replace '0xYourAddress' with your actual account address
cedra move compile --named-addresses inferenco=0xYourAddress
```

## Testing

Run the included test suite to verify functionality before deployment:

```bash
# Run tests using a dummy address (0x1) or your own
cedra move test --named-addresses inferenco=0x1
```

## Deployment

1.  **Fund your account**:
    ```bash
    cedra account fund-with-faucet --profile testnet
    ```

2.  **Publish the package**:
    This command compiles and publishes the contract to the Cedra testnet.

    ```bash
    cedra move publish --named-addresses inferenco=testnet --profile testnet
    ```
    *Note: `inferenco=testnet` assumes your profile account address will be the owner. You can also specify the raw address like `inferenco=0x123...`.*

3.  **Initialize Randomness**:
    **CRITICAL**: You must call `initialize` once for any account that will generate randomness.

    ```bash
    cedra move run \
      --function-id 'default::random::initialize' \
      --profile testnet
    ```
    *(Replace `default` with your actual published address if not using the profile name)*

## Verification

Check the deployment on the [Cedra Explorer](https://cedrascan.com) (or testnet equivalent) by searching for your account address. You should see the requested modules under the "Modules" tab.
