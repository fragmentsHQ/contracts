// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

const deployGoerli = async () => {
  const Conditional = await hre.ethers.getContractFactory("Conditional");
  const conditional = await hre.upgrades.deployProxy(
    Conditional,
    [
      "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649",
      "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
    ],
    {
      kind: "uups",
    }
  );

  await conditional.deployed();

  console.log(`Deployed to ${conditional.address}`);

  const currentImplAddress = await getImplementationAddress(
    hre.network.provider,
    conditional.address
  );

  console.log("Implementation Contract Address:", currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
};

const deployMumbai = async () => {
  const Conditional = await hre.ethers.getContractFactory("Conditional");
  const conditional = await hre.upgrades.deployProxy(
    Conditional,
    [
      "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a",
      "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
    ],
    {
      kind: "uups",
    }
  );

  await conditional.deployed();

  console.log(`Deployed to ${conditional.address}`);

  const currentImplAddress = await getImplementationAddress(
    hre.network.provider,
    conditional.address
  );

  console.log("Implementation Contract Address:", currentImplAddress);

  await hre.run("verify:verify", {
    address: currentImplAddress,
  });
};

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
