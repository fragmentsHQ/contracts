// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');

async function main () {
  
  //put the current proxy address for respective network here
  const currentProxyAddress = '0x0f6088c415F1569AC4c5C8B4F8C069aDe01E1B01'

  const FragmentsV2 = await ethers.getContractFactory('FragmentsV2');

  console.log('Upgrading Fragments...');
  await upgrades.upgradeProxy(currentProxyAddress, FragmentsV2);
  console.log('Fragments upgraded');

  const currentImplAddress = await getImplementationAddress(hre.network.provider, currentProxyAddress);
  
  console.log('New Implementation Contract Address:', currentImplAddress);
  
  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}

main();