// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const tagAddress ="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
const tagClassAddress ="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

async function deployEnvelopeContract():Promise<string>{
  const envelopeContract = await hre.ethers.getContractFactory("contracts/PigeonEnvelope.sol:PigeonEnvelope");
  const envelope = await envelopeContract.deploy( tagAddress,tagClassAddress);
  await envelope.deployed();
  console.log("PigeonEnvelope deployed to:", envelope.address)
  return envelope.address;
}

async function main() {
  await deployEnvelopeContract();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
