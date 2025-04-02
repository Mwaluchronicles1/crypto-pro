const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DocumentVerification", function () {
    let documentVerification;
    let owner;
    let addr1;
    let addr2;
    let addr3;

    beforeEach(async function () {
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        const DocumentVerification = await ethers.getContractFactory("DocumentVerification");
        documentVerification = await DocumentVerification.deploy();
        await documentVerification.waitForDeployment();
    });

    describe("Basic Functionality", function () {
        it("Should deploy and set owner as initial verifier", async function () {
            expect(await documentVerification.isVerifier(owner.address)).to.be.true;
            expect(await documentVerification.admin()).to.equal(owner.address);
        });

        it("Should convert string to bytes32 correctly", async function () {
            const testString = "0xabcdef1234567890";
            const bytes32Value = await documentVerification.stringToBytes32(testString);
            expect(bytes32Value).to.not.equal(ethers.ZeroHash);
        });

        it("Should return zero for empty string conversion", async function () {
            const emptyString = "";
            const bytes32Value = await documentVerification.stringToBytes32(emptyString);
            expect(bytes32Value).to.equal(ethers.ZeroHash);
        });
    });

    describe("Document Registration", function () {
        it("Should register a new document", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await expect(documentVerification.registerDocument(hash, title))
                .to.emit(documentVerification, "DocumentRegistered")
                .withArgs(await documentVerification.stringToBytes32(hash), title, owner.address);

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

        it("Should revert when registering with empty hash", async function () {
            const emptyHash = "";
            const title = "Empty Hash Document";

            await expect(documentVerification.registerDocument(emptyHash, title))
                .to.be.revertedWithCustomError(documentVerification, "EmptyHash");
        });

        it("Should revert when registering duplicate document", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.registerDocument(hash, "Another Title"))
                .to.be.revertedWithCustomError(documentVerification, "DocumentAlreadyRegistered");
        });
    });

    describe("Verification Requests", function () {
        it("Should allow document owner to request verification", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.requestVerification(hash))
                .to.emit(documentVerification, "VerificationRequested")
                .withArgs(await documentVerification.stringToBytes32(hash), owner.address);
        });

        it("Should revert when non-owner requests verification", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.connect(addr1).requestVerification(hash))
                .to.be.revertedWithCustomError(documentVerification, "OnlyOwnerCanRequest");
        });

        it("Should revert request for non-existent document", async function () {
            const nonExistentHash = "0x1234567890abcdef";

            await expect(documentVerification.requestVerification(nonExistentHash))
                .to.be.revertedWithCustomError(documentVerification, "DocumentDoesNotExist");
        });
    });

    describe("Document Verification", function () {
        it("Should allow verifier to approve document", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.verifyDocument(hash, true, ""))
                .to.emit(documentVerification, "DocumentVerified")
                .withArgs(
                    await documentVerification.stringToBytes32(hash), 
                    1, // VerificationStatus.Approved
                    owner.address, 
                    ""
                );

            const [,,,, exists, status, verifiers] = await documentVerification.getDocument(hash);

            expect(exists).to.be.true;
            expect(status).to.equal(1); // VerificationStatus.Approved
            expect(verifiers).to.deep.equal([owner.address]);
        });

        it("Should allow verifier to reject document with reason", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";
            const reason = "Invalid document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.verifyDocument(hash, false, reason))
                .to.emit(documentVerification, "DocumentVerified")
                .withArgs(
                    await documentVerification.stringToBytes32(hash), 
                    2, // VerificationStatus.Rejected
                    owner.address, 
                    reason
                );

            const [,,,, exists, status,, rejectionReason] = await documentVerification.getDocument(hash);

            expect(exists).to.be.true;
            expect(status).to.equal(2); // VerificationStatus.Rejected
            expect(rejectionReason).to.equal(reason);
        });

        it("Should revert when rejecting without reason", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.verifyDocument(hash, false, ""))
                .to.be.revertedWithCustomError(documentVerification, "RejectionReasonRequired");
        });

        it("Should revert when non-verifier tries to verify", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);

            await expect(documentVerification.connect(addr1).verifyDocument(hash, true, ""))
                .to.be.revertedWithCustomError(documentVerification, "NotAuthorizedVerifier");
        });

        it("Should revert verification for non-existent document", async function () {
            const nonExistentHash = "0x1234567890abcdef";

            await expect(documentVerification.verifyDocument(nonExistentHash, true, ""))
                .to.be.revertedWithCustomError(documentVerification, "DocumentDoesNotExist");
        });

        it("Should revert verification for already verified document", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);
            await documentVerification.verifyDocument(hash, true, "");

            await expect(documentVerification.verifyDocument(hash, true, ""))
                .to.be.revertedWithCustomError(documentVerification, "VerificationCompleted");
        });
    });

    describe("Verifier Management", function () {
        it("Should allow admin to add verifier", async function () {
            await expect(documentVerification.addVerifier(addr1.address))
                .to.emit(documentVerification, "VerifierAdded")
                .withArgs(addr1.address);

            expect(await documentVerification.isVerifier(addr1.address)).to.be.true;
        });

        it("Should revert when adding existing verifier", async function () {
            await documentVerification.addVerifier(addr1.address);

            await expect(documentVerification.addVerifier(addr1.address))
                .to.be.revertedWithCustomError(documentVerification, "AlreadyVerifier");
        });

        it("Should allow admin to remove verifier", async function () {
            await documentVerification.addVerifier(addr1.address);
            
            await expect(documentVerification.removeVerifier(addr1.address))
                .to.emit(documentVerification, "VerifierRemoved")
                .withArgs(addr1.address);

            expect(await documentVerification.isVerifier(addr1.address)).to.be.false;
        });

        it("Should revert when removing non-verifier", async function () {
            await expect(documentVerification.removeVerifier(addr1.address))
                .to.be.revertedWithCustomError(documentVerification, "NotVerifier");
        });

        it("Should revert when non-admin tries to add verifier", async function () {
            await expect(documentVerification.connect(addr1).addVerifier(addr2.address))
                .to.be.revertedWithCustomError(documentVerification, "NotAuthorizedVerifier");
        });

        it("Should revert when removing last verifier", async function () {
            // Try to remove owner (the only verifier)
            await expect(documentVerification.removeVerifier(owner.address))
                .to.be.revertedWithCustomError(documentVerification, "CannotRemoveLastVerifier");
        });

        it("Should allow new verifier to verify documents", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);
            await documentVerification.addVerifier(addr1.address);

            await expect(documentVerification.connect(addr1).verifyDocument(hash, true, ""))
                .to.emit(documentVerification, "DocumentVerified");

            const [,,,, exists, status, verifiers] = await documentVerification.getDocument(hash);

            expect(exists).to.be.true;
            expect(status).to.equal(1); // VerificationStatus.Approved
            expect(verifiers).to.include(addr1.address);
        });
    });

    describe("Gas Optimization Tests", function () {
        it("Should measure gas usage for document registration", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            const tx = await documentVerification.registerDocument(hash, title);
            const receipt = await tx.wait();
            
            console.log(`Gas used for document registration: ${receipt.gasUsed}`);
            expect(receipt.gasUsed).to.be.lessThan(200000); // Adjust threshold as needed
        });

        it("Should measure gas usage for document verification", async function () {
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);
            
            const tx = await documentVerification.verifyDocument(hash, true, "");
            const receipt = await tx.wait();
            
            console.log(`Gas used for document verification: ${receipt.gasUsed}`);
            expect(receipt.gasUsed).to.be.lessThan(100000); // Adjust threshold as needed
        });
    });

    describe("Security Tests", function () {
        it("Should not allow reentrancy attacks", async function () {
            // This is a basic test - in a real scenario, you would use a malicious contract
            const hash = "0xabcdef1234567890";
            const title = "Test Document";

            await documentVerification.registerDocument(hash, title);
            
            // Verify the document changes state before external calls
            const tx = await documentVerification.verifyDocument(hash, true, "");
            await tx.wait();
            
            // Try to verify again - should fail because state was already changed
            await expect(documentVerification.verifyDocument(hash, true, ""))
                .to.be.revertedWithCustomError(documentVerification, "VerificationCompleted");
        });

        it("Should protect admin functions", async function () {
            // Non-admin should not be able to add verifiers
            await expect(documentVerification.connect(addr1).addVerifier(addr2.address))
                .to.be.revertedWithCustomError(documentVerification, "NotAuthorizedVerifier");
                
            // Non-admin should not be able to remove verifiers
            await documentVerification.addVerifier(addr1.address);
            await expect(documentVerification.connect(addr2).removeVerifier(addr1.address))
                .to.be.revertedWithCustomError(documentVerification, "NotAuthorizedVerifier");
        });
    });
});