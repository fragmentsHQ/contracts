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

import "./interfaces/OpsTaskCreator.sol";
import "./interfaces/WETH9_.sol";

contract Conditional is OpsTaskCreator {
    using SafeERC20 for IERC20;

    receive() external payable {}

    fallback() external payable {}

    uint256 public FEES = 10000;

    enum Option {
        TIME,
        PRICE_FEED,
        CONTRACT_VARIBLES
    }

    event FundsDeposited(address indexed sender, address indexed token, uint256 indexed amount);
    event FundsWithdrawn(address indexed receiver, address indexed initiator, address indexed token, uint256 amount);

    IConnext public immutable connext;
    ISwapRouter public immutable swapRouter;

    address public constant WETH = 0xFD2AB41e083c75085807c4A65C0A14FDD93d55A9;

    struct user {
        address _user;
        uint256 _totalCycles;
        uint256 _executedCycles;
        bytes32 _gelatoTaskID;
    }

    mapping(bytes32 => user) public _createdJobs;
    mapping(address => mapping(address => uint256)) public userBalance;

    constructor(IConnext _connext, ISwapRouter _swapRouter, address payable _ops) OpsTaskCreator(_ops, msg.sender) {
        connext = _connext;
        swapRouter = _swapRouter;
        // priceFeed = AggregatorV3Interface(chainLink);
    }

    // function getLatestPrice() public view returns (int256) {
    //     (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
    //         priceFeed.latestRoundData();
    //     return price;
    // }

    bool public isTransferring = false;

    modifier isTransfer() {
        require(isTransferring == false, "already transferring!");
        _;
    }

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

        // address payable recipient  = payable(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7);
        // WETH9_(WETH).withdraw(amountOut);
        // _recipient.transfer(amountOut);
    }

    function _cancelJob(bytes32 _jobId) public {

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
        uint256 _relayerFeeInTransactingAsset;
    }

    struct gelatoModule {
        uint256 _cycles;
        uint256 _startTime;
        uint256 _interval;
    }

    // PRICE FEED AUTOMATE
    function _gelatoPriceFeedJobCreator(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price, 
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._priceFeedAutomateCron.selector,
            _from,
            _to,
            _amount,
            _price,
            _fromToken,
            _toToken,
            _connextModule,
            _gelatoModule
        );

        ModuleData memory moduleData = ModuleData({modules: new Module[](2), args: new bytes[](2)});

        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _timeModuleArg(_gelatoModule._startTime, 5);
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        return id;
    }

    error CONDITION_NOT_MET(int256, int256);
    int256 public price;
    function changePrice(int256 _price) public {
        price = _price;
    }


    function _createPriceFeedAutomate(
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) public {
        require(IERC20(_fromToken).allowance(msg.sender, address(this)) >= _amount, "User must approve amount");

        IERC20(_fromToken).transferFrom(msg.sender, address(this), _amount);

        bytes32 _id = _gelatoPriceFeedJobCreator(
                            msg.sender,
                            _to,
                            _amount,
                            _price,
                            _fromToken,
                            _toToken,
                             _connextModule,
                            _gelatoModule
                        );

        emit JobCreated(address(this), msg.sender, _id, _fromToken, _amount, _to, block.timestamp, Option.PRICE_FEED);
    }

    function _createMultiplePriceFeedAutomate(
        address[] calldata _to,
        uint256[] calldata _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    )  external {
        uint256 totalAmount;
        for (uint i = 0; i < _to.length; i++) {
            totalAmount += _amount[i];
        }

        require(IERC20(_fromToken).allowance(msg.sender, address(this)) >= totalAmount, "User must approve amount");

        for (uint i = 0; i < _to.length; i++) {
            _createPriceFeedAutomate(
                 _to[i],
                 _amount[i],
                 _price,
                 _fromToken,
                 _toToken,
                 _connextModule,
                 _gelatoModule
            ); 
        }
    }


    function _priceFeedAutomateCron(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        int256 _price, 
        connextModule memory _connextModule,
        gelatoModule memory _gelatoModule
    ) public payable {
        // int price = getLatestPrice();
        if (price != _price) {
            revert CONDITION_NOT_MET(price, _price);
        }

        IERC20 token = IERC20(_fromToken);
        require(_amount > 0, "Amount must be greater than 0");
        require(_fromToken != _toToken, "From and To tokens must be different");
        require(_connextModule._toChain > 0, "To chain must be greater than 0");
        require(token.allowance(msg.sender, address(this)) >= _amount, "User must approve amount");

        // User sends funds to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 slippage = 300;

        uint256 amountOut = _amount;

         if (_fromToken != _toToken && block.chainid == _connextModule._toChain) {
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
                _connextModule._relayerFeeInTransactingAsset
            );
        } else {
            IERC20(_fromToken).transferFrom(address(this), _to, _amount);
        }

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    function _createContractAutomate(address exec, bytes calldata execData) external {}

    function _transferGas(address payable _to, address _paymentToken, uint256 _amount) external {
        (uint256 fee, address feeToken) = _getFeeDetails();

        payable(address(this)).transfer(fee);

        if (_paymentToken == ETH) {
            (bool success,) = _to.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
        }
    }

    function depositGas(address payable _to, address _paymentToken, uint256 _amount) external payable {
        if (_paymentToken == ETH) {
            (bool success,) = _to.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
        }

        userBalance[_to][_paymentToken] = userBalance[_to][_paymentToken] + _amount;

        emit FundsDeposited(_to, _paymentToken, _amount);
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
        return
            keccak256(abi.encode(
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
                _connextModule._destinationDomain,
                _connextModule._relayerFeeInTransactingAsset
            ));
    }
}
