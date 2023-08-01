// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../contracts/XStreamPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ISuperfluid,
    ISuperToken,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import "../contracts/interfaces/IConnext.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract XStreamPoolTest is XStreamPool, Test {
    XStreamPool public xStreamPool;

    function setUp() public {
        vm.startPrank(address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));

        XStreamPool impl = new XStreamPool();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        address payable proxyAddress = payable(address(proxy));
        xStreamPool = XStreamPool(proxyAddress);

        address payable _ops = payable(0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0);
        address _host = (0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9);
        address _cfa = (0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8);
        address _connext = (0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649);
        address _swapRouter = (0xE592427A0AEce92De3Edee1F18E0157C05861564);

        xStreamPool.initialize(_ops, _host, _cfa, _connext, _swapRouter, 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

        vm.stopPrank();
    }

    function test_createXStream() public {
        vm.startPrank(address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));

        uint256 _streamActionType = 1;
        address _receiver = 0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7;
        int96 _flowRate = 100;
        uint256 _relayerFeeInTransactingAsset = 10000000;
        uint256 _slippage = 500;
        uint256 _amount = 100;
        address _bridgingToken =0x7ea6eA49B0b0Ae9c5db7907d139D9Cd3439862a1;
        address _destinationSuperToken,
        address _destinationContract,
        uint32 _destinationDomain

        vm.stopPrank();
    }
}
