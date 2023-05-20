// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import {IConnext} from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

function xTransfer(
    address recipient,
    address destinationContract,
    uint32 destinationDomain,
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 slippage,
    uint256 relayerFeeInTransactingAsset
) public  {
    IERC20 token = IERC20(fromToken);
    // This contract approves transfer to Connext
    token.approve(address(connext), amount);

    bytes memory _callData = abi.encode(msg.sender, recipient, toToken);

    connext.xcall(
        destinationDomain, // _destination: Domain ID of the destination chain
        destinationContract, // _to: address receiving the funds on the destination
        fromToken, // _asset: address of the token contract
        msg.sender, // _delegate: address that can revert or forceLocal on destination
        amount - relayerFeeInTransactingAsset, // _amount: amount of tokens to transfer
        slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
        _callData, // _callData: empty because we're only sending funds
        relayerFeeInTransactingAsset
    );
}

function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
) external onlySource(_originSender, _origin, _origin, _originSender) returns (bytes memory) {
    address _sender;
    address _recipient;
    address _toToken;

    (_sender, _recipient, _toToken) = abi.decode(_callData, (address, address, address));

    uint256 amountOut = _amount;
    if (_asset != _toToken) {
        amountOut = swapExactInputSingle(_asset, _toToken, amountOut);
    }

    IERC20(_asset).transfer(_recipient, amountOut);
}