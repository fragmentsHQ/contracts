// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

import "./interfaces/OpsTaskCreator.sol";
import "./interfaces/WETH9_.sol";

contract Fragments is OpsTaskCreator {
    using SafeERC20 for IERC20;

    receive() external payable {}

    fallback() external payable {}

    uint256 public FEES;

    enum Option {
        TIME,
        PRICE_FEED,
        CONTRACT_VARIBLES
    }

    struct PRICE_FEED {
        address _to;
        uint256 _amount;
        int256 _price;
        address _fromToken;
        address _toToken;
        uint256 _toChain;
        uint32 destinationDomain;
        uint256 relayerFee;
    }

    struct TIME {
        address _to;
        uint256 _amount;
        uint256 _interval;
        address _fromToken;
        address _toToken;
        uint256 _toChain;
        uint32 destinationDomain;
        uint256 relayerFee;
    }

    event FundsDeposited(
        address indexed sender,
        address indexed token,
        uint256 indexed amount
    );
    event FundsWithdrawn(
        address indexed receiver,
        address indexed initiator,
        address indexed token,
        uint256 amount
    );

    IConnext public connext;
    ISwapRouter public swapRouter;

    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    mapping(bytes32 => address) internal _createdJobs;

    mapping(address => mapping(address => uint256)) public userBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IConnext _connext,
        ISwapRouter _swapRouter,
        address payable _ops
    ) public initializer {
        connext = _connext;
        swapRouter = _swapRouter;
        isTransferring = true;
        price = 100;
        FEES = 10000;
        // priceFeed = AggregatorV3Interface(chainLink);
        OpsTaskCreator.Ops__initialize(_ops, msg.sender);
    }

    // constructor(
    //     IConnext _connext,
    //     ISwapRouter _swapRouter,
    //     address payable _ops
    // ) OpsTaskCreator(_ops, msg.sender) {
    // connext = _connext;
    // swapRouter = _swapRouter;
    // // priceFeed = AggregatorV3Interface(chainLink);
    // }

    // function getLatestPrice() public view returns (int256) {
    //     (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
    //         priceFeed.latestRoundData();
    //     return price;
    // }

    bool public isTransferring;

    modifier isTransfer() {
        require(isTransferring == false, "already transferring!");
        _;
    }

    /**
     * @notice A modifier for authenticated calls.
     * This is an important security consideration. If the target contract
     * function should be authenticated, it must check three things:
     *    1) The originating call comes from the expected origin domain.
     *    2) The originating call comes from the expected source contract.
     *    3) The call to this contract comes from Connext.
     */
    modifier onlySource(
        address _originSender,
        uint32 _origin,
        uint32 _originDomain,
        address _source
    ) {
        require(
            _origin == _originDomain &&
                _originSender == _source &&
                msg.sender == address(connext),
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

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function xTransfer(
        address recipient,
        uint32 destinationDomain,
        address tokenAddress,
        uint256 amount,
        uint256 slippage,
        uint256 relayerFee
    ) public payable {
        IERC20 token = IERC20(tokenAddress);
        // This contract approves transfer to Connext
        token.approve(address(connext), amount);

        connext.xcall{value: relayerFee}(
            destinationDomain, // _destination: Domain ID of the destination chain
            recipient, // _to: address receiving the funds on the destination
            tokenAddress, // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            amount, // _amount: amount of tokens to transfer
            slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
            "" // _callData: empty because we're only sending funds
        );
    }

    /**
     * @notice Authenticated receiver function.
     * @param _callData Calldata containing the new greeting.
     */
    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    )
        external
        onlySource(_originSender, _origin, _origin, _originSender)
        returns (bytes memory)
    {
        // Unpack the _callData
    }

    function swapExactInputSingle(
        address _fromToken,
        address _toToken,
        uint256 amountIn
    ) public returns (uint256 amountOut) {
        uint24 poolFee = 500;
        TransferHelper.safeApprove(_fromToken, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
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

    // TIME AUTOMATE
    function _gelatoTimeJobCreator(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _interval,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._timeAutomateCron.selector,
            _from,
            _to,
            _amount,
            _interval,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee
        );

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _timeModuleArg(
            block.timestamp + _interval,
            _interval
        );
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        return id;
    }

    function _createTimeAutomate(
        address _to,
        uint256 _amount,
        uint256 _interval,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) external {
        require(
            IERC20(_fromToken).allowance(msg.sender, address(this)) >= _amount,
            "User must approve amount"
        );

        bytes32 _id = _gelatoTimeJobCreator(
            msg.sender,
            _to,
            _amount,
            _interval,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee
        );

        emit JobCreated(
            address(this),
            msg.sender,
            _id,
            _fromToken,
            _amount,
            _to,
            _interval,
            Option.TIME
        );
    }

    function _timeAutomateCron(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _interval,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) external {
        require(
            IERC20(_fromToken).allowance(_from, address(this)) >= _amount,
            "User must approve amount"
        );

        IERC20(_fromToken).transferFrom(_from, address(this), _amount);
        uint256 slippage = 300;

        uint256 amountOut = _amount;

        if (_fromToken != _toToken) {
            amountOut = swapExactInputSingle(_fromToken, _toToken, _amount);
        }
        if (block.chainid != _toChain) {
            xTransfer(
                _to,
                destinationDomain,
                WETH,
                amountOut,
                slippage,
                relayerFee
            );
        }

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    // PRICE FEED AUTOMATE
    function _gelatoPriceFeedJobCreator(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._priceFeedAutomateCron.selector,
            _from,
            _to,
            _amount,
            _price,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee
        );

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](3),
            args: new bytes[](3)
        });

        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;
        moduleData.modules[2] = Module.SINGLE_EXEC;

        moduleData.args[0] = _timeModuleArg(block.timestamp, 5);
        moduleData.args[1] = _proxyModuleArg();
        moduleData.args[2] = _singleExecModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        return id;
    }

    function _createPriceFeedAutomate(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) external {
        require(
            IERC20(_fromToken).allowance(_from, address(this)) >= _amount,
            "User must approve amount"
        );

        IERC20(_fromToken).transferFrom(msg.sender, address(this), _amount);

        bytes32 _id = _gelatoPriceFeedJobCreator(
            _from,
            _to,
            _amount,
            _price,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee
        );

        emit JobCreated(
            address(this),
            _from,
            _id,
            _fromToken,
            _amount,
            _to,
            block.timestamp,
            Option.PRICE_FEED
        );
    }

    error CONDITION_NOT_MET(int256, int256);

    int256 public price;

    function changePrice(int256 _price) public {
        price = _price;
    }

    function _priceFeedAutomateCron(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) public payable {
        // int price = getLatestPrice();
        if (price != _price) {
            revert CONDITION_NOT_MET(price, _price);
        }

        IERC20 token = IERC20(_fromToken);
        require(_amount > 0, "Amount must be greater than 0");
        require(_fromToken != _toToken, "From and To tokens must be different");
        require(_toChain > 0, "To chain must be greater than 0");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "User must approve amount"
        );

        // User sends funds to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 slippage = 300;

        uint256 amountOut = _amount;

        if (_fromToken != _toToken) {
            amountOut = swapExactInputSingle(_fromToken, _toToken, _amount);
        }
        if (block.chainid != _toChain) {
            xTransfer(
                _to,
                destinationDomain,
                WETH,
                amountOut,
                slippage,
                relayerFee
            );
        }

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    function _createContractAutomate(
        address exec,
        bytes calldata execData
    ) external {}

    function _transferGas(
        address payable _to,
        address _paymentToken,
        uint256 _amount
    ) external {
        (uint256 fee, address feeToken) = _getFeeDetails();

        payable(address(this)).transfer(fee);

        if (_paymentToken == ETH) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
        }
    }

    function depositGas(
        address payable _to,
        address _paymentToken,
        uint256 _amount
    ) external payable {
        if (_paymentToken == ETH) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
        }

        userBalance[_to][_paymentToken] =
            userBalance[_to][_paymentToken] +
            _amount;

        emit FundsDeposited(_to, _paymentToken, _amount);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    function getJobId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    taskCreator,
                    execAddress,
                    execSelector,
                    useTaskTreasuryFunds,
                    feeToken,
                    resolverHash
                )
            );
    }
}
