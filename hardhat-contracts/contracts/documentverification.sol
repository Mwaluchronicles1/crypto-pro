// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;  // Update this line to match

contract DocumentVerification {
    struct Document {
        string hash;
        string title;
        address owner;
        uint256 timestamp;
        bool exists;
    }

    mapping(string => Document) private documents;

    event DocumentRegistered(string hash, string title, address owner);
    event DocumentVerified(string hash, bool verified);

    function registerDocument(string memory hash, string memory title) public returns (bool) {
        require(bytes(hash).length > 0, "Hash cannot be empty");
        require(!documents[hash].exists, "Document already registered");

        documents[hash] = Document({
            hash: hash,
            title: title,
            owner: msg.sender,
            timestamp: block.timestamp,
            exists: true
        });

        emit DocumentRegistered(hash, title, msg.sender);
        return true;
    }

    function verifyDocument(string memory hash) public view returns (bool) {
        return documents[hash].exists;
    }
}