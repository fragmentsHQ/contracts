// scripts/upgrade_box.js
const { ethers, upgrades } = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

async function upgradeConditionalGoerli() {
  //put the current proxy address for respective network here
  const currentProxyAddress = "0xDc7EcF12CFf43ea2d40Ad475b6BB0C5Fe6dD368A";

  const ConditionalV2 = await ethers.getContractFactory("Conditional");

  console.log("Upgrading Conditional...");
  await upgrades.upgradeProxy(currentProxyAddress, ConditionalV2, {
    kind: "uups",
  });
  console.log("Conditional upgraded");

  const currentImplAddress = await getImplementationAddress(
    hre.network.provider,
    currentProxyAddress
  );

  console.log("New Implementation Contract Address:", currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}

async function upgradeConditionalMumbai() {
  //put the current proxy address for respective network here
  const currentProxyAddress = "0x927CFeBA7c83f2626ca09A815Bce899190Cb5800";

  const ConditionalV2 = await ethers.getContractFactory("Conditional");

  console.log("Upgrading Conditional...");
  await upgrades.upgradeProxy(currentProxyAddress, ConditionalV2, {
    kind: "uups",
  });
  console.log("Conditional upgraded");

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
    upgradeConditionalGoerli();
  } else if (chainId == 80001) {
    upgradeConditionalMumbai();
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
