// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface WETH9_ {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";

import "./interfaces/OpsTaskCreator.sol";

contract Fragments is OpsTaskCreator {
    receive() external payable {}

    fallback() external payable {}

    uint256 public FEES = 10000;

    enum Option {
        TIME,
        PRICE_FEED,
        CONTRACT_VARIBLES
    }

    IConnext public connext;
    ISwapRouter public swapRouter;

    uint24 public constant poolFee = 500;
    uint256 public out;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    mapping(bytes32 => address) internal _createdJobs;

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
        // priceFeed = AggregatorV3Interface(chainLink);
        OpsTaskCreator.initialize(_ops, msg.sender);
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

    bool public isTransferring = false;

    modifier isTransfer() {
        require(isTransferring == false, "already transferring!");
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

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _gelatoTaskCreator(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _interval,
        address _receiver
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this._timeAutomateCron.selector,
            _user,
            _token,
            _amount,
            _receiver
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

    function createTask(
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
            this.executeLimitOrder.selector,
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

    function swapExactInputSingle(
        address _token,
        uint256 amountIn
    )
        public
        returns (
            // address payable _recipient
            uint256 amountOut
        )
    {
        TransferHelper.safeApprove(_token, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _token,
                tokenOut: WETH,
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

    function _createTimeAutomate(
        address _exec,
        uint256 _interval,
        address _token,
        uint256 _amount,
        address _receiver
    ) external {
        require(
            IERC20(_token).allowance(_exec, address(this)) >= _amount,
            "User must approve amount"
        );

        IERC20(_token).transfer(_exec, _amount);

        bytes32 _id = _gelatoTaskCreator(
            _exec,
            _token,
            _amount,
            _interval,
            _receiver
        );

        emit JobCreated(
            address(this),
            _exec,
            _id,
            _token,
            _amount,
            _receiver,
            _interval,
            Option.TIME
        );
    }

    function _createPriceFeedAutomate(
        address _exec,
        uint256 _interval,
        address _token,
        uint256 _amount,
        address _receiver
    ) external {
        require(
            IERC20(_token).allowance(_exec, address(this)) >= _amount,
            "User must approve amount"
        );

        IERC20(_token).transfer(_exec, _amount);

        bytes32 _id = _gelatoTaskCreator(
            _exec,
            _token,
            _amount,
            _interval,
            _receiver
        );

        emit JobCreated(
            address(this),
            _exec,
            _id,
            _token,
            _amount,
            _receiver,
            _interval,
            Option.TIME
        );
    }

    function _createContractAutomate(
        address exec,
        bytes calldata execData
    ) external {}

    function _timeAutomateCron(
        address _exec,
        address _token,
        uint256 _amount,
        address _receiver
    ) external {
        require(
            IERC20(_token).allowance(_exec, address(this)) >= _amount,
            "User must approve amount"
        );

        IERC20(_token).transferFrom(_exec, _receiver, _amount);

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    error CONDITION_NOT_MET(int, int);

    int256 public price = 100;

    function changePrice(int256 _price) public {
        price = _price;
    }

    function executeOrder(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee
    ) public payable {
        require(_amount > 0, "Amount must be greater than 0");
        require(_fromToken != _toToken, "From and To tokens must be different");
        require(_toChain > 0, "To chain must be greater than 0");

        // IERC20 token = IERC20(_fromToken);

        // require(
        //     token.allowance(msg.sender, address(this)) >= _amount,
        //     "User must approve amount"
        // );

        // User sends funds to this contract
        // token.transferFrom(msg.sender, address(this), _amount);

        uint256 slippage = 300;
        // token - weth

        uint256 amountOut = swapExactInputSingle(_fromToken, _amount);

        xTransfer(
            _to,
            destinationDomain,
            WETH,
            amountOut,
            slippage,
            relayerFee
        );

        // emit Action(
        //     DepositCounter,
        //     "Deposit CREATED & EXECUTED",
        //     true,
        //     _from,
        //     block.timestamp
        // );
    }

    function executeLimitOrder(
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

        executeOrder(
            _from,
            _to,
            _amount,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee
        );

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    function _transferGas() external {
        (uint256 fee, address feeToken) = _getFeeDetails();

        payable(address(this)).transfer(fee);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }
}
