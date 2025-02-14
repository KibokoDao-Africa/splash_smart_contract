## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# 🎓 Learn or Lose: A Staking-Based Learning Platform

## Introduction

How many courses have you bought or pirated and never completed? Imagine a platform that ensures users complete their courses by requiring them to stake money, which they only get back upon successful completion.

Additionally, other users can place bets on enrollees—either supporting them (upvoting) or betting against their success (downvoting). Upon course completion, rewards are distributed among supporters based on their stake, while a small fee is deducted.

---

## 🛠️ Functions

### 📚 Course CRUD
- `create_course(title, description, category, creator) -> course_id`
- `update_course(course_id, title, description, category, creator)`
- `delete_course(course_id)`
- `get_course(course_id)`

### 🚀 Self-Enroll in a Course
- `enroll(user, course_id, deadline, stake=0) -> enroll_id`
- `multi_enroll([user, course_id, deadline, stake=0]) -> [enroll_id]`

### 📋 Utility Functions
- `enrollers(course_id) -> [user]`
- `enrollments(user) -> [enroll_id]`

### 🏆 Update Enrollment Status
- `update(enroll_id, completed_at)`

### 💰 Stake on Enrollment
- `stake(enroll_id, action, amount)`
  - **Action**: `upvote` (bet in favor) or `downvote` (bet against)

### 🎁 Reward Distribution
- `distribute(enroll_id)`

---

## 🎯 Reward Calculation
If an enrolled user **completes** their course **before the deadline**, rewards are distributed among upvoters, while a **10% fee** is deducted from the total.

### Example Calculation
#### 📊 Stake Distribution
- **Upvotes**: 10 + 10 + 20 = **40**
- **Downvotes**: 0
- **Total Votes**: **40**

#### 💸 Fee Calculation
- **Platform Fee** = 10% of total votes = `4`
- **Reward Pool** = `40 - 4 = 36`

#### 🎉 Reward Distribution
- **10/40 * 36** = `9`
- **10/40 * 36** = `9`
- **20/40 * 36** = `18`

---

### 📌 Summary
- **Learners must complete courses to reclaim their stake**
- **Supporters (upvoters) share the winnings if the learner completes**
- **Downvoters lose their stake if the learner completes**
- **A small fee is deducted to maintain platform sustainability**

This creates a high-stakes, gamified learning environment that ensures accountability and engagement. 🚀

