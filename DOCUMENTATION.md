# Inferenco Randomness Module - Documentation

## Introduction

The `inferenco::randomness` module provides pseudorandom number generation (PRNG) for the Cedra network. It is designed as a drop-in replacement for `cedra_framework::randomness` when native VRF is unavailable.

> **Security Warning**: This module uses on-chain entropy (timestamp, transaction hash). It is predictable by validators and should **NOT** be used for high-stakes financial applications.

## Usage Guidelines & Security

### When to Use This Module
*   Low-stakes games and testing
*   Non-financial randomness (loot drops, matchmaking, cosmetics)
*   Development and prototyping on testnet
*   Educational purposes

### When NOT to Use This Module
*   High-value financial applications
*   Lotteries, casinos, or defi protocols with significant funds
*   Any system where randomness integrity is the sole security guarantee

## Integration

### 1. Add Dependency

Reference the package in your `Move.toml`:

```toml
[dependencies]
CedraFramework = { git = "https://github.com/cedra-labs/cedra-framework.git", rev = "mainnet" }
# InferencoRandomness = { local = "../inferenco-randomness" }
```

### 2. Basic Usage

The API matches native `cedra_framework::randomness` - no caller address needed:

```move
module my_game::dice {
    use inferenco::randomness;

    entry fun roll(_player: &signer) {
        // Get 32 random bytes
        let random_bytes = randomness::bytes(32);

        // Roll a d6
        let result = randomness::dice_roll(6);

        // Random u64
        let random_num = randomness::u64_integer();

        // Random in range [1, 100)
        let percentage = randomness::u64_range(1, 100);
    }
}
```

## API Reference

### Initialization
*   `initialize(account: &signer)`: One-time setup. Must be called by the module deployer (`@inferenco`).

### Bytes
*   `bytes(n: u64): vector<u8>`: Returns `n` random bytes.

### Integer Generation
*   `u8_integer(): u8`
*   `u16_integer(): u16`
*   `u32_integer(): u32`
*   `u64_integer(): u64`
*   `u128_integer(): u128`
*   `u256_integer(): u256`

### Ranges
*   `u8_range(min: u8, max: u8): u8`
*   `u16_range(min: u16, max: u16): u16`
*   `u32_range(min: u32, max: u32): u32`
*   `u64_range(min: u64, max: u64): u64`
*   `u128_range(min: u128, max: u128): u128`
*   `u256_range(min: u256, max: u256): u256`

Returns a value where `min <= value < max`.

### Game Helpers
*   `dice_roll(sides: u64): u64` - Returns `1` to `sides` (inclusive).
*   `dice_roll_sum(num_dice: u64, sides: u64): u64` - Sum of multiple dice.
*   `coin_flip(): bool` - Returns `true` or `false`.
*   `boolean(probability: u8): bool` - Returns true with `probability` percent chance (0-100).
*   `critical_hit(crit_chance_percent: u8): bool` - Alias for boolean.
*   `weighted_choice(weights: &vector<u64>): u64` - Returns weighted random index.

### Utilities
*   `permutation(n: u64): vector<u64>` - Random permutation of [0, n).
*   `shuffle<T: drop>(vec: &mut vector<T>)` - Shuffles a vector in-place.
*   `pick<T: copy>(vec: &vector<T>): T` - Returns a random element.

### View Functions
*   `is_initialized(): bool` - Check if module is initialized.
*   `get_counter(): u64` - Get current counter value.

## Migration to Native Randomness

When Cedra releases native VRF support:

1.  Replace `use inferenco::randomness` with `use cedra_framework::randomness`.
2.  Remove the `initialize` call (native randomness doesn't require it).
3.  The function signatures are identical - no other changes needed.

## Troubleshooting

**Error: `E_NOT_INITIALIZED` (code 2)**
*   **Cause**: Module not initialized.
*   **Fix**: The module deployer must call `randomness::initialize(signer)` once after deployment.

**Error: `E_NOT_AUTHORIZED` (code 4)**
*   **Cause**: Non-deployer tried to call initialize.
*   **Fix**: Only the account at `@inferenco` can initialize.
