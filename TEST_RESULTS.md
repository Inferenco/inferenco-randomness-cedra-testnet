# Testnet Verification Results

**Date**: 2026-01-26
**Network**: Cedra Testnet
**Profile**: `testnet`
**Deployer**: `0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403`

## 1. Random Event Generation
Tested the `trigger_random_event` function which uses weighted probabilities to select an event type.

- **Command**: `cedra move run --function-id 'testnet::game_examples::trigger_random_event'`
- **Transaction**: [`0xbb75...acc`](https://cedrascan.com/txn/0xbb75586970b70c09f283192d96ef9c206c8c3d0634514e4952d354ac0f6aeacc?network=testnet)
- **Status**: ✅ Success
- **Gas Used**: 7
- **Result**: Emitted `RandomEventTriggered` event.

## 2. Dice Game
Tested resource initialization and state modification using randomness.

### Initialization
- **Function**: `initialize_dice`
- **Transaction**: [`0x6aa2...953`](https://cedrascan.com/txn/0x6aa2a7bf767fe4c1a66399d6b17db7b43c6aff69dfb0130a5eb5eda9eb590953?network=testnet)
- **Status**: ✅ Success
- **Gas Used**: 450

### Gameplay (Roll Dice)
- **Function**: `roll_dice(6)`
- **Transaction**: [`0x8a55...d62`](https://cedrascan.com/txn/0x8a555305eafebb3682a9d7e12762bb5b66ca4bd85ee63b7bad14b3ddf5e90d62?network=testnet)
- **Status**: ✅ Success
- **Gas Used**: 7
- **Result**: Updated `DiceGame` resource with new roll.

## 3. Lottery System
Tested a multi-step flow involving admin setup, user interaction, and randomness-based selection.

### Setup
- **Function**: `init_lottery(100)`
- **Transaction**: [`0x6806...e34`](https://cedrascan.com/txn/0x68060cd68a02dd797eb41482f065d1e8a6f4aeab8ad46c9dec8f83f23d306e34?network=testnet)
- **Status**: ✅ Success
- **Gas Used**: 443

### Participation
- **Function**: `buy_ticket`
- **Transaction**: [`0x9c63...b70b`](https://cedrascan.com/txn/0x9c63c73919160d8a8e770a3929e3807bd640f81d1d7345a8093b72e72d56b70b?network=testnet)
- **Status**: ✅ Success
- **Gas Used**: 18

### Selection
- **Function**: `draw_winner`
- **Transaction**: [`0x2d55...5c6`](https://cedrascan.com/txn/0x2d55dceff5e9e46838627f4411ba96f8769bf338688b8160b8c4181397be15c6?network=testnet)
- **Status**: ✅ Success
- **Gas Used**: 7
- **Result**: Selected winner from ticket pool and emitted `LotteryWinner` event.
