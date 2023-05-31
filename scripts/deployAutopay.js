

const hre = require("hardhat"); 

const deployGoerli = async () => {
  const AutoPay = await hre.ethers.getContractFactory("AutoPay");
  const autoPay = await AutoPay.deploy(
    "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649",
    "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0"
  )

  await autoPay.deployed();

  console.log(
    `Deployed to ${autoPay.address}`
  );


  await hre.run("verify:verify", {
    address: autoPay.address,
    constructorArguments: [
      "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649",
      "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0"
    ],
  });
}


const deployMumbai = async () => {
  const AutoPay = await hre.ethers.getContractFactory("AutoPay");
  const autoPay = await AutoPay.deploy(
    "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a",
    "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0"
  )

  await autoPay.deployed();

  console.log(
    `Deployed to ${autoPay.address}`
  );

  await hre.run("verify:verify", {
    address: autoPay.address,
    constructorArguments: [
      "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a",
      "0xE592427A0AEce92De3Edee1F18E0157C05861564",
      "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0"
    ],
  });
}



async function main() {
  const chainId = hre.network.config.chainId;
  console.log(chainId);

  if (chainId == 5) {
    deployGoerli();
  } else if (chainId == 80001) {
    deployMumbai();
  } else if (chainId == 31337){
    deployGoerli();
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
