// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.17;

import "hardhat/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IConnext} from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";

import {IConstantFlowAgreementV1} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    ISuperfluid,
    ISuperToken,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import "./interfaces/AutomateTaskCreator.sol";
import {IDestinationPool} from "./interfaces/IDestinationPool.sol";
import "./interfaces/IConnext.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error Unauthorized();
error InvalidAgreement();
error InvalidToken();
error StreamAlreadyActive();

/// @title Origin Pool to Receive Streams.
/// @notice This is a super app. On stream (create|update|delete), this contract sends a message
/// accross the bridge to the DestinationPool.

contract XStreamPool is SuperAppBase, IXReceiver, AutomateTaskCreator {
    using SafeERC20 for IERC20;
    using Strings for address;
    using Address for address;
    using Address for address payable;

    receive() external payable {}

    fallback() external payable {}

    /// @dev Emitted when flow message is sent across the bridge.
    /// @param flowRate Flow Rate, unadjusted to the pool.
    event FlowStartMessage(address indexed sender, address indexed receiver, int96 flowRate, uint256 startTime);
    event FlowTopupMessage(
        address indexed sender, address indexed receiver, int96 newFlowRate, uint256 topupTime, uint256 endTime
    );
    event FlowEndMessage(address indexed sender, address indexed receiver, int96 flowRate);

    event XStreamFlowTrigger(
        address indexed sender,
        address indexed receiver,
        address indexed selectedToken,
        int96 flowRate,
        uint256 amount,
        uint256 streamStatus,
        uint256 startTime,
        uint256 bufferFee,
        uint256 networkFee,
        uint32 destinationDomain
    );

    enum StreamOptions {
        START,
        TOPUP,
        END
    }

    /// @dev Emitted when rebalance message is sent across the bridge.
    /// @param amount Amount rebalanced (sent).
    event RebalanceMessageSent(uint256 amount);

    modifier isCallbackValid(address _agreementClass, ISuperToken _token) {
        if (msg.sender != address(host)) revert Unauthorized();
        if (_agreementClass != address(cfa)) revert InvalidAgreement();
        if (_token != superToken) revert InvalidToken();
        _;
    }

    IConnext public  connext;
    ISuperfluid public  host;
    IConstantFlowAgreementV1 public  cfa;
    ISuperToken public  superToken;
    IERC20 public erc20Token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(
        address payable _ops,
        address _host,
        address _cfa,
        address _connext,
        address _superToken,
        address _erc20Token
    ) public initializer  {

        AutomateTaskCreator.ATC__initialize(_ops, msg.sender);

        host = ISuperfluid(_host);
        cfa = IConstantFlowAgreementV1(_cfa);
        superToken = ISuperToken(_superToken);
        connext = IConnext(_connext);
        erc20Token = IERC20(_erc20Token);

        IERC20(superToken.getUnderlyingToken()).approve(address(connext), type(uint256).max);

        console.log("Address performing the approval", msg.sender);

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Rebalances pools. This sends funds over the bridge to the destination.
    function rebalance(uint32 destinationDomain, address destinationContract, uint256 relayerFeeInTransactingAsset)
        external
    {
        _sendRebalanceMessage(destinationDomain, destinationContract, relayerFeeInTransactingAsset);
    }


    function xTransfer(address _recipient, uint32 _originDomain, uint256 _amount, uint256 relayerFeeInTransactingAsset)
        internal
    {
        // This contract approves transfer to Connext
        erc20Token.approve(address(connext), _amount);

        uint256 _slippage = 300;
        uint256 remainingBalance = _amount - superToken.balanceOf(address(this));

        connext.xcall(
            _originDomain, // _destination: Domain ID of the destination chain
            _recipient, // _to: address receiving the funds on the destination
            address(erc20Token), // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            remainingBalance - relayerFeeInTransactingAsset, // _amount: amount of tokens to transfer
            _slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
            "" // _callData: empty because we're only sending funds
        );
    }

    function deleteStream(address account) external {
        bytes memory _callData = abi.encodeCall(cfa.deleteFlow, (superToken, address(this), account, new bytes(0)));

        host.callAgreement(cfa, _callData, new bytes(0));

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    function createTask(address _user, uint256 _interval, uint256 _startTime) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(this.deleteStream.selector, _user);

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});

        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;
        moduleData.modules[2] = Module.SINGLE_EXEC;

        moduleData.args[0] = _timeModuleArg(_startTime, _interval - 14400);
        moduleData.args[1] = _proxyModuleArg();
        moduleData.args[2] = _singleExecModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        return id;
    }

    // for streamActionType: 1 -> start stream, 2 -> Topup stream, 3 -> delete stream
    function _sendFlowMessage(
        uint256 _streamActionType,
        address _receiver,
        int96 _flowRate,
        uint256 relayerFeeInTransactingAsset,
        uint256 slippage,
        uint256 cost,
        address bridgingToken,
        address destinationContract,
        uint32 destinationDomain
    ) public {
        if (bridgingToken == address(superToken)) {
            // if user is sending Super Tokens
            ISuperToken(superToken).approve(address(this), type(uint256).max);
            superToken.transferFrom(msg.sender, address(this), cost); // here the sender is my wallet account, cost is the amount of TEST or TESTx tokens
                // supertokens won't be bridged, just the callData
        } else if (bridgingToken == address(erc20Token)) {
            // if user is sending ERC20 tokens
            IERC20(superToken.getUnderlyingToken()).approve(address(this), type(uint256).max);
            erc20Token.transferFrom(msg.sender, address(this), cost); // here the sender is my wallet account, cost is the amount of TEST or TESTx tokens
            erc20Token.approve(address(connext), cost); // approve the connext contracts to handle OriginPool's liquidity
        } else {
            revert("Send the correct token to bridge");
        }

        bytes memory callData = abi.encode(
            _streamActionType, msg.sender, _receiver, _flowRate, block.timestamp, relayerFeeInTransactingAsset
        );

        connext.xcall(
            destinationDomain, // _destination: Domain ID of the destination chain
            destinationContract, // _to: contract address receiving the funds on the destination chain
            address(bridgingToken), // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            cost - relayerFeeInTransactingAsset, // _amount: amount of tokens to transfer, // 0 if just sending a message
            slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
            callData, // _callData
            relayerFeeInTransactingAsset //relayerFeeInTransactingAsset
        );

        emit XStreamFlowTrigger(
            msg.sender,
            _receiver,
            address(bridgingToken),
            _flowRate,
            cost,
            1,
            block.timestamp,
            0,
            relayerFeeInTransactingAsset,
            destinationDomain
            );
    }

    function _sendToManyFlowMessage(
        address[] calldata receivers,
        int96[] calldata flowRates,
        uint96[] memory costs,
        uint256 _streamActionType,
        uint256 _relayerFee,
        uint256 slippage,
        address bridgingToken,
        address destinationContract,
        uint32 destinationDomain
    ) external {
        for (uint256 i = 0; i < receivers.length; i++) {
            _sendFlowMessage(
                _streamActionType,
                receivers[i],
                flowRates[i],
                _relayerFee,
                slippage,
                costs[i],
                bridgingToken,
                destinationContract,
                destinationDomain
            );
        }
    }

    /// @dev Sends rebalance message with the full balance of this pool. No need to collect dust.
    function _sendRebalanceMessage(
        uint32 destinationDomain,
        address destinationContract,
        uint256 relayerFeeInTransactingAsset
    ) internal {
        uint256 balance = superToken.balanceOf(address(this));
        // downgrade for sending across the bridge
        superToken.downgrade(balance);
        // encode call
        bytes memory callData = abi.encodeWithSelector(IDestinationPool.receiveRebalanceMessage.selector);

        connext.xcall(
            destinationDomain, // _destination: Domain ID of the destination chain
            destinationContract, // _to: contract address receiving the funds on the destination chain
            superToken.getUnderlyingToken(), // _asset: address of the token contract
            address(this), // _delegate: address that can revert or forceLocal on destination
            balance - relayerFeeInTransactingAsset, // _amount: amount of tokens to transfer
            300, // _slippage: the maximum amount of slippage the user will accept in BPS
            callData // _callData
        );
        emit RebalanceMessageSent(balance);
    }


    event StreamStart(address indexed sender, address receiver, int96 flowRate, uint256 startTime);
    event StreamUpdate(address indexed sender, address indexed receiver, int96 flowRate, uint256 startTime);

    event StreamDelete(address indexed sender, address indexed receiver);
    event XReceiveData(
        address indexed originSender,
        uint32 origin,
        address asset,
        uint256 amount,
        bytes32 transferId,
        uint256 receiveTimestamp,
        address senderAccount,
        address receiverAccount,
        int256 flowRate
    );

    // receive functions

    function receiveFlowMessage(
        address _account,
        int96 _flowRate,
        uint256 _amount,
        uint256 _startTime,
        uint256 _streamActionType
    ) internal {
        // if possible, upgrade all non-super tokens in the pool
        // uint256 balance = IERC20(token.getUnderlyingToken()).balanceOf(address(this));

        // if (balance > 0) token.upgrade(balance);

        (, int96 existingFlowRate,,) = cfa.getFlow(superToken, address(this), _account);

        bytes memory callData;

        if (_streamActionType == 1) {
            if (_flowRate == 0) return; // do not revert
            // create
            if (existingFlowRate == 0) {
                callData = abi.encodeCall(cfa.createFlow, (superToken, _account, _flowRate, new bytes(0)));

                /// @dev Gelato OPS is called here
                uint256 _interval = _amount / uint256(uint96(_flowRate));
                createTask(_account, _interval, _startTime);
            } else {
                callData = abi.encodeCall(cfa.updateFlow, (superToken, _account, _flowRate, new bytes(0)));
            }
        } else if (_streamActionType == 2) {
            // update
            callData = abi.encodeCall(cfa.updateFlow, (superToken, _account, _flowRate, new bytes(0)));
        } else if (_streamActionType == 3) {
            // delete
            callData = abi.encodeCall(cfa.deleteFlow, (superToken, address(this), _account, new bytes(0)));
        }

        host.callAgreement(cfa, callData, new bytes(0));
    
    }

    struct StreamInfo {
        uint256 streamActionType; // 1 -> Start stream, 2 -> Topup stream, 3 -> Delete stream
        address sender;
        address receiver;
        int96 flowRate;
        uint256 startTime;
        uint256 relayerFee;
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external returns (bytes memory) {
        // Unpack the _callData
        StreamInfo memory streamInfo;
        (
            streamInfo.streamActionType,
            streamInfo.sender,
            streamInfo.receiver,
            streamInfo.flowRate,
            streamInfo.startTime,
            streamInfo.relayerFee
        ) = abi.decode(_callData, (uint256, address, address, int96, uint256, uint256));

        emit XReceiveData(
            _originSender,
            _origin,
            _asset,
            _amount,
            _transferId,
            block.timestamp,
            streamInfo.sender,
            streamInfo.receiver,
            streamInfo.flowRate
            );
        approveSuperToken(address(_asset), _amount);
        receiveFlowMessage(
            streamInfo.receiver, streamInfo.flowRate, _amount, streamInfo.startTime, streamInfo.streamActionType
        );

        if (streamInfo.streamActionType == 1) {
            emit StreamStart(msg.sender, streamInfo.receiver, streamInfo.flowRate, streamInfo.startTime);
        } else if (streamInfo.streamActionType == 2) {
            emit StreamUpdate(streamInfo.sender, streamInfo.receiver, streamInfo.flowRate, streamInfo.startTime);
        } else {
            xTransfer(streamInfo.sender, _origin, _amount, streamInfo.relayerFee);

            emit StreamDelete(streamInfo.sender, streamInfo.receiver);
        }
    }

    event UpgradeToken(address indexed baseToken, uint256 amount);

    function approveSuperToken(address _asset, uint256 _amount) public {
        IERC20(_asset).approve(address(superToken), _amount); // approving the superToken contract to upgrade TEST
        ISuperToken(address(superToken)).upgrade(_amount);
        emit UpgradeToken(_asset, _amount);
    }
}
