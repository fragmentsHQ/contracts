
const hre = require("hardhat");
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');

const deployGoerli = async () => {
  const Treasury = await hre.ethers.getContractFactory("Treasury");
  const treasury = await hre.upgrades.deployProxy(Treasury,
    {
      kind: 'uups'
    }
  );

  await treasury.deployed();

  console.log(
    `Deployed to ${treasury.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, treasury.address);

  console.log('Implementation Contract Address:', currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}


const deployMumbai = async () => {
  const Treasury = await hre.ethers.getContractFactory("Treasury");
  const treasury = await hre.upgrades.deployProxy(Treasury,
    {
      kind: 'uups'
    }
  );

  await treasury.deployed();

  console.log(
    `Deployed to ${treasury.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, treasury.address);

  console.log('Implementation Contract Address:', currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
}



const deployPolygon = async () => {
  const Treasury = await hre.ethers.getContractFactory("Treasury");
  const treasury = await hre.upgrades.deployProxy(Treasury,
    {
      kind: 'uups'
    }
  );

  await treasury.deployed();

  console.log(
    `Deployed to ${treasury.address}`
  );


  const currentImplAddress = await getImplementationAddress(hre.network.provider, treasury.address);

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
