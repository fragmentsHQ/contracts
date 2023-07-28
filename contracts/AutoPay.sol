// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import {IConnext} from "@connext/smart-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

import "./interfaces/AutomateTaskCreator.sol";
import "./interfaces/WETH9_.sol";
import "./interfaces/Treasury.sol";
import "./interfaces/IOpsProxy.sol";
import "./interfaces/IConnext.sol";

contract AutoPay is AutomateTaskCreator {
    using SafeERC20 for IERC20;
    using Strings for address;
    using Address for address;
    using Address for address payable;

    receive() external payable {}

    fallback() external payable {}

    uint256 public FEES;

    IConnext public connext;
    ISwapRouter public swapRouter;
    ITreasury public treasury;
    address public WETH;

    enum Option {
        TIME,
        PRICE_FEED,
        CONTRACT_VARIBLES,
        GAS_PRICE
    }

    struct user {
        address _user;
        uint256 _totalCycles;
        uint256 _executedCycles;
        bytes32 _gelatoTaskID;
    }

    mapping(bytes32 => user) public _createdJobs;
    mapping(Option => string) public _web3functionHashes;

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

    /**
     * @notice  .Modifier to check at only source contract calls an xcall to destination chain
     * @dev     .
     * @param   _originSender  . address of origin contract(address(this))
     * @param   _origin  . connext domain of source chain
     * @param   _originDomain  . connext domain of source chain
     * @param   _source  . contract address of origin contract passed as arguement
     */
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

    /**
     * @notice  .Initialise function called by the proxy when deployed
     * @dev     .
     * @param   _connext  . address of connext router
     * @param   _swapRouter  .address of uniswap router
     * @param   _ops  . address of gelato ops automate
     * @param   _WETH  . address of WETH contract
     */
    function initialize(IConnext _connext, ISwapRouter _swapRouter, address payable _ops, address _WETH)
        public
        initializer
    {
        AutomateTaskCreator.ATC__initialize(_ops, msg.sender);

        connext = _connext;
        swapRouter = _swapRouter;
        WETH = _WETH;
        FEES = 35;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice  . Function to check the ether(native) balance of the contract
     * @dev     .
     * @return  uint256  . balance in wei(native)
     */
    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice  . Function called to connext on source chain to transfer xcall and funds
     * @dev     .
     * @param   from  . address of the user who is sending the funds
     * @param   recipient  . address of the user who is receiving the funds
     * @param   destinationContract  . address of the contract on the destination chain
     * @param   destinationDomain  . connext domain of the destination chain
     * @param   fromToken  . address of the token to be sent
     * @param   toToken  . address of the token to be received
     * @param   amount  . amount of tokens to be sent
     * @param   slippage  . maximum slippage in BPS
     * @param   relayerFeeInTransactingAsset  . relayer fee in transacting asset
     */
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
    ) internal {
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
            destinationDomain,
            destinationContract,
            WETH,
            msg.sender,
            amountOut - relayerFeeInTransactingAsset,
            slippage,
            _callData,
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

    /**
     * @notice  .Function called to connext on destination chain to receive xcall and funds
     * @dev     .
     * @param   _transferId  . connext xcall unique transfer id
     * @param   _amount  . amount of asset recieved on the destination chain
     * @param   _asset  . address of token received
     * @param   _originSender  . address of source contract of AutoPay
     * @param   _origin  . domain of origin chain
     * @param   _callData  . calldata passed in xcall
     * @return  bytes  .
     */
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

    /**
     * @notice  . Function to swap assets using swapper and calldata
     * @dev     .
     * @param   _fromAsset  . token address of from token
     * @param   _toAsset  . token address of to token
     * @param   _amountIn  . amount of tokens to be swapped
     * @param   _swapper  . address of swapper router
     * @param   _swapData  . swapdata provider by swap APIs (1inch, 0x)
     * @return  amountOut  . amount of tokens recieved after swap
     */
    function _setupAndSwap(
        address _fromAsset,
        address _toAsset,
        uint256 _amountIn,
        address _swapper,
        bytes calldata _swapData
    ) internal returns (uint256 amountOut) {
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

    /**
     * @notice  . Function to swap on chain (uniswap v3, v2)
     * @dev     .
     * @param   _fromToken  . token address of from token
     * @param   _toToken  . token address of to token
     * @param   amountIn  . amount of tokens to be swapped
     * @return  amountOut  . amount of tokens recieved after swap
     */
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
    }

    /**
     * @notice  .Function called by taskcreator to cancel the job
     * @dev     .
     * @param   _jobId  . unique jobId created for each task
     */
    function _cancelJob(bytes32 _jobId) public {
        user storage _userInfo = _createdJobs[_jobId];
        require(_userInfo._user != address(0), "No JOB Found");
        require(_userInfo._user != msg.sender, "Not Authorised");

        _cancelTask(_userInfo._gelatoTaskID);

        delete _createdJobs[_jobId];
    }

    // TIME AUTOMATE

    /**
     * @notice  . Function to get the jobId for time automate
     * @dev     .
     * @param   _from  . address of the user who is sending the funds
     * @param   _to  . address of the user who is receiving the funds
     * @param   _amount  . amount of tokens to be sent
     * @param   _fromToken  . address of the token to be sent
     * @param   _toToken  . address of the token to be received
     * @param   _toChain  . chainId of the destination chain
     * @param   _destinationDomain  . connext domain of the destination chain
     * @param   _destinationContract  . address of the contract on the destination chain
     * @param   _cycles  . number of cycles to be executed
     * @param   _startTime  . time when the first cycle should be executed (unixtime in seconds)
     * @param   _interval  . time interval between each cycle (in seconds)
     * @return  bytes  . returns uniqure jobId (bytes32)
     */
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
            abi.encode( _from.toHexString(), _to.toHexString(), __amount, _fromToken.toHexString(), _toToken.toHexString(), block.chainid, _toChain, connext.domain(), _destinationDomain, address(this).toHexString(), _destinationContract.toHexString(), _cycles, _startTime, _interval, _isForwardPaying
            )
        );
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _startTime  .
     * @param   _interval  .
     * @param   _web3FunctionArgsHex  .
     * @return  bytes32  .
     */
    
    function _gelatoTimeJobCreator(
        uint256 _startTime,
        uint256 _interval,
        bytes memory _web3FunctionArgsHex
    ) internal returns (bytes32) {
        
        bytes memory execData = abi.encodeWithSelector(
            IOpsProxy.batchExecuteCall.selector
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

    /**
     * @notice  . Function to create a scheduled time automate
     * @dev     .
     * @param   _to  . address of the user who is receiving the funds
     * @param   _amount  . amount of tokens to be sent
     * @param   _fromToken  . address of the token to be sent
     * @param   _toToken  . address of the token to be received
     * @param   _toChain  . chainId of the destination chain
     * @param   _destinationDomain  . connext domain of the destination chain
     * @param   _destinationContract  . address of the contract on the destination chain
     * @param   _cycles  . number of cycles to be executed
     * @param   _startTime  . time when the first cycle should be executed (unixtime in seconds)
     * @param   _interval  . time interval between each cycle (in seconds)
     */
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

        bytes memory _web3FunctionArgsHex = _getWeb3FunctionHash( msg.sender, _to, _amount, _fromToken, _toToken, _toChain, _destinationDomain, _destinationContract, _cycles, _startTime, _interval, _isForwardPaying );

        bytes32 _id = _gelatoTimeJobCreator( _startTime, _interval, _web3FunctionArgsHex);

        bytes32 _jobId = _getAutomateJobId( msg.sender, _to, _amount, _fromToken, _toToken, _toChain, _destinationDomain, _destinationContract, _cycles, _startTime, _interval );

        _createdJobs[_jobId] = user(msg.sender, _cycles, 0, _id);

        emit JobCreated( msg.sender, _jobId, _id, _to, _amount, _fromToken, _toToken, _toChain, _destinationDomain, _destinationContract, _cycles, _startTime, _interval, _isForwardPaying, Option.TIME );
    }

    /**
     * @notice  . Function to create multiple scheduled time automates
     * @dev     .
     * @param   _to  . array of addresses of the user who is receiving the funds
     * @param   _amount  . array of amounts of tokens to be sent
     * @param   _fromToken  . array of addresses of the token to be sent
     * @param   _toToken  . array of addresses of the token to be received
     * @param   _toChain  . array of chainIds of the destination chain
     * @param   _destinationDomain  . array of connext domains of the destination chain
     * @param   _destinationContract  . array of addresses of the contract on the destination chain
     * @param   _cycles  . array of number of cycles to be executed
     * @param   _startTime  . array of times when the first cycle should be executed (unixtime in seconds)
     * @param   _interval  . array of time intervals between each cycle (in seconds)
     */
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
        bool isForwardPaying
    ) external {
        uint256 len = _to.length;

        for (uint256 i = 0; i < len; ++i) {
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
                isForwardPaying
            );
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _from  .
     * @param   _to  .
     * @param   _amount  .
     * @param   _fromToken  .
     * @param   _toToken  .
     * @param   _toChain  .
     * @param   _destinationDomain  .
     * @param   _destinationContract  .
     * @param   _cycles  .
     * @param   _startTime  .
     * @param   _interval  .
     * @param   _relayerFeeInTransactingAsset  .
     * @param   _swapper  .
     * @param   _swapData  .
     */
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
      
        uint256 slippage = 300;

        uint256 amountOut = _amount;

        if (block.chainid == _toChain && _fromToken != _toToken) {
            amountOut = _setupAndSwap(_fromToken, _toToken, _amount, _swapper, _swapData);
            // amountOut = swapExactInputSingle(_fromToken, _toToken, _amount);
            TransferHelper.safeTransfer(_toToken, _to, amountOut);
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
        }

        bytes32 _jobId = _getAutomateJobId( _from, _to, _amount, _fromToken, _toToken, _toChain, _destinationDomain, _destinationContract, _cycles, _startTime, _interval );

        user storage userInfo = _createdJobs[_jobId];
        require(userInfo._user != address(0), "NO JOB Found");
        userInfo._executedCycles++;

        if (userInfo._executedCycles == userInfo._totalCycles) {
            _cancelJob(_jobId);
        }

        uint256 gasRemaining2 = gasleft();

        uint256 gasConsumed = (gasRemaining - gasRemaining2) * tx.gasprice;
        gasConsumed = gasConsumed + (gasConsumed * FEES / 100);
        treasury.useFunds(ETH, gasConsumed, _from);

        emit ExecutedSourceChain(_jobId, _from, userInfo._executedCycles, gasConsumed, amountOut, _isForwardPaying);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _from  .
     * @param   _to  .
     * @param   _amount  .
     * @param   _fromToken  .
     * @param   _toToken  .
     * @param   _toChain  .
     * @param   _destinationDomain  .
     * @param   _destinationContract  .
     * @param   _cycles  .
     * @param   _startTime  .
     * @param   _interval  .
     * @return  bytes32  .
     */
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
            abi.encode( _from, _to, _amount, _fromToken, _toToken, _toChain, _destinationDomain, _destinationContract, _cycles, _startTime, _interval)
        );
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _treasury  .
     */
    function updateTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _types  .
     * @param   _hashes  .
     */
    function updateWeb3functionHashes(Option[] calldata _types, string[] calldata _hashes) external onlyOwner {
        for (uint256 i = 0; i < _types.length; i++) {
            _web3functionHashes[_types[i]] = _hashes[i];
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _fee  .
     */
    function updateFee(uint256 _fee) external onlyOwner {
        FEES = _fee;
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _gelatoTaskID  .
     */
    function _forceCancelGelato(bytes32 _gelatoTaskID) external onlyOwner {
        _cancelTask(_gelatoTaskID);
    }
}
