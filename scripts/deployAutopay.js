


const hre = require("hardhat");
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');

const deployGoerli = async () => {
  const AutoPay = await hre.ethers.getContractFactory("AutoPay");
  const autoPay = await hre.upgrades.deployProxy(AutoPay, [
    "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649",
    "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0"],
    {
      kind: 'uups'
    }
  );

  await autoPay.deployed();

  console.log(
    `Deployed to ${autoPay.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, autoPay.address);

  console.log('Implementation Contract Address:', currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}


const deployzkEVM = async () => {
  const AutoPay = await hre.ethers.getContractFactory("AutoPay");
  const autoPay = await hre.upgrades.deployProxy(AutoPay, [
    "0x20b4789065DE09c71848b9A4FcAABB2c10006FA2"],
    {
      kind: 'uups'
    }
  );

  await autoPay.deployed();

  console.log(
    `Deployed to ${autoPay.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, autoPay.address);

  console.log('Implementation Contract Address:', currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}


const deployMumbai = async () => {
  const AutoPay = await hre.ethers.getContractFactory("AutoPay");
  const autoPay = await hre.upgrades.deployProxy(AutoPay, [
    "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a",
    "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
    "0xFD2AB41e083c75085807c4A65C0A14FDD93d55A9"
  ],
    {
      kind: 'uups'
    }
  );

  await autoPay.deployed();

  console.log(
    `Deployed to ${autoPay.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, autoPay.address);

  console.log('Implementation Contract Address:', currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}


const deployPolygon = async () => {
  const AutoPay = await hre.ethers.getContractFactory("AutoPay");
  const autoPay = await hre.upgrades.deployProxy(AutoPay, [
    "0x11984dc4465481512eb5b777E44061C158CF2259",
    "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"
  ],
    {
      kind: 'uups'
    }
  );

  await autoPay.deployed();

  console.log(
    `Deployed to ${autoPay.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, autoPay.address);

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
  } else if (chainId == 1442) {
    deployzkEVM();
  } else if (chainId == 137) {
    deployPolygon();
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
