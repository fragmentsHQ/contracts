// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IConnext} from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

import "./interfaces/AutomateTaskCreator.sol";
import "./interfaces/WETH9_.sol";
import "./interfaces/Treasury.sol";

contract AutoPay is AutomateTaskCreator {
    using SafeERC20 for IERC20;

    receive() external payable {}

    fallback() external payable {}

    uint256 public FEES;

    enum Option {
        TIME,
        PRICE_FEED,
        CONTRACT_VARIBLES,
        GAS_PRICE
    }

    event FundsDeposited(address indexed sender, address indexed token, uint256 indexed amount);
    event FundsWithdrawn(address indexed receiver, address indexed initiator, address indexed token, uint256 amount);

    IConnext public connext;
    ISwapRouter public swapRouter;

    address public constant WETH = 0xFD2AB41e083c75085807c4A65C0A14FDD93d55A9;

    struct user {
        address _user;
        uint256 _totalCycles;
        uint256 _executedCycles;
        bytes32 _gelatoTaskID;
    }

    mapping(bytes32 => user) public _createdJobs;
    mapping(address => mapping(address => uint256)) public userBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IConnext _connext, ISwapRouter _swapRouter, address payable _ops) public initializer {
        AutomateTaskCreator.ATC__initialize(_ops, msg.sender);

        connext = _connext;
        swapRouter = _swapRouter;
        FEES = 10000;

        __Ownable_init();
        __UUPSUpgradeable_init();
        // priceFeed = AggregatorV3Interface(chainLink);
    }
    ITreasury public treasury;

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source) {
        require(
            _origin == _originDomain && _originSender == _source && msg.sender == address(connext),
            "Expected original caller to be source contract on origin domain and this to be called by Connext"
        );
        _;
    }

    event JobCreated(
        address indexed taskCreator,
        address indexed execAddress,
        bytes32 indexed taskId,
        address token,
        uint256 amount,
        address receiver,
        uint256 inteval,
        Option option
    );

    event JobSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed execAddress,
        bytes execData,
        bytes32 taskId,
        bool callSuccess
    );

    event XTransferData(
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

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

 

    function xTransfer(
        address recipient,
        address destinationContract,
        uint32 destinationDomain,
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 slippage,
        uint256 relayerFeeInTransactingAsset
    ) internal {
        // This contract approves transfer to Connext
        IERC20(fromToken).approve(address(connext), amount);

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
    ) internal onlySource(_originSender, _origin, _origin, _originSender) returns (bytes memory) {
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

    function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn)
        internal
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

        // address payable recipient  = payable(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7);
        // WETH9_(WETH).withdraw(amountOut);
        // _recipient.transfer(amountOut);
    }

    function _cancelJob(bytes32 _jobId) public {
        user memory _userInfo = _createdJobs[_jobId];
        require(_userInfo._user != address(0), "No JOB Found");

        _cancelTask(_userInfo._gelatoTaskID);

        delete _createdJobs[_jobId];
    }

    // TIME AUTOMATE

    function _getWeb3FunctionHash(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) public view returns (bytes memory) {
        return (
            abi.encode(
                _from,
                _to,
                _amount,
                _fromToken,
                _toToken,
                block.chainid,
                _connextModule._toChain,
                connext.domain(),
                _connextModule._destinationDomain,
                address(this),
                _connextModule._destinationContract,
                _gelatoModule._cycles,
                _gelatoModule._startTime,
                _gelatoModule._interval
            )
        );
    }

    // string public _web3FunctionHash;

    // function updateWeb3FunctionHash(string memory _hash) external {
    //     _web3FunctionHash = _hash;
    // }

    function _gelatoTimeJobCreator(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule,
        bytes memory _web3FunctionArgsHex
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._timeAutomateCron.selector, _from, _to, _amount, _fromToken, _toToken, _connextModule, _gelatoModule
        );

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;
        moduleData.modules[2] = Module.WEB3_FUNCTION;

        moduleData.args[0] = _timeModuleArg(_gelatoModule._startTime, _gelatoModule._interval);
        moduleData.args[1] = _proxyModuleArg();
        moduleData.args[2] = _web3FunctionModuleArg(_gelatoModule._web3FunctionHash, _web3FunctionArgsHex);

        bytes32 id = _createTask(address(this), execData, moduleData, address(0));

        return id;
    }

    function _gelatoTimeJobCreator(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._timeAutomateCron.selector, _from, _to, _amount, _fromToken, _toToken, _connextModule, _gelatoModule
        );

        ModuleData memory moduleData;

        moduleData = ModuleData({modules: new Module[](2), args: new bytes[](2)});
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _timeModuleArg(_gelatoModule._startTime, _gelatoModule._interval);
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        return id;
    }

    /* 
    _cycles
        0 = infinite
        any number = number of cycles
    */

    struct connextModule {
        uint256 _toChain;
        uint32 _destinationDomain;
        address _destinationContract;
    }

    struct gelatoModule {
        uint256 _cycles;
        uint256 _startTime;
        uint256 _interval;
        string _web3FunctionHash;
    }

    struct token {
        address _fromToken;
        address _toToken;
    }

    error Allowance(uint256 allowance, uint256 amount, address token);

    function _createTimeAutomate(
        address _to,
        uint256 _amount,
        token memory _token,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) public {
        if (IERC20(_token._fromToken).allowance(msg.sender, address(this)) < _amount) {
            revert Allowance(IERC20(_token._fromToken).allowance(msg.sender, address(this)), _amount, _token._fromToken);
        }

        bytes memory _web3FunctionArgsHex = _getWeb3FunctionHash(
            msg.sender, _to, _amount, _token._fromToken, _token._toToken, _connextModule, _gelatoModule
        );

        bytes32 _id = _gelatoTimeJobCreator(
            msg.sender,
            _to,
            _amount,
            _token._fromToken,
            _token._toToken,
            _connextModule,
            _gelatoModule,
            _web3FunctionArgsHex
        );

        bytes32 _jobId = _getAutomateJobId(
            msg.sender, _to, _amount, _token._fromToken, _token._toToken, _connextModule, _gelatoModule
        );

        _createdJobs[_jobId] = user(msg.sender, _gelatoModule._cycles, 0, _id);

        emit JobCreated(
            address(this), msg.sender, _id, _token._fromToken, _amount, _to, _gelatoModule._interval, Option.TIME
            );
    }

    function _createMultipleTimeAutomate(
        address[] calldata _to,
        uint256[] calldata _amount,
        token[] calldata _token,
        connextModule[] calldata _connextModule,
        gelatoModule memory _gelatoModule
    ) external {
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                IERC20(_token[i]._fromToken).allowance(msg.sender, address(this)) >= _amount[i],
                "User must approve amount"
            );
            _createTimeAutomate(_to[i], _amount[i], _token[i], _connextModule[i], _gelatoModule);
        }
    }

    function _timeAutomateCron(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule,
        uint256 _relayerFeeInTransactingAsset
    ) external {
        require(IERC20(_fromToken).allowance(_from, address(this)) >= _amount, "User must approve amount");

        IERC20(_fromToken).transferFrom(_from, address(this), _amount);
        uint256 slippage = 300;

        uint256 amountOut = _amount;

        if (block.chainid == _connextModule._toChain && _fromToken != _toToken) {
            amountOut = swapExactInputSingle(_fromToken, _toToken, _amount);
            IERC20(_toToken).transferFrom(address(this), _to, amountOut);
        } else if (block.chainid != _connextModule._toChain) {
            xTransfer(
                _to,
                _connextModule._destinationContract,
                _connextModule._destinationDomain,
                _fromToken,
                _toToken,
                amountOut,
                slippage,
                _relayerFeeInTransactingAsset
            );
        } else {
            IERC20(_fromToken).transferFrom(address(this), _to, _amount);
        }

        bytes32 _jobId = _getAutomateJobId(_from, _to, _amount, _fromToken, _toToken, _connextModule, _gelatoModule);

        user memory userInfo = _createdJobs[_jobId];
        userInfo._executedCycles++;

        if (userInfo._executedCycles == userInfo._totalCycles) {
            _cancelJob(_jobId);
        }

        // (uint256 fee, address feeToken) = _getFeeDetails();
        // treasury.useFunds(userInfo._user, fee, feeToken);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    function _getAutomateJobId(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _from,
                _to,
                _amount,
                _gelatoModule._cycles,
                _gelatoModule._startTime,
                _gelatoModule._interval,
                _fromToken,
                _toToken,
                _connextModule._toChain,
                _connextModule._destinationContract,
                _connextModule._destinationDomain
            )
        );
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }
}
