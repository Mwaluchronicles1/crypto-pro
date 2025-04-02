// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title DocumentVerification
 * @dev A contract for verifying document authenticity on the blockchain
 * @notice Gas-optimized version with security improvements
 */
contract DocumentVerification {
    enum VerificationStatus { Pending, Approved, Rejected }

    struct Document {
        bytes32 hashBytes; // Changed from string to bytes32 for gas optimization
        string title;
        address owner;
        uint256 timestamp;
        bool exists;
        VerificationStatus status;
        address[] verifiers;
        string rejectionReason;
    }

    // Main storage
    mapping(bytes32 => Document) private documents;
    mapping(address => bool) public verifiers;
    address public immutable admin; // Immutable saves gas
    uint256 private verifierCount;
    
    // Events
    event DocumentRegistered(bytes32 indexed hashBytes, string title, address indexed owner);
    event VerificationRequested(bytes32 indexed hashBytes, address indexed requester);
    event DocumentVerified(bytes32 indexed hashBytes, VerificationStatus status, address indexed verifier, string reason);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

    // Custom errors - more gas efficient than require statements with strings
    error NotAuthorizedVerifier();
    error DocumentAlreadyRegistered();
    error DocumentDoesNotExist();
    error EmptyHash();
    error AlreadyVerifier();
    error NotVerifier();
    error OnlyOwnerCanRequest();
    error VerificationCompleted();
    error RejectionReasonRequired();
    error CannotRemoveLastVerifier();
    
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAuthorizedVerifier();
        _;
    }

    modifier onlyVerifier() {
        if (!verifiers[msg.sender]) revert NotAuthorizedVerifier();
        _;
    }

    constructor() {
        admin = msg.sender;
        verifiers[msg.sender] = true; // Deployer is initial verifier
        verifierCount = 1;
    }

    /**
     * @dev Converts a string to bytes32 for storage optimization
     * @param source The string to convert
     * @return result The bytes32 representation
     */
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        // Convert string to bytes32 for gas-efficient storage
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev Register a new document on the blockchain
     * @param hash The document hash as a string
     * @param title The document title
     * @return success Whether the operation was successful
     */
    function registerDocument(string memory hash, string memory title) public returns (bool) {
        bytes32 hashBytes = stringToBytes32(hash);
        if (hashBytes == 0) revert EmptyHash();
        
        Document storage doc = documents[hashBytes];
        if (doc.exists) revert DocumentAlreadyRegistered();

        // Create new document with fewer storage writes
        doc.hashBytes = hashBytes;
        doc.title = title;
        doc.owner = msg.sender;
        doc.timestamp = block.timestamp;
        doc.exists = true;
        doc.status = VerificationStatus.Pending;
        // No need to initialize empty arrays or strings as they default to empty

        emit DocumentRegistered(hashBytes, title, msg.sender);
        return true;
    }

    /**
     * @dev Request verification for a document
     * @param hash The document hash as a string
     */
    function requestVerification(string memory hash) public {
        bytes32 hashBytes = stringToBytes32(hash);
        Document storage doc = documents[hashBytes];
        
        if (!doc.exists) revert DocumentDoesNotExist();
        if (doc.owner != msg.sender) revert OnlyOwnerCanRequest();
        if (doc.status != VerificationStatus.Pending) revert VerificationCompleted();

        emit VerificationRequested(hashBytes, msg.sender);
    }

    /**
     * @dev Verify a document
     * @param hash The document hash as a string
     * @param approved Whether the document is approved
     * @param reason The reason for rejection if not approved
     */
    function verifyDocument(
        string memory hash,
        bool approved,
        string memory reason
    ) public onlyVerifier {
        bytes32 hashBytes = stringToBytes32(hash);
        Document storage doc = documents[hashBytes];
        
        if (!doc.exists) revert DocumentDoesNotExist();
        if (doc.status != VerificationStatus.Pending) revert VerificationCompleted();

        if (approved) {
            doc.status = VerificationStatus.Approved;
            doc.verifiers.push(msg.sender);
        } else {
            if (bytes(reason).length == 0) revert RejectionReasonRequired();
            doc.status = VerificationStatus.Rejected;
            doc.rejectionReason = reason;
        }

        emit DocumentVerified(hashBytes, doc.status, msg.sender, reason);
    }

    /**
     * @dev Add a new verifier
     * @param verifier The address to add as a verifier
     */
    function addVerifier(address verifier) public onlyAdmin {
        if (verifiers[verifier]) revert AlreadyVerifier();
        verifiers[verifier] = true;
        verifierCount++;
        emit VerifierAdded(verifier);
    }

    /**
     * @dev Remove a verifier
     * @param verifier The address to remove as a verifier
     */
    function removeVerifier(address verifier) public onlyAdmin {
        if (!verifiers[verifier]) revert NotVerifier();
        if (verifierCount <= 1) revert CannotRemoveLastVerifier();
        verifiers[verifier] = false;
        verifierCount--;
        emit VerifierRemoved(verifier);
    }

    /**
     * @dev Get detailed information about a document
     * @param hash The document hash as a string
     * @return Document details (hash, title, owner, timestamp, exists, status, verifiers, rejectionReason)
     */
    function getDocument(string memory hash) public view returns (
        string memory,
        string memory,
        address,
        uint256,
        bool,
        VerificationStatus,
        address[] memory,
        string memory
    ) {
        bytes32 hashBytes = stringToBytes32(hash);
        Document storage doc = documents[hashBytes];
        
        // For non-existent documents, return default values
        if (!doc.exists) {
            return ("", "", address(0), 0, false, VerificationStatus.Pending, new address[](0), "");
        }
        
        return (
            hash,
            doc.title,
            doc.owner,
            doc.timestamp,
            doc.exists,
            doc.status,
            doc.verifiers,
            doc.rejectionReason
        );
    }

    /**
     * @dev Get just the verification status of a document
     * @param hash The document hash as a string
     * @return status The verification status
     */
    function getVerificationStatus(string memory hash) public view returns (VerificationStatus) {
        bytes32 hashBytes = stringToBytes32(hash);
        if (!documents[hashBytes].exists) revert DocumentDoesNotExist();
        return documents[hashBytes].status;
    }

    /**
     * @dev Check if an address is a verifier
     * @param verifier The address to check
     * @return isVerifier Whether the address is a verifier
     */
    function isVerifier(address verifier) public view returns (bool) {
        return verifiers[verifier];
    }
}