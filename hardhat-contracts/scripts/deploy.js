async function main() {
  // Get the contract factory
  const DocumentVerification = await ethers.getContractFactory("DocumentVerification");

  // Deploy the contract
  console.log("Deploying contract...");
  const contract = await DocumentVerification.deploy();

  // Wait for deployment to finish
  await contract.waitForDeployment();

  // Get the deployed contract address
  const address = await contract.getAddress();
  console.log("DocumentVerification deployed to:", address);
}

// Execute deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });