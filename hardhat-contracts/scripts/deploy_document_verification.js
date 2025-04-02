// Script to deploy the DocumentVerification contract to the Ganache network
const hre = require("hardhat");

async function main() {
  console.log("Deploying DocumentVerification contract...");

  // Get the deployer's account
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deploying with account: ${deployer.address}`);

  // Check deployer balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`Account balance: ${hre.ethers.formatEther(balance)} ETH`);

  // Deploy the contract
  const DocumentVerification = await hre.ethers.getContractFactory("DocumentVerification");
  const documentVerification = await DocumentVerification.deploy();

  // Wait for the contract to be deployed
  await documentVerification.waitForDeployment();

  // Get the contract address
  const contractAddress = await documentVerification.getAddress();
  console.log(`DocumentVerification deployed to: ${contractAddress}`);
  console.log("Save this address in your frontend application!");

  // Verify the deployer is set as admin and verifier
  const isVerifier = await documentVerification.isVerifier(deployer.address);
  const admin = await documentVerification.admin();
  
  console.log(`Deployer is admin: ${admin === deployer.address}`);
  console.log(`Deployer is verifier: ${isVerifier}`);

  // Output for easier access in the frontend
  console.log("\n--------- Configuration for Frontend ---------");
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Admin Address: ${deployer.address}`);
  console.log("----------------------------------------------\n");

  // Test document registration
  console.log("Testing document registration...");
  const documentHash = "0xabcdef1234567890";
  const documentTitle = "Test Document";
  
  const tx = await documentVerification.registerDocument(documentHash, documentTitle);
  await tx.wait();
  
  console.log("Document registered successfully!");
  
  // Get document details
  const document = await documentVerification.getDocument(documentHash);
  console.log("Document details:", {
    hash: document[0],
    title: document[1],
    owner: document[2],
    timestamp: document[3].toString(),
    exists: document[4],
    status: ["Pending", "Approved", "Rejected"][document[5]],
    verifiers: document[6],
    rejectionReason: document[7]
  });
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  }); 