// test/autoPay.test.js
const { expect } = require("chai");

describe("AutoPay - Create Time Automate", function () {
    let autoPay;
    let owner;
    let user1;

    beforeEach(async () => {
        const AutoPay = await ethers.getContractFactory("AutoPay");
        [owner, user1] = await ethers.getSigners();

        const autoPay = await upgrades.deployProxy(AutoPay, [
            "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649",
            "0xE592427A0AEce92De3Edee1F18E0157C05861564",
            "0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0",
            "0xb4fbf271143f4fbf7b91a5ded31805e42b2208d6",
        ], { initializer: 'initialize', kind: 'uups' });

        await autoPay.deployed();
    });

    it("should create a scheduled time automate", async function () {
        // Set up test parameters
        const to = user1.address;
        const amount = ethers.utils.parseEther("1"); // 1 Ether
        const fromToken = ethers.constants.AddressZero; // Native token (ETH)
        const toToken = ethers.constants.AddressZero; // Native token (ETH)
        const toChain = 1; // Mainnet chain ID (example)
        const destinationDomain = 2; // Connext domain (example)
        const destinationContract = user1.address; // Destination contract address (example)
        const cycles = 5;
        const startTime = Math.floor(Date.now() / 1000) + 60; // Start after 1 minute from now
        const interval = 3600; // 1 hour interval
        const isForwardPaying = true;


        // Set user1 as the signer for the transaction
        const tokenContract = await ethers.getContractAt(
            "IERC20",
            fromToken,
            user1
        );

        // Make sure user1 approves AutoPay contract to spend the required amount of fromToken
        await tokenContract.approve(fromToken, amount);

        console.log(autoPay);

        // Create the time automate
        await autoPay._createTimeAutomate(
            to,
            amount,
            fromToken,
            toToken,
            toChain,
            destinationDomain,
            destinationContract,
            cycles,
            startTime,
            interval,
            isForwardPaying
        )

        // Verify that the created job is stored in the contract
        const jobId = await autoPay._getAutomateJobId(
            to,
            amount,
            fromToken,
            toToken,
            toChain,
            destinationDomain,
            destinationContract,
            cycles,
            startTime,
            interval
        );
        const job = await autoPay._createdJobs(jobId);
        expect(job._user).to.equal(user1.address);
        expect(job._totalCycles).to.equal(cycles);
        expect(job._executedCycles).to.equal(0);

        // Verify that the gelato task is created and stored in the contract
        const gelatoTaskId = job._gelatoTaskID;
        expect(gelatoTaskId).to.not.be.empty;

        // You may add more assertions based on your contract logic and requirements.
    });
});
