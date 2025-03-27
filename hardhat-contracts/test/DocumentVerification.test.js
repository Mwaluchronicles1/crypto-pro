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

        const [retrievedHash, retrievedTitle, ownerAddress, timestamp, exists, verified] =
            await documentVerification.getDocument(nonExistentHash);

        expect(retrievedHash).to.equal("");
        expect(retrievedTitle).to.equal("");
        expect(ownerAddress).to.equal(ethers.ZeroAddress); // Fix here
        expect(exists).to.be.false;
        expect(verified).to.be.false;
    });
});