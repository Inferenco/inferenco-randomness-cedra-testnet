# Live Randomness Testing Guide

This document details how to run the interactive Python demo scripts to test the `inferenco::game_examples` contract on the Cedra testnet.

## Prerequisites

1.  **Cedra CLI**: Must be installed and available in your PATH.
2.  **Testnet Profile**: You must have a configured `testnet` profile with a funded account.
    ```bash
    cedra init --profile testnet --network testnet
    cedra account fund-with-faucet --profile testnet
    ```
3.  **Python 3**: Required to run the scripts.

## The Scripts

All scripts are located in `scripts/demos/`. They allow you to verify different aspects of on-chain randomness.

| Script | Command | On-Chain Logic | Live Verification |
|--------|---------|----------------|-------------------|
| **Dice Roll** | `python3 scripts/demos/dice_roll.py` | `roll_dice(36)` | Visualizes a 2D6 roll side-by-side. Verifies generic RNG by efficiently generating two numbers from one call. Uses `DiceGame` resource state for instant verification. |
| **Coin Flip** | `python3 scripts/demos/coin_flip.py` | `roll_dice(2)` | Verifies low-range RNG (0-1). Uses same robust `DiceGame` resource check. |
| **Combat Sim** | `python3 scripts/demos/combat_sim.py` | `roll_dice(10000)` | Verifies composability. Uses a single call to derive both damage variance and critical hit chance. |
| **Loot Box** | `python3 scripts/demos/loot_box.py` | `open_loot_box(N)` | Verifies complex struct generation and event emission. *Note: Uses event fetching which may have latency (retries automatically).* |
| **Card Dealer** | `python3 scripts/demos/card_dealer.py` | `start_card_game` | Verifies permutation/shuffles. Reads `CardGame` resource for the player's initial hand. |

## How It Works (The "Live" Part)

The scripts use a shared driver (`scripts/demos/shared/random_provider.py`) that intelligently interacts with the blockchain:

1.  **Execution**: It constructs and runs a `cedra move run` command to execute the transaction on testnet.
    *   Flag: `--assume-yes` is used to bypass prompts.
    *   Address: Uses the deployed address `0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403`.
2.  **Verification**:
    *   **Resource Query (Fast)**: For Dice and Cards, it immediately queries the account's on-chain resources (`cedra account list`) to get the updated state. This confirms the transaction actually mutated the chain.
    *   **Event Fetching (Slower)**: For Loot Boxes (which don't store history on-chain), it fetches the transaction receipt via the REST API. *Note: This includes a retry loop to wait for indexing.*
3.  **Fallback**: If the CLI is missing, the network is down, or the transaction times out, the scripts automatically switch to **Simulation Mode** (using Python's `random`) to ensure the demo UI still works for testing.

## Running the Verification Suite

To run all tests in verifying order:

```bash
# 1. verify simple RNG
python3 scripts/demos/dice_roll.py

# 2. Verify binary outcomes
python3 scripts/demos/coin_flip.py

# 3. Verify complex game logic (Crit/Damage)
python3 scripts/demos/combat_sim.py

# 4. Verify stateful shuffles
python3 scripts/demos/card_dealer.py

# 5. Verify events (May take longer due to indexing)
python3 scripts/demos/loot_box.py
```
