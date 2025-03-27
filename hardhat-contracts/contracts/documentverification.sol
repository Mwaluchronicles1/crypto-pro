// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DocumentVerification {
    enum VerificationStatus { Pending, Approved, Rejected }

    struct Document {
        string hash;
        string title;
        address owner;
        uint256 timestamp;
        bool exists;
        VerificationStatus status;
        address[] verifiers;
        string rejectionReason;
    }

    mapping(string => Document) private documents;
    mapping(address => bool) public verifiers;

    event DocumentRegistered(string hash, string title, address owner);
    event VerificationRequested(string hash, address requester);
    event DocumentVerified(string hash, VerificationStatus status, address verifier, string reason);
    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);

    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Not authorized verifier");
        _;
    }

    constructor() {
        verifiers[msg.sender] = true; // Deployer is initial verifier
    }

    function registerDocument(string memory hash, string memory title) public returns (bool) {
        require(bytes(hash).length > 0, "Hash cannot be empty");
        require(!documents[hash].exists, "Document already registered");

        documents[hash] = Document({
            hash: hash,
            title: title,
            owner: msg.sender,
            timestamp: block.timestamp,
            exists: true,
            status: VerificationStatus.Pending,
            verifiers: new address[](0),
            rejectionReason: ""
        });

        emit DocumentRegistered(hash, title, msg.sender);
        return true;
    }

    function requestVerification(string memory hash) public {
        require(documents[hash].exists, "Document does not exist");
        require(documents[hash].owner == msg.sender, "Only document owner can request verification");
        require(documents[hash].status == VerificationStatus.Pending, "Verification already in progress");

        emit VerificationRequested(hash, msg.sender);
    }

    function verifyDocument(
        string memory hash,
        bool approved,
        string memory reason
    ) public onlyVerifier {
        Document storage doc = documents[hash];
        require(doc.exists, "Document does not exist");
        require(doc.status == VerificationStatus.Pending, "Verification already completed");

        if (approved) {
            doc.status = VerificationStatus.Approved;
            doc.verifiers.push(msg.sender);
        } else {
            require(bytes(reason).length > 0, "Rejection reason required");
            doc.status = VerificationStatus.Rejected;
            doc.rejectionReason = reason;
        }

        emit DocumentVerified(hash, doc.status, msg.sender, reason);
    }

    function addVerifier(address verifier) public onlyVerifier {
        require(!verifiers[verifier], "Address is already a verifier");
        verifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }

    function removeVerifier(address verifier) public onlyVerifier {
        require(verifiers[verifier], "Address is not a verifier");
        verifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }

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
        Document memory doc = documents[hash];
        return (
            doc.hash,
            doc.title,
            doc.owner,
            doc.timestamp,
            doc.exists,
            doc.status,
            doc.verifiers,
            doc.rejectionReason
        );
    }

    function getVerificationStatus(string memory hash) public view returns (VerificationStatus) {
        require(documents[hash].exists, "Document does not exist");
        return documents[hash].status;
    }
}