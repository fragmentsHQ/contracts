// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

        IConnext _connext = IConnext(0x5Ea1bb242326044699C3d81341c5f535d5Af1504);
        ISwapRouter _swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        address payable _ops = payable(0x2501648Bf32e6ea8804d4603e3794f651CCEceC0);

        autopay.initialize(_connext, _swapRouter, _ops, 0x74c6FD7D2Bc6a8F0Ebd7D78321A95471b8C2B806);
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

        vm.stopPrank();
    }
}
