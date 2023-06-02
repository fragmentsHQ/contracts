// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');


async function upgradeConditional() {
    //put the current proxy address for respective network here
    const currentProxyAddress = '0x...'

    const ConditionalV2 = await ethers.getContractFactory('ConditionalV2');
  
    console.log('Upgrading Conditional...');
    await upgrades.upgradeProxy(currentProxyAddress, ConditionalV2);
    console.log('Conditional upgraded');
  
    const currentImplAddress = await getImplementationAddress(hre.network.provider, currentProxyAddress);
    
    console.log('New Implementation Contract Address:', currentImplAddress);
    
    await hre.run("verify:verify", {
      address: currentImplAddress,
    });
}

async function upgradeAutoPay() {
  //put the current proxy address for respective network here
  const currentProxyAddress = '0x0...'

  const AutopayV2 = await ethers.getContractFactory('AutopayV2');

  console.log('Upgrading Autopay...');
  await upgrades.upgradeProxy(currentProxyAddress, AutopayV2);
  console.log('Autopay upgraded');

  const currentImplAddress = await getImplementationAddress(hre.network.provider, currentProxyAddress);
  
  console.log('New Implementation Contract Address:', currentImplAddress);
  
  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}

async function upgradeXStream() {
  //put the current proxy address for respective network here
  const currentProxyAddress = '0x0...'

  const XStreamV2 = await ethers.getContractFactory('XStreamV2');

  console.log('Upgrading XStream...');
  await upgrades.upgradeProxy(currentProxyAddress, XStreamV2);
  console.log('XStream upgraded');

  const currentImplAddress = await getImplementationAddress(hre.network.provider, currentProxyAddress);
  
  console.log('New Implementation Contract Address:', currentImplAddress);
  
  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}


async function main () {
  upgradeConditional()
  upgradeAutoPay()
  upgradeXStream()
}

main();