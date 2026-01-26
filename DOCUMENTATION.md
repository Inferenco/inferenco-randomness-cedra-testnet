# Inferenco Randomness Module - Documentation

## Introduction

The `inferenco::random` module provides pseudorandom number generation (PRNG) for the Cedra network. It is designed for game prototypes, non-financial randomization, and educational purposes.

> **⚠️ Security Warning**: This module uses on-chain entropy (timestamp, transaction hash). It is predictable by validators and should **NOT** be used for high-stakes financial applications.

## Usage Guidelines & Security

### When to Use This Module
*   ✅ **Low-stakes games and testing**: Prototyping game mechanics where perfect randomness isn't critical.
*   ✅ **Non-financial randomness**: Loot drops, matchmaking brackets, cosmetic generation.
*   ✅ **Development and prototyping**: Building and testing dApps on testnet before mainnet VRF is live.
*   ✅ **Educational purposes**: Learning Move and randomness concepts.

### When NOT to Use This Module
*   ❌ **High-value financial applications**: Lotteries, casinos, or defi protocols with significant funds.
*   ❌ **Large-sum gambling/betting**: Where minor predictability could lead to major loss of funds.
*   ❌ **Critical randomness**: Any system where the integrity of the randomness is the sole security guarantee.

## Integration

### 1. Add Dependency

Add the package to your `Move.toml`. If you deployed it yourself, reference it by local path or git (if hosted). For development, you can include the source files directly.

```toml
[dependencies]
CedraFramework = { git = "https://github.com/cedra-labs/cedra-framework.git", rev = "mainnet" }
# InferencoGames = { local = "../inferenco-randomness" } 
```

### 2. Basic Usage

Import the module and use the helper functions.

```move
module my_game::dice {
    use inferenco::random;
    use std::signer;

    entry fun roll(player: &signer) {
        let player_addr = signer::address_of(player);

        // 1. Initialize (idempotent, harmless if already done)
        if (!random::is_initialized(player_addr)) {
            random::initialize(player);
        };

        // 2. Generate Number (1 to 6)
        let result = random::dice_roll(player_addr, 6);
    }
}
```

## API Reference

### Initialization
*   `initialize(account: &signer)`: Sets up the `RandomnessCounter` resource for the account. Required before calling any random functions.

### Integer Generation
*   `u8_integer(caller: address): u8`
*   `u64_integer(caller: address): u64`
*   `u256_integer(caller: address): u256`
    *Returns a random integer across the full range of the type.*

### Ranges
*   `u64_range(caller: address, min: u64, max: u64): u64`
    *Returns a value where `min <= value < max`.*

### Game Helpers
*   `dice_roll(caller: address, sides: u64): u64`
    *Returns `1` to `sides` (inclusive).*
*   `coin_flip(caller: address): bool`
    *Returns `true` or `false`.*
*   `boolean(caller: address, probability: u8): bool`
    *Returns true with `probability` percent chance (0-100).*
*   `weighted_choice(caller: address, weights: &vector<u64>): u64`
    *Returns an index from `weights` based on their relative values.*

### Utilities
*   `shuffle<T>(caller: address, vec: &mut vector<T>)`
    *Shuffles a vector in-place.*
*   `pick<T>(caller: address, vec: &vector<T>): T`
    *Returns a random element from the vector.*

## Migration to Native Randomness

When Cedra releases native VRF support, you should migrate:

1.  Replace `inferenco::random` imports with `cedra_framework::randomness`.
2.  Remove `initialize` calls.
3.  Remove the `caller` address argument from function calls (native randomness checks the sender automatically or doesn't require it).

## Troubleshooting

**Error: `E_NOT_INITIALIZED` (code 2)**
*   **Cause**: You called a random function without initializing the account first.
*   **Fix**: Call `random::initialize(signer)` or ensure your entry function handles auto-initialization.

**Obvious Patterns / Repetition**
*   **Cause**: Calling random functions in a loop within the *same* transaction without updating the counter (internal implementation handles this, but verify `RandomnessCounter` exists).
*   **Fix**: The module automatically increments a counter per call. If you see repetition, ensure you are not simulating or reverting state inappropriately.
