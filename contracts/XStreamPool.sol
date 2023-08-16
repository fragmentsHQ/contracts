// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
import "./interfaces/WETH9_.sol";
import "./interfaces/Treasury.sol";
import "./interfaces/IOpsProxy.sol";
import "./interfaces/IConnext.sol";
import {IDestinationPool} from "./interfaces/IDestinationPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error Unauthorized();
error InvalidAgreement();
error InvalidToken();
error StreamAlreadyActive();

contract XStreamPool is SuperAppBase, IXReceiver, AutomateTaskCreator {
    using SafeERC20 for IERC20;
    using Strings for address;
    using Address for address;
    using Address for address payable;

    receive() external payable {}

    fallback() external payable {}

    IConnext public connext;
    ISwapRouter public swapRouter;
    ISuperfluid public host;
    IConstantFlowAgreementV1 public cfa;
    ITreasury public treasury;
    mapping(StreamOptions => string) public _web3functionHashes;
    address public WETH;

    struct user {
        address _user;
        int96 _flowRate;
        uint256 _startTime;
        uint256 _endTime;
        address _superToken;
        address _token;
        bytes32 _gelatoTaskID;
    }

    mapping(bytes32 => user) public _createdXStreams;
    mapping(address => bool) public _isTokenAllowed;

    enum StreamOptions {
        START,
        TOPUP,
        END
    }

    struct XStreamData {
        bytes32 _xStreamId;
        uint256 _streamActionType;
        address _sender;
        address _receiver;
        int96 _flowRate;
        uint256 _startTime;
        address _superToken;
        address _asset;
        uint256 _amount;
    }

    event FlowStartMessage(
        bytes32 indexed _xStreamId, address indexed sender, address indexed receiver, int96 flowRate, uint256 startTime
    );

    event FlowTopupMessage(
        bytes32 indexed _xStreamId,
        address indexed sender,
        address indexed receiver,
        int96 newFlowRate,
        uint256 topupTime,
        uint256 endTime
    );

    event FlowEndMessage(bytes32 indexed _xStreamId, address indexed sender, address indexed receiver, int96 flowRate);

    event XStreamFlowTrigger(
        bytes32 indexed _xStreamId,
        address indexed sender,
        address indexed receiver,
        address selectedToken,
        int96 flowRate,
        uint256 amount,
        uint256 streamStatus,
        uint256 startTime,
        uint256 bufferFee,
        uint256 networkFee,
        uint32 destinationDomain
    );

    event UpgradeToken(address indexed baseToken, uint256 amount);

    event StreamStart(
        bytes32 indexed _xStreamId, address indexed sender, address receiver, int96 flowRate, uint256 startTime
    );

    event StreamUpdate(
        bytes32 indexed _xStreamId, address indexed sender, address indexed receiver, int96 flowRate, uint256 startTime
    );

    event StreamDelete(bytes32 indexed _xStreamId, address indexed sender, address indexed receiver);

    event XReceiveData(
        bytes32 indexed _xStreamId,
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

    modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source) {
        require(
            _origin == _originDomain && _originSender == _source && msg.sender == address(connext),
            "Expected original caller to be source contract on origin domain and this to be called by Connext"
        );
        _;
    }

    error Allowance(uint256 allowance, uint256 amount, address token);
    error AmountLessThanRelayer(uint256 _amount, uint256 _relayerFeeInTransactingAsset);

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
        address _swapRouter,
        address _WETH
    ) public initializer {
        AutomateTaskCreator.ATC__initialize(_ops, msg.sender);

        host = ISuperfluid(_host);
        cfa = IConstantFlowAgreementV1(_cfa);
        connext = IConnext(_connext);
        swapRouter = ISwapRouter(_swapRouter);
        WETH = _WETH;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function xTransfer(
        bytes32 _xStreamId,
        address _from,
        address _receiver,
        address _destinationContract,
        uint32 _destinationDomain,
        address _bridgingToken,
        address _destinationSuperToken,
        uint256 _amount,
        uint256 _slippage,
        uint256 _relayerFeeInTransactingAsset,
        uint256 _streamActionType,
        int96 _flowRate
    ) public {
        uint256 amountOut;

        if (_bridgingToken != WETH) {
            amountOut = swapExactInputSingle(_bridgingToken, WETH, _amount);
        }

        if (_bridgingToken != address(0)) {
            if (IERC20(WETH).allowance(address(this), address(connext)) < amountOut + _relayerFeeInTransactingAsset) {
                TransferHelper.safeApprove(WETH, address(connext), amountOut + _relayerFeeInTransactingAsset);
            }
        }

        if (amountOut < _relayerFeeInTransactingAsset) {
            revert AmountLessThanRelayer(_amount, _relayerFeeInTransactingAsset);
        }
        

        bytes memory callData = abi.encode(
            _xStreamId,
            _streamActionType,
            _from,
            _receiver,
            _flowRate,
            block.timestamp,
            _amount,
            _relayerFeeInTransactingAsset,
            _destinationSuperToken
        );

        connext.xcall(
            _destinationDomain,
            _destinationContract,
            _bridgingToken,
            _from,
            _amount - _relayerFeeInTransactingAsset,
            _slippage,
            callData,
            _relayerFeeInTransactingAsset
        );
    }

    function xTransferFunds(
        address _recipient,
        uint32 _originDomain,
        uint256 _amount,
        uint256 _relayerFeeInTransactingAsset,
        address _bridgingToken,
        address _destinationSuperToken
    ) internal {
        // This contract approves transfer to Connext
        uint256 amountOut;

        if (_bridgingToken != WETH) {
            amountOut = swapExactInputSingle(_bridgingToken, WETH, _amount);
        }

        if (_bridgingToken != address(0)) {
            if (IERC20(WETH).allowance(address(this), address(connext)) < amountOut + _relayerFeeInTransactingAsset) {
                TransferHelper.safeApprove(WETH, address(connext), amountOut + _relayerFeeInTransactingAsset);
            }
        }

        if (amountOut < _relayerFeeInTransactingAsset) {
            revert AmountLessThanRelayer(_amount, _relayerFeeInTransactingAsset);
        }

        uint256 _slippage = 500;
        uint256 remainingBalance = _amount - ISuperToken(_destinationSuperToken).balanceOf(address(this));

        connext.xcall(
            _originDomain,
            _recipient,
            _bridgingToken,
            msg.sender,
            remainingBalance - _relayerFeeInTransactingAsset,
            _slippage,
            ""
        );
    }

    function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn)
        public
        returns (uint256 amountOut)
    {
        uint24 poolFee = 500;
        TransferHelper.safeApprove(_fromToken, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _fromToken,
            tokenOut: _toToken,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }

    function _getWeb3FunctionHash(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 _destinationDomain,
        address _destinationContract,
        uint256 _cycles,
        uint256 _startTime,
        uint256 _interval
    ) public view returns (bytes memory) {
        string memory __amount = Strings.toString(_amount);
        return (
            abi.encode(
                _from.toHexString(),
                _to.toHexString(),
                __amount,
                _fromToken.toHexString(),
                _toToken.toHexString(),
                block.chainid,
                _toChain,
                connext.domain(),
                _destinationDomain,
                address(this).toHexString(),
                _destinationContract.toHexString(),
                _cycles,
                _startTime,
                _interval
            )
        );
    }

    function _gelatoTimeJobCreator(uint256 _startTime, uint256 _interval, bytes memory _web3FunctionArgsHex)
        internal
        returns (bytes32)
    {
        bytes memory execData = abi.encodeWithSelector(IOpsProxy.batchExecuteCall.selector);

        string memory _web3FunctionHash = _web3functionHashes[StreamOptions.START];

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;
        moduleData.modules[2] = Module.WEB3_FUNCTION;

        moduleData.args[0] = _timeModuleArg(_startTime, _interval);
        moduleData.args[1] = _proxyModuleArg();
        moduleData.args[2] = _web3FunctionModuleArg(_web3FunctionHash, _web3FunctionArgsHex);

        bytes32 id = _createTask(address(this), execData, moduleData, address(0));

        return id;
    }

    function _gelatoTimeJobCreator(address _user, uint256 _interval, uint256 _startTime) internal returns (bytes32) {
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

    function deleteStream(address account, address _superToken) external {
        // user memory _userInfo = _createdXStreams[_jobId];
        // require(_userInfo._user != address(0), "No JOB Found");

        // delete _createdXStreams[_jobId];

        bytes memory _callData =
            abi.encodeCall(cfa.deleteFlow, (ISuperToken(_superToken), address(this), account, new bytes(0)));

        host.callAgreement(cfa, _callData, new bytes(0));

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    // for streamActionType: 1 -> start stream, 2 -> Topup stream, 3 -> delete stream
    function _createXStream(
        uint256 _streamActionType,
        address _receiver,
        int96 _flowRate,
        uint256 _relayerFeeInTransactingAsset,
        uint256 _slippage,
        uint256 _amount,
        address _bridgingToken,
        address _destinationSuperToken,
        address _destinationContract,
        uint32 _destinationDomain
    ) public {
        if (IERC20(_bridgingToken).allowance(msg.sender, address(this)) < _amount) {
            revert Allowance(IERC20(_bridgingToken).allowance(msg.sender, address(this)), _amount, _bridgingToken);
        }

        // IERC20(superToken.getUnderlyingToken()).approve(address(this), type(uint256).max);
        IERC20(_bridgingToken).transferFrom(msg.sender, address(this), _amount);

        bytes32 _xStreamId = _getXStreamJobId(
            _streamActionType,
            msg.sender,
            _receiver,
            _flowRate,
            block.timestamp,
            _destinationSuperToken,
            _bridgingToken,
            _amount
        );

        xTransfer(
            _xStreamId,
            msg.sender,
            _receiver,
            _destinationContract,
            _destinationDomain,
            _bridgingToken,
            _destinationSuperToken,
            _amount,
            _slippage,
            _relayerFeeInTransactingAsset,
            _streamActionType,
            _flowRate
        );

        _createdXStreams[_xStreamId] =
            user(msg.sender, _flowRate, block.timestamp, 0, _destinationSuperToken, _bridgingToken, 0);

        emit XStreamFlowTrigger(
            _xStreamId,
            msg.sender,
            _receiver,
            _bridgingToken,
            _flowRate,
            _amount - _relayerFeeInTransactingAsset,
            1,
            block.timestamp,
            0,
            _relayerFeeInTransactingAsset,
            _destinationDomain
        );
    }

    function _createMultipleXStream(
        address[] calldata _receivers,
        int96[] calldata _flowRates,
        uint96[] memory _amounts,
        uint256 _streamActionType,
        uint256 _relayerFee,
        uint256 _slippage,
        address _bridgingToken,
        address _destinationSuperToken,
        address _destinationContract,
        uint32 _destinationDomain
    ) external {
        uint256 len = _receivers.length;

        for (uint256 i = 0; i < len; ++i) {
            _createXStream(
                _streamActionType,
                _receivers[i],
                _flowRates[i],
                _relayerFee,
                _slippage,
                _amounts[i],
                _bridgingToken,
                _destinationSuperToken,
                _destinationContract,
                _destinationDomain
            );
        }
    }

    // receive functions

    function receiveFlowMessage(
        address _account,
        int96 _flowRate,
        uint256 _amount,
        uint256 _startTime,
        uint256 _streamActionType,
        address _superToken
    ) internal {
        // if possible, upgrade all non-super tokens in the pool
        // uint256 balance = IERC20(token.getUnderlyingToken()).balanceOf(address(this));

        // if (balance > 0) token.upgrade(balance);
        ISuperToken superToken = ISuperToken(_superToken);

        (, int96 existingFlowRate,,) = cfa.getFlow(superToken, address(this), _account);

        bytes memory callData;

        if (_streamActionType == 1) {
            if (_flowRate == 0) return; // do not revert
            // create
            if (existingFlowRate == 0) {
                callData = abi.encodeCall(cfa.createFlow, (superToken, _account, _flowRate, new bytes(0)));

                /// @dev Gelato OPS is called here
                uint256 _interval = _amount / uint256(uint96(_flowRate));
                _gelatoTimeJobCreator(_account, _interval, _startTime);
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

    // 1 -> Start stream, 2 -> Topup stream, 3 -> Delete stream

    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external returns (bytes memory) {
        (
            bytes32 _xStreamId,
            uint256 _streamActionType,
            address _sender,
            address _receiver,
            int96 _flowRate,
            uint256 _startTime,
            uint256 _relayerFee,
            address _superToken
        ) = abi.decode(_callData, (bytes32, uint256, address, address, int96, uint256, uint256, address));

        bytes32 _xStreamIdLocal = _getXStreamJobId(
            _streamActionType,
            msg.sender,
            _receiver,
            _flowRate,
            block.timestamp,
            _superToken,
            _asset,
            _amount
        );

        


        emit XReceiveData(
            _xStreamId,
            _originSender,
            _origin,
            _asset,
            _amount,
            _transferId,
            block.timestamp,
            _sender,
            _receiver,
            _flowRate
        );

        approveSuperToken(address(_asset), _amount, _superToken);
        receiveFlowMessage(_receiver, _flowRate, _amount, _startTime, _streamActionType, _superToken);

        if (_streamActionType == 1) {
            emit StreamStart(_xStreamId, msg.sender, _receiver, _flowRate, _startTime);
        } else if (_streamActionType == 2) {
            emit StreamUpdate(_xStreamId, _sender, _receiver, _flowRate, _startTime);
        } else {
            xTransferFunds(_sender, _origin, _amount, _relayerFee, _asset, _superToken);

            emit StreamDelete(_xStreamId, _sender, _receiver);
        }
    }

    function approveSuperToken(address _asset, uint256 _amount, address _superToken) public {
        IERC20(_asset).approve(_superToken, _amount); // approving the superToken contract to upgrade TEST
        ISuperToken(_superToken).upgrade(_amount);
        emit UpgradeToken(_asset, _amount);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }

    function updateWeb3functionHashes(StreamOptions[] calldata _types, string[] calldata _hashes) external onlyOwner {
        for (uint256 i = 0; i < _types.length; i++) {
            _web3functionHashes[_types[i]] = _hashes[i];
        }
    }

    function _getXStreamJobId(
        uint256 _streamActionType,
        address _sender,
        address _receiver,
        int96 _flowRate,
        uint256 _startTime,
        address _superToken,
        address _asset,
        uint256 _amount
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(_streamActionType, _sender, _receiver, _flowRate, _startTime, _superToken, _asset, _amount)
        );
    }
}
