# Inferenco Randomness (Cedra Testnet)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Network: Cedra Testnet](https://img.shields.io/badge/Network-Cedra_Testnet-blue)](https://cedrascan.com)
[![Language: Move](https://img.shields.io/badge/Language-Move-green)](https://move-language.github.io/move/)

A custom randomness module for the Cedra Network that provides a drop-in replacement for `cedra_framework::randomness` when native VRF is unavailable.

> **Security Note**: This module is intended for **testnet and low-stakes usage only**. It uses on-chain entropy sources which are predictable by validators.

## Documentation

- **[Deployment Guide](DEPLOYMENT_GUIDE.md)**: Steps to compile, test, and publish.
- **[Developer Documentation](DOCUMENTATION.md)**: API reference and integration guide.

## Quick Start

```bash
git clone https://github.com/Inferenco/inferenco-randomness-cedra-testnet.git
cd inferenco-randomness-cedra-testnet
cedra move test --named-addresses inferenco=0x1
```

## Usage

```move
use inferenco::randomness;

// Get 32 random bytes
let random_bytes = randomness::bytes(32);

// Random u64
let num = randomness::u64_integer();

// Random in range [0, 100)
let pct = randomness::u64_range(0, 100);

// Dice roll (1-6)
let roll = randomness::dice_roll(6);
```

## Features

- Drop-in replacement API matching `cedra_framework::randomness`
- Integer generation: u8, u16, u32, u64, u128, u256
- Range functions for all integer types
- Utility functions: permutation, shuffle, pick, weighted_choice
- Game helpers: dice_roll, coin_flip, boolean

## License

[MIT License](LICENSE)
