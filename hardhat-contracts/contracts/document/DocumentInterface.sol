// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title DocumentVerification Interface
 * @dev This file contains interfaces and abstract examples 
 *      showcasing the optimization patterns used in the main contract
 */

// Common structures referenced in the GAS_OPTIMIZATION.md examples
enum VerificationStatus { Pending, Approved, Rejected }

struct Document {
    bytes32 hashBytes;
    string title;
    address owner;
    uint256 timestamp;
    bool exists;
    VerificationStatus status;
    address[] verifiers;
    string rejectionReason;
}

// Custom errors used in optimization examples
error NotAuthorizedVerifier();
error DocumentDoesNotExist(bytes32 hashBytes);
error NotAuthorized();
error AlreadyVerifier();
error VerifierAlreadyExists(address verifier);
error NotVerifier();
error CannotRemoveLastVerifier();
error DocumentAlreadyRegistered();
error EmptyHash();
error OnlyOwnerCanRequest();
error VerificationCompleted();
error RejectionReasonRequired();

/**
 * @dev Example contract for the before optimization state
 */
contract DocumentVerificationBefore {
    // Before optimization examples
    mapping(string => Document) private documents;
    address public admin;
    mapping(address => bool) public verifiers;
    
    event DocumentRegistered(string hash, string title, address owner);
    
    constructor() {
        admin = msg.sender;
    }
    
    function registerDocument(string memory hash, string memory title) public {
        documents[hash] = Document({
            hashBytes: bytes32(0), // placeholder for example
            title: title,
            owner: msg.sender,
            timestamp: block.timestamp,
            exists: true,
            status: VerificationStatus.Pending,
            verifiers: new address[](0),
            rejectionReason: ""
        });
    }
    
    function verifyDocument(string memory hash, bool approved) public {
        require(verifiers[msg.sender], "Not authorized verifier");
        // Rest of implementation omitted for brevity
    }
    
    function getVerifierCount() public view returns (uint256 count) {
        address[] memory allAddresses = new address[](0); // Simplified
        for (uint i = 0; i < allAddresses.length; i++) {
            if (verifiers[allAddresses[i]]) {
                count++;
            }
        }
        return count;
    }
}

/**
 * @dev Example contract for the after optimization state
 */
contract DocumentVerificationAfter {
    // After optimization examples
    mapping(bytes32 => Document) private documents;
    address public immutable admin;
    mapping(address => bool) public verifiers;
    uint256 private verifierCount;
    
    event DocumentRegistered(bytes32 indexed hashBytes, string title, address indexed owner);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    
    constructor() {
        admin = msg.sender;
        verifiers[msg.sender] = true;
        verifierCount = 1;
    }
    
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAuthorized();
        _;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function registerDocument(string memory hash, string memory title) public {
        bytes32 hashBytes = stringToBytes32(hash);
        
        Document storage doc = documents[hashBytes];
        doc.hashBytes = hashBytes;
        doc.title = title;
        doc.owner = msg.sender;
        doc.timestamp = block.timestamp;
        doc.exists = true;
        doc.status = VerificationStatus.Pending;
        // No need to initialize empty arrays or strings as they default to empty
    }
    
    function verifyDocument(string memory hash, bool approved, string memory rejectionReason) public {
        // Exit early if not a verifier
        if (!verifiers[msg.sender]) revert NotAuthorizedVerifier();
        
        bytes32 hashBytes = stringToBytes32(hash);
        Document storage doc = documents[hashBytes];
        
        // Exit early if document doesn't exist
        if (!doc.exists) revert DocumentDoesNotExist(hashBytes);
        
        // Exit early if document is already verified
        if (doc.status != VerificationStatus.Pending) revert VerificationCompleted();
        
        // Rest of implementation omitted for brevity
    }
    
    function addVerifier(address verifier) public onlyAdmin {
        if (verifiers[verifier]) revert AlreadyVerifier();
        verifiers[verifier] = true;
        verifierCount++;
        emit VerifierAdded(verifier);
    }
    
    function removeVerifier(address verifier) public onlyAdmin {
        if (!verifiers[verifier]) revert NotVerifier();
        if (verifierCount <= 1) revert CannotRemoveLastVerifier();
        verifiers[verifier] = false;
        verifierCount--;
        emit VerifierRemoved(verifier);
    }
    
    function getVerifierCount() public view returns (uint256) {
        return verifierCount;
    }
} 