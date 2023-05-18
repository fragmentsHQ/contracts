// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat"); 
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');

const deployGoerli = async () => {
  const Fragments = await hre.ethers.getContractFactory("Fragments");
  const fragments = await hre.upgrades.deployProxy(Fragments, [
  "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649",
  "0xE592427A0AEce92De3Edee1F18E0157C05861564",
  "0xc1C6805B857Bef1f412519C4A842522431aFed39"]);

  await fragments.deployed();
  

  console.log(
    `Deployed to ${fragments.address}`
  );

  const currentImplAddress = await getImplementationAddress(hre.network.provider, fragments.address);
  
  console.log('Implementation Contract Address:', currentImplAddress);
  
  await hre.run("verify:verify", {
    address: currentImplAddress,
  });

}

const deployMumbai = async () => {
  const Fragments = await hre.ethers.getContractFactory("Fragments");
  const fragments = await hre.upgrades.deployProxy(Fragments, [
  "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a",
  "0xE592427A0AEce92De3Edee1F18E0157C05861564",
  "0xB3f5503f93d5Ef84b06993a1975B9D21B962892F"]);

  await fragments.deployed();

  console.log(
    `Deployed to ${fragments.address}`
  );

  const currentImplAddress = await getImplementationAddress(hre.network.provider, fragments.address);
  
  console.log('Implementation Contract Address:', currentImplAddress);
  
  await hre.run("verify:verify", {
    address: currentImplAddress,
  });

}

async function main() {
  const chainId = hre.network.config.chainId;
  console.log(chainId);

  if (chainId == 5) {
    deployGoerli();
  } else if (chainId == 80001) {
    deployMumbai();
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
