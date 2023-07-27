// Import necessary libraries and dependencies
const { ethers } = require("hardhat");
const { expect } = require("chai");
require("dotenv").config();

const abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];

describe("AutoPay", function () {
  let contract;
  let accounts;
  let customAddress;

  // Deploy the contract before each test case
  beforeEach(async () => {
    accounts = await ethers.getSigners();

    const Contract = await ethers.getContractFactory("AutoPay");
    contract = await Contract.deploy();
    await contract.deployed();
  });

  // it("should get  a time automate hash", async function () {
  //     // Set up the test inputs
  //     const from = "0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7";
  //     const to = "0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7";
  //     const amount = "40000000000";
  //     const fromToken = "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747";
  //     const toToken = "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747";
  //     const toChain = 80001;
  //     const destinationContract = "0x7f464d4f3D46552F936cb68c21a0A2dB3E32919F";
  //     const destinationDomain = 9991;
  //     const cycles = 2;
  //     const startTime = 1685513100;
  //     const interval = 120;

  //     console.log("1");

  //     console.log("2");
  //     // Call the function
  //     const expectedHash = ethers.utils.defaultAbiCoder.encode(
  //         [
  //             "address",
  //             "address",
  //             "uint256",
  //             "address",
  //             "address",
  //             "uint256",
  //             "uint32",
  //             "address",
  //             "uint256",
  //             "uint256",
  //             "uint256",
  //         ],
  //         [
  //             from,
  //             to,
  //             amount,
  //             fromToken,
  //             toToken,
  //             80001,
  //             destinationDomain,
  //             destinationContract,
  //             cycles,
  //             startTime,
  //             interval,
  //         ]
  //     );

  //     console.log("3", expectedHash)

  //     const resultHash = await contract._getWeb3FunctionHash(
  //         from,
  //         to,
  //         amount,
  //         fromToken,
  //         toToken,
  //         toChain,
  //         destinationDomain,
  //         destinationContract,
  //         cycles,
  //         startTime,
  //         interval
  //     );

  //     expect(resultHash).to.equal(expectedHash);
  // });
  it("should create a scheduled time automate", async function () {
    // Set up the test inputs
    const _to = "0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7";
    const _amount = "40000000000";
    const _fromToken = "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747";
    const _toToken = "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747";
    const _toChain = 80001;
    const _destinationContract = "0x7f464d4f3D46552F936cb68c21a0A2dB3E32919F";
    const _destinationDomain = 9991;
    const _cycles = 2;
    const _startTime = 1685513100;
    const _interval = 120;

    console.log("1");

    // Approve the contract to spend fromToken on behalf of accounts[0]
    const fromTokenContract = await ethers.getContractAt(abi, _fromToken);
    await fromTokenContract.approve(contract.address, _amount);

    console.log("2");
    // Call the function
    const res = await contract._createTimeAutomate(
      _to,
      _amount,
      _fromToken,
      _toToken,
      _toChain,
      _destinationDomain,
      _destinationContract,
      _cycles,
      _startTime,
      _interval,
      "QmRDg82h63AP1ytAXFMaYKRE98ZjRjc21L9Ldbv3hnUmgh"
    );
    console.log("3", res);

    // Assert the expected results
    // Add assertions here based on the expected behavior of the function

    // Example assertion: Check if the scheduled automate was created correctly
    // const automate = await contract.getAutomate(); // Replace with the appropriate function to retrieve the automate details
    // expect(automate.to).to.equal(_to);
    // expect(automate.amount).to.equal(_amount);
    // expect(automate.fromToken).to.equal(_fromToken);
    // Add more assertions for other properties of the automate
  });
});
