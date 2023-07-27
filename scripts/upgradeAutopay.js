// scripts/upgrade_box.js
const { ethers, upgrades } = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

async function upgradeAutoPayGoerli() {
  //put the current proxy address for respective network here
  const currentProxyAddress = "0xA8e3315CE15cADdB4616AefD073e4CBF002C5D73";

  const AutopayV2 = await ethers.getContractFactory("AutoPay");

  console.log("Upgrading Autopay...");
  await upgrades.upgradeProxy(currentProxyAddress, AutopayV2, {
    kind: "uups",
  });
  console.log("Autopay upgraded");

  const currentImplAddress = await getImplementationAddress(
    hre.network.provider,
    currentProxyAddress
  );

  console.log("New Implementation Contract Address:", currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}

async function upgradeAutoPayMumbai() {
  //put the current proxy address for respective network here
  const currentProxyAddress = "0x7f464d4f3d46552f936cb68c21a0a2db3e32919f";

  const AutopayV2 = await ethers.getContractFactory("AutoPay");

  console.log("Upgrading Autopay...");
  await upgrades.upgradeProxy(currentProxyAddress, AutopayV2, {
    kind: "uups",
  });
  console.log("Autopay upgraded");

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
    upgradeAutoPayGoerli();
  } else if (chainId == 80001) {
    upgradeAutoPayMumbai();
  } else {
    upgradeAutoPayGoerli();
    upgradeAutoPayMumbai();
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
