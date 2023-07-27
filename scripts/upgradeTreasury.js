// scripts/upgrade_box.js
const { ethers, upgrades } = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

async function upgradeGoerli() {
  //put the current proxy address for respective network here
  const currentProxyAddress = "0x6e2b6959c81183dCe1EB5819E573092bee28511b";

  const TreasuryV2 = await ethers.getContractFactory("Treasury");

  console.log("Upgrading Treasury...");
  await upgrades.upgradeProxy(currentProxyAddress, TreasuryV2);
  console.log("Treasury upgraded");

  const currentImplAddress = await getImplementationAddress(
    hre.network.provider,
    currentProxyAddress
  );

  console.log("New Implementation Contract Address:", currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}

async function upgradeMumbai() {
  //put the current proxy address for respective network here
  const currentProxyAddress = "0x1Ff5C1D4713772C5AA17d551039d9599Bc65C31C";

  const TreasuryV2 = await ethers.getContractFactory("Treasury");

  console.log("Upgrading Treasury...");
  await upgrades.upgradeProxy(currentProxyAddress, TreasuryV2);
  console.log("Treasury upgraded");

  const currentImplAddress = await getImplementationAddress(
    hre.network.provider,
    currentProxyAddress
  );

  console.log("New Implementation Contract Address:", currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}

async function main() {
  const chainId = hre.network.config.chainId;
  console.log(chainId);

  if (chainId == 5) {
    upgradeGoerli();
  } else if (chainId == 80001) {
    upgradeMumbai();
  } else {
    upgradeGoerli();
    // upgradeMumbai();
  }
}

main();
