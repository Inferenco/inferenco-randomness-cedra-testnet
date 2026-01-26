# Inferenco Randomness (Cedra Testnet)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Network: Cedra Testnet](https://img.shields.io/badge/Network-Cedra_Testnet-blue)](https://cedrascan.com)
[![Language: Move](https://img.shields.io/badge/Language-Move-green)](https://move-language.github.io/move/)
[![Status: Released](https://img.shields.io/badge/Status-Released-success)]()

A custom randomness module built for the Cedra Network, designed to provide on-chain pseudorandom number generation to support game prototyping and development on testnet.

> **⚠️ Security Note**: This module is intended for **testnet and low-stakes usage only**. It utilizes on-chain entropy sources which are verifiable but ultimately predictable by validators. Do not use for high-value financial applications.

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT_GUIDE.md)**: Steps to compile, test, and publish to Cedra Testnet.
- **[Developer Documentation](DOCUMENTATION.md)**: API reference, verification, and integration usage.

## 🚀 Quick Start

### Installation

Clone the repository and install dependencies (Cedra CLI required).

```bash
git clone https://github.com/Inferenco/inferenco-randomness-cedra-testnet.git
cd inferenco-randomness-cedra-testnet
cedra init --profile testnet --network testnet
```

### Run Tests

Verify the contract logic:

```bash
cedra move test --named-addresses inferenco=0x1
```

## 🎮 Features

- **Integer Generation**: u8, u64, u256 support.
- **Game Helpers**: Dice rolls, coin flips, weighted choice, deck shuffling.
- **Example Games**: Includes implementations for Dice, Card, PvP, and Loot Box mechanics.

## License

This project is licensed under the [MIT License](LICENSE).
