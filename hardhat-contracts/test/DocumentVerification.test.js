const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DocumentVerification", function () {
    let documentVerification;
    let owner;

    beforeEach(async function () {
        [owner] = await ethers.getSigners();
        const DocumentVerification = await ethers.getContractFactory("DocumentVerification");
        documentVerification = await DocumentVerification.deploy();
    });

    // ... (other tests)

    it("Should return default values for non-existent documents", async function () {
        const nonExistentHash = "0xabcdef1234567890";

        const [
            retrievedHash,
            retrievedTitle,
            ownerAddress,
            timestamp,
            exists,
            status,
            verifiers,
            rejectionReason
        ] = await documentVerification.getDocument(nonExistentHash);

        expect(retrievedHash).to.equal("");
        expect(retrievedTitle).to.equal("");
        expect(ownerAddress).to.equal(ethers.ZeroAddress);
        expect(timestamp).to.equal(0);
        expect(exists).to.be.false;
        expect(status).to.equal(0); // VerificationStatus.Pending
        expect(verifiers).to.deep.equal([]);
        expect(rejectionReason).to.equal("");
    });

    // Add more comprehensive tests
    it("Should register a new document", async function () {
        const hash = "0xabcdef1234567890";
        const title = "Test Document";

        await documentVerification.registerDocument(hash, title);

        const [
            retrievedHash,
            retrievedTitle,
            ownerAddress,
            timestamp,
            exists,
            status,
            verifiers,
            rejectionReason
        ] = await documentVerification.getDocument(hash);

        expect(retrievedHash).to.equal(hash);
        expect(retrievedTitle).to.equal(title);
        expect(ownerAddress).to.equal(owner.address);
        expect(timestamp).to.not.equal(0);
        expect(exists).to.be.true;
        expect(status).to.equal(0); // VerificationStatus.Pending
        expect(verifiers).to.deep.equal([]);
        expect(rejectionReason).to.equal("");
    });

    it("Should allow verifier to verify document", async function () {
        const hash = "0xabcdef1234567890";
        const title = "Test Document";

        await documentVerification.registerDocument(hash, title);
        await documentVerification.verifyDocument(hash, true, "");

        const [,,,, exists, status, verifiers] = await documentVerification.getDocument(hash);

        expect(exists).to.be.true;
        expect(status).to.equal(1); // VerificationStatus.Approved
        expect(verifiers).to.deep.equal([owner.address]);
    });

    it("Should allow verifier to reject document", async function () {
        const hash = "0xabcdef1234567890";
        const title = "Test Document";
        const reason = "Invalid document";

        await documentVerification.registerDocument(hash, title);
        await documentVerification.verifyDocument(hash, false, reason);

        const [,,,, exists, status,, rejectionReason] = await documentVerification.getDocument(hash);

        expect(exists).to.be.true;
        expect(status).to.equal(2); // VerificationStatus.Rejected
        expect(rejectionReason).to.equal(reason);
    });
});