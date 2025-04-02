# DocumentVerification Smart Contract

This repository contains a gas-optimized, security-audited smart contract for document verification on the Ethereum blockchain. It allows users to register documents and verifiers to approve or reject them, all while maintaining an immutable record on the blockchain.

## Features

- **Document Registration**: Register document hashes with metadata
- **Verification Process**: Approve or reject documents with reasons
- **Role-Based Access**: Admin and verifier roles for secure operations
- **Gas Optimized**: Efficient storage patterns and operations
- **Security Focused**: Custom errors, access controls, and input validation

## Directory Structure

```
hardhat-contracts/
├── contracts/                   # Smart contract source code
│   ├── DocumentVerification.sol # Main contract for document verification
│   └── Lock.sol                 # Example contract (can be ignored)
├── test/                        # Test files
│   └── DocumentVerification.test.js # Comprehensive tests
├── scripts/                     # Deployment scripts
│   └── deploy_document_verification.js # Script to deploy to Ganache
├── SECURITY_AUDIT.md            # Security audit report
├── GAS_OPTIMIZATION.md          # Gas optimization guide
└── README.md                    # This file
```

## Gas Optimization Overview

The contract has been optimized for gas efficiency using the following techniques:

1. **bytes32 for hashes**: Using fixed-size types instead of strings
2. **Custom errors**: More efficient than string error messages
3. **Storage patterns**: Reduced storage operations
4. **Immutable variables**: For admin and constant values
5. **Indexed events**: For efficient filtering

For detailed information on gas optimizations, see [GAS_OPTIMIZATION.md](./GAS_OPTIMIZATION.md).

## Security Audit

The contract has undergone a security audit that identified and addressed several potential vulnerabilities:

1. **Access Control**: Properly implemented admin and verifier roles
2. **Input Validation**: Comprehensive checks for all inputs
3. **State Management**: Proper handling of document states
4. **Custom Errors**: Detailed error reporting for better debugging

For the full security audit report, see [SECURITY_AUDIT.md](./SECURITY_AUDIT.md).

## Quick Start

### Prerequisites

- Node.js and npm
- Ganache (for local Ethereum development)
- Hardhat

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```

2. Install dependencies:
   ```bash
   cd hardhat-contracts
   npm install
   ```

3. Start Ganache (either through the UI or CLI):
   ```bash
   ganache-cli
   ```

4. Deploy the contract to Ganache:
   ```bash
   npx hardhat run scripts/deploy_document_verification.js --network ganache
   ```

5. Run tests:
   ```bash
   npx hardhat test
   ```

### Running Gas Reports

To generate a detailed gas usage report:

```bash
npx hardhat test
```

The report will be generated in `gas-report.txt`.

## Contract Usage

### Document Registration

```javascript
// Register a document
const hash = "0xabcdef1234567890"; // Document hash
const title = "My Important Document"; // Document title
await documentVerification.registerDocument(hash, title);
```

### Document Verification

```javascript
// Approve a document
await documentVerification.verifyDocument(hash, true, "");

// Reject a document
const reason = "Document contains errors";
await documentVerification.verifyDocument(hash, false, reason);
```

### Verifier Management

```javascript
// Add a verifier
await documentVerification.addVerifier(verifierAddress);

// Remove a verifier
await documentVerification.removeVerifier(verifierAddress);
```

## Integration with Frontend

To integrate with your Flutter application:

1. Deploy the contract and note the contract address
2. Update your Flutter app's contract constants:

```dart
// In lib/utils/constants.dart
class ContractConstants {
  static const contractAddress = '0x...'; // Your deployed contract address
}
```

3. Use the contract methods via web3dart:

```dart
// Example of calling the contract from Flutter
final result = await contractService.registerDocument(
  hash: documentHash, 