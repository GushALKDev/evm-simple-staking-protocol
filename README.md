# 🏦 Simple Staking Protocol

> A straightforward and efficient staking protocol enabling secure token staking with rewards on Ethereum Virtual Machines.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/solidity-^0.8.13-blue)](https://docs.soliditylang.org/en/v0.8.13/)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/yourusername/SimpleStaking)

## 📝 Description

Simple Staking is a decentralized protocol that provides a secure and efficient way to stake ERC20 tokens and earn rewards. The protocol features a straightforward but battle-tested design, making it ideal for projects looking to implement staking functionality without unnecessary complexity.

## ⚙️ Features

🔐 **Security Features**
- Reentrancy protection using OpenZeppelin's ReentrancyGuard
- Comprehensive input validation
- Access control using Ownable pattern
- Full test coverage with edge cases

🛠️ **Core Functionality**
- ERC20 token staking
- Block-based reward calculation
- Configurable reward rates
- Partial withdrawals supported
- Flexible reward distribution
- Owner-managed reward pool

## 🏗️ Technical Stack

- **Framework**: Foundry
- **Language**: Solidity ^0.8.13
- **Standards**: ERC20
- **Dependencies**: OpenZeppelin Contracts

## 🚀 Quick Start

### Prerequisites

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/SimpleStaking.git
cd SimpleStaking
```

2. Install dependencies:
```bash
forge install
```

3. Run tests:
```bash
forge test
```

## 📖 Core Contracts

### Staking.sol
Main staking contract handling all staking logic:
```solidity
function stake(uint256 amount)
function withdraw(uint256 amount)
function getRewards()
function addRewards(uint256 amount)
```

### ERC20Token.sol
Test token for development and testing purposes.

## 🔍 Testing

Run the complete test suite:
```bash
forge test -vvv
```

Coverage includes:
- ✅ Setup validation
- ✅ Staking mechanisms
- ✅ Withdrawal flows
- ✅ Reward calculations
- ✅ Multiple users scenarios
- ✅ Edge cases

## 🔒 Security Considerations

The protocol implements several security measures:
- NonReentrant modifiers on critical functions
- Safe math operations (Solidity ^0.8.13)
- Protected reward pool management
- Validated user inputs
- Access control for admin functions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🧪 Test Coverage

The protocol includes extensive testing:
- Basic staking and withdrawal flows
- Multiple user interactions
- Reward calculation accuracy
- Edge cases and security scenarios
