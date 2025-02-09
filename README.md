# Shape Grinders [@Shape_L2](https://shape.network/)
![ShapeGrinders_logo_01](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_logo_02.png)

_Gamified NFTs with fragmentation, dynamic world state, and (NFT) upgradability._

## 🚀 Project Overview
Shape Grinders is a security-oriented NFT engine focusing on gamified and experimental features.
It's an early-stage prototype showcasing techniques and ideas to introduce a new level of complexity in the NFT space.
Inspired by **[ShapeCraft](https://shape.network/shapecraft), [Shape_L2](https://shape.network/)**, and many awesome builders in Web3,
it aims to establish a strong foundation and utility for the rise of the next level of NFT-based game engines.

## 🎮 Concept and Vision

### 🤔 Why?
The NFT space is stuck.
Many players enter the Web3 era for the wrong reasons.
As a result, we often see the reuse of the same business models and techniques,
seeking fast-forward monetization while adding little to no value to the technology.

### 💡 How?
It's time to make the current trends somewhat obsolete by introducing new, shiny layers of complexity.

### 🧪 What?
Shape Grinders is a collection of low-level functionality tailored to introduce
more abstract, advanced, and gamified ways of incentives,
trading, and collection mechanisms, fused with the ERC-721 standard, security, and gamification techniques.

## ✨ Current Features
- 🎨 **Dynamic NFT System**
    - Fragment-based NFT minting
    - 4 fragments required to complete each NFT
    - Automatic fragment tracking and validation

- 🌍 **World State System**
     - Four distinct world states (NEXUS, FLUX, CORE, GEAR)
     - Each fragment carries world state properties
     - State-based metadata generation

- 🔒 **Security & Access Control**
     - Owner-controlled base URI management
     - Safe minting mechanisms
     - Gas-optimized operations

- 📄 **Metadata Management**
     - On-chain base64 encoded metadata
     - IPFS image URI support
     - OpenSea-compatible attribute system

## 📜 Smart Contracts
### Key Standards & Dependencies
- **ERC-721**: Core NFT standard implementation via OpenZeppelin
- **OpenZeppelin**:
    - ERC721URIStorage for metadata handling
    - Ownable for access control
    - Base64 for metadata encoding
    - Strings utilities

### Core Fragment Engine
The system currently implements foundational fragment NFT mechanics:
- Dynamic minting of fragment NFTs
- Four fragments required to complete a single NFT
- Automatic fragment ID generation and tracking
- Gas-optimized circulation management
- On-chain metadata generation with IPFS integration

## 💻 Screenshots
![ShapeGrinders_01](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_01.jpg)
![ShapeGrinders_02](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_02.jpg)
![ShapeGrinders_03](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_03.jpg)
![ShapeGrinders_04](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_04.jpg)
![ShapeGrinders_05](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_05.jpg)
![ShapeGrinders_06](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_06.jpg)
![ShapeGrinders_07](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_07.jpg)
![ShapeGrinders_08](https://github.com/ATrnd/ShapeGrinders/blob/main/img/shape_grinders_screenshots_08.1.jpg)

### 🧑‍💻 Development Status
Currently in testing phase with core functionality:
- ✅ Fragment minting mechanics
- ✅ Fragment-to-NFT tracking
- ✅ Basic world state system
- ⚠️ Temporary pseudo-random number generation (to be replaced)
- 🔄 Metadata system with OpenSea compatibility

### 📝 Milestones & Roadmap

#### ✅ Completed
- Core Fragment NFT System
 - ERC721 implementation
 - Fragment minting & tracking
 - Metadata generation
 - Base IPFS integration

#### 🔨 In Progress
- World State System
     - State transitions
     - Event system implementation

#### 🎯 Upcoming
- **Fragment Fusion System**
    - Smart contract mechanics for combining fragments
    - Validation of complete fragment sets

- **Dynamic World State**
    - NFT-driven state changes
    - State transition effects
    - Community interaction mechanics

- **System Security**
    - Multisig implementation for revenue
    - Multisig implementation for image URI updates
    - Secure randomization (replacing current test implementation)

- **Media & Rendering**
    - PFP image/mp4 switching mechanism
    - Enhanced metadata handling
    - Dynamic NFT themes

#### ⚠️ Known Temporary Implementations
- Pseudo-random number generation
- Basic world state transitions

## 🛠️ Technologies & Tools
### Core Development
- **Language**: Solidity ^0.8.28
- **Framework**: Foundry

### Smart Contract Dependencies
- **OpenZeppelin Contracts**:
    - ERC721URIStorage.sol
    - Ownable.sol
    - Base64.sol
    - Strings.sol

### Testing Environment
- **Foundry Tools**:
    - Forge: Contract compilation & testing
    - Anvil: Local Ethereum node
    - Cast: Transaction handling

## Setup Guide 🛠️

### Prerequisites
- Git
- Foundry

### Clone Repository
```bash
git clone https://github.com/ATrnd/ShapeGrinders.git
cd ShapeGrinders
```

### Install Dependencies
```bash
forge install
```

### Run Tests
```bash
forge test -vvv
```

## ⚠️ Disclaimer
**This repository is experimental and for educational purposes only.**<br>
**Not audited** – Don't use this in production environments.<br>
**No warranties** – Provided "as is."

## Contact
For any inquiries, reach out via:

📬 Telegram: [@at_rnd](https://t.me/at_rnd)

## 📜 License
MIT License

