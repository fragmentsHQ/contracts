// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../contracts/AutoPay.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/interfaces/IConnext.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AutoPayTest is AutoPay, Test {
    AutoPay public autopay;

    function setUp() public {
        AutoPay impl = new AutoPay();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        address payable proxyAddress = payable(address(proxy));
        autopay = AutoPay(proxyAddress);

        IConnext _connext = IConnext(0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649);
        ISwapRouter _swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        address payable _ops = payable(0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0);

        autopay.initialize(_connext, _swapRouter, _ops, 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    }

    function testCreateTimeAutomate() public {
        vm.startPrank(address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));

        address _to = address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7);
        uint256 _amount = 100;
        address _fromToken = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        address _toToken = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        uint256 _toChain = 5;
        uint32 _destinationDomain = 5;
        address _destinationContract = address(0xA8e3315CE15cADdB4616AefD073e4CBF002C5D73);
        uint256 _cycles = 5;
        uint256 _startTime = block.timestamp + 3600;
        uint256 _interval = 86400;
        bool _isForwardPaying = true;

        IERC20(_fromToken).approve(address(autopay), _amount);

        bytes32 _jobId = autopay._getAutomateJobId(
            address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7),
            _to,
            _amount,
            _fromToken,
            _toToken,
            _toChain,
            _destinationDomain,
            _destinationContract,
            _cycles,
            _startTime,
            _interval
        );

        vm.expectEmit(true, true, true, false);

        emit JobCreated(
            address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7),
            _jobId,
            bytes32(0),
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
            _isForwardPaying,
            Option.TIME
        );

        autopay._createTimeAutomate(
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
            _isForwardPaying
        );

        (address _user, uint256 _totalCycles, uint256 _executedCycles, bytes32 _gelatoTaskID) = autopay._getJob(_jobId);

        assertEq(_user, address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));
        assertEq(_totalCycles, _cycles);
        assertEq(_executedCycles, 0);

        vm.stopPrank();
    }

    function testFuzzCreateTimeAutomate(
        address _to,
        uint256 _amount,
        // address _fromToken,
        // address _toToken,
        // uint256 _toChain,
        // uint32 _destinationDomain,
        // address _destinationContract,
        uint256 _cycles,
        uint256 _startTime,
        uint256 _interval,
        bool _isForwardPaying
    ) public {
        vm.startPrank(address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));

        // address _to = address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7);
        // uint256 _amount = 100;
        address _fromToken = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        address _toToken = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        uint256 _toChain = 5;
        uint32 _destinationDomain = 5;
        address _destinationContract = address(0xA8e3315CE15cADdB4616AefD073e4CBF002C5D73);
        // uint256 _cycles = 5;
        // uint256 _startTime = block.timestamp + 3600;
        // uint256 _interval = 86400;
        // bool _isForwardPaying = true;

        IERC20(_fromToken).approve(address(autopay), _amount);

        bytes32 _jobId = autopay._getAutomateJobId(
            address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7),
            _to,
            _amount,
            _fromToken,
            _toToken,
            _toChain,
            _destinationDomain,
            _destinationContract,
            _cycles,
            _startTime,
            _interval
        );

        vm.expectEmit(true, true, true, false);

        emit JobCreated(
            address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7),
            _jobId,
            bytes32(0),
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
            _isForwardPaying,
            Option.TIME
        );

        autopay._createTimeAutomate(
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
            _isForwardPaying
        );

        (address _user, uint256 _totalCycles, uint256 _executedCycles, bytes32 _gelatoTaskID) = autopay._getJob(_jobId);

        assertEq(_user, address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));
        assertEq(_totalCycles, _cycles);
        assertEq(_executedCycles, 0);

        vm.stopPrank();
    }

    function testFuzzCreateMultipleTimeAutomate(
        address[] calldata _to,
        uint256[] calldata _amount,
        uint256[] calldata _cycles,
        uint256[] calldata _startTime,
        uint256[] calldata _interval,
        bool _isForwardPaying
    ) public {
        vm.startPrank(address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));

        // address _to = address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7);
        // uint256 _amount = 100;
        address _fromToken = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        address _toToken = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        uint256 _toChain = 5;
        uint32 _destinationDomain = 5;
        address _destinationContract = address(0xA8e3315CE15cADdB4616AefD073e4CBF002C5D73);
        // uint256 _cycles = 5;
        // uint256 _startTime = block.timestamp + 3600;
        // uint256 _interval = 86400;
        // bool _isForwardPaying = true;

        for (uint256 i = 0; i < _to.length; i++) {
            IERC20(_fromToken).approve(address(autopay), _amount[i]);

            bytes32 _jobId = autopay._getAutomateJobId(
                address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7),
                _to[i],
                _amount[i],
                _fromToken,
                _toToken,
                _toChain,
                _destinationDomain,
                _destinationContract,
                _cycles[i],
                _startTime[i],
                _interval[i]
            );

            vm.expectEmit(true, true, true, false);

            emit JobCreated(
                address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7),
                _jobId,
                bytes32(0),
                _to[i],
                _amount[i],
                _fromToken,
                _toToken,
                _toChain,
                _destinationDomain,
                _destinationContract,
                _cycles[i],
                _startTime[i],
                _interval[i],
                _isForwardPaying,
                Option.TIME
            );

            autopay._createTimeAutomate(
                _to[i],
                _amount[i],
                _fromToken,
                _toToken,
                _toChain,
                _destinationDomain,
                _destinationContract,
                _cycles[i],
                _startTime[i],
                _interval[i],
                _isForwardPaying
            );

            (address _user, uint256 _totalCycles, uint256 _executedCycles, bytes32 _gelatoTaskID) =
                autopay._getJob(_jobId);

            assertEq(_user, address(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7));
            assertEq(_totalCycles, _cycles[i]);
            assertEq(_executedCycles, 0);
        }
        vm.stopPrank();
    }
}
