// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IConnext} from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

import "./interfaces/AutomateTaskCreator.sol";
import "./interfaces/WETH9_.sol";
import "./interfaces/Treasury.sol";

contract AutoPay is AutomateTaskCreator {
    using SafeERC20 for IERC20;
    using Strings for address;
    using Address for address;
    using Address for address payable;

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

    address public constant WETH = 0xFD2AB41e083c75085807c4A65C0A14FDD93d55A9; ///TODO TO BE UPDATED

    struct user {
        address _user;
        uint256 _totalCycles;
        uint256 _executedCycles;
        bytes32 _gelatoTaskID;
    }

    mapping(bytes32 => user) public _createdJobs;
    mapping(address => mapping(address => uint256)) public userBalance; ///TODO TO BE REMOVED

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
    }

    ITreasury public treasury;
    mapping(Option => string) public _web3functionHashes;
    mapping(uint8 => string) public _web3functionHashesNew;

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source) {
        require(
            _origin == _originDomain && _originSender == _source && msg.sender == address(connext),
            "Expected original caller to be source contract on origin domain and this to be called by Connext"
        );
        _;
    }

    event JobCreated(
        address indexed _taskCreator,
        bytes32 indexed _jobId,
        bytes32 _gelatoTaskId,
        address indexed _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 _destinationDomain,
        address _destinationContract,
        uint256 _cycles,
        uint256 _startTime,
        uint256 _interval,
        bool _isForwardPaying,
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
        address indexed fromToken,
        address toToken,
        address destinationContract,
        uint256 amount,
        uint256 startTime,
        uint256 relayerFeeInTransactingAsset,
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
        address receiverAccount
    );

     event ExecutedSourceChain(
        bytes32 indexed _jobId,
        address indexed _from,
        uint256 _timesExecuted,
        uint256 _fundsUsed,
        uint256 _amountOut,
        bool _isForwardPaying
    );

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    error AmountLessThanRelayer(uint256 _amount, uint256 _relayerFeeInTransactingAsset);

    function xTransfer(
        address from,
        address recipient,
        address destinationContract,
        uint32 destinationDomain,
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 slippage,
        uint256 relayerFeeInTransactingAsset
    ) public {
        uint256 amountOut;

        if (fromToken != WETH) {
            amountOut = swapExactInputSingle(fromToken, WETH, amount);
        }

        if (fromToken != address(0)) {
            if (IERC20(WETH).allowance(address(this), address(connext)) < amountOut + relayerFeeInTransactingAsset) {
                TransferHelper.safeApprove(WETH, address(connext), amountOut + relayerFeeInTransactingAsset);
            }
        }

        if (amountOut < relayerFeeInTransactingAsset) {
            revert AmountLessThanRelayer(amount, relayerFeeInTransactingAsset);
        }

        bytes memory _callData = abi.encode(from, recipient, toToken);

        connext.xcall(
            destinationDomain, // _destination: Domain ID of the destination chain
            destinationContract, // _to: address receiving the funds on the destination
            WETH, // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            amountOut - relayerFeeInTransactingAsset, // _amount: amount of tokens to transfer
            slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
            _callData, // _callData: empty because we're only sending funds
            relayerFeeInTransactingAsset
        );

        emit XTransferData(
            from,
            recipient,
            fromToken,
            toToken,
            destinationContract,
            amount,
            block.timestamp,
            relayerFeeInTransactingAsset,
            destinationDomain
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

        TransferHelper.safeTransfer(_asset, _recipient, amountOut);

        emit XReceiveData(_originSender, _origin, _asset, _amount, _transferId, block.timestamp, _sender, _recipient);
    }

    function directSwapperCall(address _swapper, bytes calldata swapData) public payable returns (uint256 amountOut) {
        bytes memory ret = _swapper.functionCallWithValue(swapData, msg.value, "!directSwapperCallFailed");
        amountOut = abi.decode(ret, (uint256));
    }

    function _setupAndSwap(
        address _fromAsset,
        address _toAsset,
        uint256 _amountIn,
        address _swapper,
        bytes calldata _swapData
    ) public returns (uint256 amountOut) {
        // TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);

        if (_fromAsset != _toAsset) {
            require(_swapper != address(0), "Swap: zero swapper!");

            // If fromAsset is not native and allowance is less than amountIn
            if (IERC20(_fromAsset).allowance(address(this), _swapper) < _amountIn) {
                TransferHelper.safeApprove(_fromAsset, _swapper, type(uint256).max);
            }

            amountOut = directSwapperCall(_swapper, _swapData);
        } else {
            amountOut = _amountIn;
        }
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
        uint256 _toChain,
        uint32 _destinationDomain,
        address _destinationContract,
        uint256 _cycles,
        uint256 _startTime,
        uint256 _interval,
        bool _isForwardPaying
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
                _interval,
                _isForwardPaying
            )
        );
    }

    function _gelatoTimeJobCreator(
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
        uint256 _interval,
        bool _isForwardPaying,
        bytes memory _web3FunctionArgsHex
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._timeAutomateCron.selector,
            _from,
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
            0,
            _isForwardPaying,
            address(0),
            bytes("")
        );

        
        string memory _web3FunctionHash = _web3functionHashes[Option.TIME];

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;
        moduleData.modules[2] = Module.WEB3_FUNCTION;

        moduleData.args[0] = _timeModuleArg(_startTime, _interval);
        moduleData.args[1] = _proxyModuleArg();
        moduleData.args[2] = _web3FunctionModuleArg(_web3FunctionHash, _web3FunctionArgsHex);

        bytes32 id = _createTask(dedicatedMsgSender, execData, moduleData, address(0));

        return id;
    }

    error Allowance(uint256 allowance, uint256 amount, address token);

    function _createTimeAutomate(
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 _destinationDomain,
        address _destinationContract,
        uint256 _cycles,
        uint256 _startTime,
        uint256 _interval,
        bool _isForwardPaying
    ) public {
        if (IERC20(_fromToken).allowance(msg.sender, address(this)) < _amount) {
            revert Allowance(IERC20(_fromToken).allowance(msg.sender, address(this)), _amount, _fromToken);
        }

        bytes memory _web3FunctionArgsHex = _getWeb3FunctionHash(
            msg.sender,
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

        bytes32 _id = _gelatoTimeJobCreator(
            msg.sender,
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
            _web3FunctionArgsHex
        );

        bytes32 _jobId = _getAutomateJobId(
            msg.sender,
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

        _createdJobs[_jobId] = user(msg.sender, _cycles, 0, _id);

        emit JobCreated(
            msg.sender,
            _jobId,
            _id,
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
    }

    function _createMultipleTimeAutomate(
        address[] calldata _to,
        uint256[] calldata _amount,
        address[] calldata _fromToken,
        address[] calldata _toToken,
        uint256[] calldata _toChain,
        uint32[] calldata _destinationDomain,
        address[] calldata _destinationContract,
        uint256[] calldata _cycles,
        uint256[] calldata _startTime,
        uint256[] calldata _interval,
        bool _isForwardPaying
    ) external {
        for (uint256 i = 0; i < _to.length; i++) {
            if (IERC20(_fromToken[i]).allowance(msg.sender, address(this)) < _amount[i]) {
                revert Allowance(IERC20(_fromToken[i]).allowance(msg.sender, address(this)), _amount[i], _fromToken[i]);
            }
            _createTimeAutomate(
                _to[i],
                _amount[i],
                _fromToken[i],
                _toToken[i],
                _toChain[i],
                _destinationDomain[i],
                _destinationContract[i],
                _cycles[i],
                _startTime[i],
                _interval[i],
                _isForwardPaying
            );
        }
    }

     function _timeAutomateCron(
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
        uint256 _interval,
        uint256 _relayerFeeInTransactingAsset,
        bool _isForwardPaying,
        address _swapper,
        bytes calldata _swapData
    ) public onlyDedicatedMsgSender {
        uint256 gasRemaining = gasleft();

        if (IERC20(_fromToken).allowance(_from, address(this)) < _amount) {
            revert Allowance(IERC20(_fromToken).allowance(_from, address(this)), _amount, _fromToken);
        }

        TransferHelper.safeTransferFrom(_fromToken, _from, address(this), _amount);
        // IERC20(_fromToken).transferFrom(_from, address(this), _amount);
        uint256 slippage = 300;

        uint256 amountOut = _amount;

        if (block.chainid == _toChain && _fromToken != _toToken) {
            amountOut = _setupAndSwap(_fromToken, _toToken, _amount, _swapper, _swapData);
            // amountOut = swapExactInputSingle(_fromToken, _toToken, _amount);
            TransferHelper.safeTransfer(_toToken, _to, amountOut);
            // IERC20(_toToken).transfer(_to, amountOut);
        } else if (block.chainid != _toChain) {
            xTransfer(
                _from,
                _to,
                _destinationContract,
                _destinationDomain,
                _fromToken,
                _toToken,
                amountOut,
                slippage,
                _relayerFeeInTransactingAsset
            );
        } else {
            TransferHelper.safeTransfer(_fromToken, _to, amountOut);
            // IERC20(_fromToken).transfer(_to, amountOut);
        }

        bytes32 _jobId = _getAutomateJobId(
            _from,
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

        user storage userInfo = _createdJobs[_jobId];
        require(userInfo._user != address(0), "NO JOB Found");
        userInfo._executedCycles++;

        if (userInfo._executedCycles == userInfo._totalCycles) {
            _cancelJob(_jobId);
        }

        uint256 gasRemaining2 = gasleft();

        uint256 gasConsumed = (gasRemaining - gasRemaining2) * tx.gasprice;
        gasConsumed = gasConsumed + (gasConsumed * FEES / 100);

        address _owner = treasury.owner();
        if(_isForwardPaying){
            treasury.depositFunds{value: gasConsumed}(_owner, ETH, gasConsumed);
        }else {
            treasury.useFunds(ETH, gasConsumed, _from);
        }

        emit ExecutedSourceChain(_jobId, _from, userInfo._executedCycles, gasConsumed, amountOut, _isForwardPaying);
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
        uint256 _toChain,
        uint32 _destinationDomain,
        address _destinationContract,
        uint256 _cycles,
        uint256 _startTime,
        uint256 _interval
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _from,
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
            )
        );
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }

    function updateWeb3functionHashes(Option[] calldata _types, string[] calldata _hashes) external onlyOwner {
        for (uint256 i = 0; i < _types.length; i++) {
            _web3functionHashes[_types[i]] = _hashes[i];
        }
    }

    function _forceCancelGelato(bytes32 _gelatoTaskID) external onlyOwner {
        _cancelTask(_gelatoTaskID);
    }
}