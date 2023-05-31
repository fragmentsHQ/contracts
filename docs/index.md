# Solidity API

## AutoPay

### receive

```solidity
receive() external payable
```

### fallback

```solidity
fallback() external payable
```

### FEES

```solidity
uint256 FEES
```

### Option

```solidity
enum Option {
  TIME,
  PRICE_FEED,
  CONTRACT_VARIBLES,
  GAS_PRICE
}
```

### FundsDeposited

```solidity
event FundsDeposited(address sender, address token, uint256 amount)
```

### FundsWithdrawn

```solidity
event FundsWithdrawn(address receiver, address initiator, address token, uint256 amount)
```

### connext

```solidity
contract IConnext connext
```

### swapRouter

```solidity
contract ISwapRouter swapRouter
```

### WETH

```solidity
address WETH
```

### user

```solidity
struct user {
  address _user;
  uint256 _totalCycles;
  uint256 _executedCycles;
  bytes32 _gelatoTaskID;
}
```

### _createdJobs

```solidity
mapping(bytes32 => struct AutoPay.user) _createdJobs
```

### userBalance

```solidity
mapping(address => mapping(address => uint256)) userBalance
```

### constructor

```solidity
constructor(contract IConnext _connext, contract ISwapRouter _swapRouter, address payable _ops) public
```

### isTransferring

```solidity
bool isTransferring
```

### isTransfer

```solidity
modifier isTransfer()
```

### onlySource

```solidity
modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source)
```

### JobCreated

```solidity
event JobCreated(address taskCreator, address execAddress, bytes32 taskId, address token, uint256 amount, address receiver, uint256 inteval, enum AutoPay.Option option)
```

### JobSuccess

```solidity
event JobSuccess(uint256 txFee, address feeToken, address execAddress, bytes execData, bytes32 taskId, bool callSuccess)
```

### XTransferData

```solidity
event XTransferData(address sender, address receiver, address selectedToken, int96 flowRate, uint256 amount, uint256 streamStatus, uint256 startTime, uint256 bufferFee, uint256 networkFee, uint32 destinationDomain)
```

### XReceiveData

```solidity
event XReceiveData(address originSender, uint32 origin, address asset, uint256 amount, bytes32 transferId, uint256 receiveTimestamp, address senderAccount, address receiverAccount, int256 flowRate)
```

### checkBalance

```solidity
function checkBalance() public view returns (uint256)
```

### xTransfer

```solidity
function xTransfer(address recipient, address destinationContract, uint32 destinationDomain, address fromToken, address toToken, uint256 amount, uint256 slippage, uint256 relayerFeeInTransactingAsset) internal
```

### xReceive

```solidity
function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes _callData) internal returns (bytes)
```

### swapExactInputSingle

```solidity
function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn) internal returns (uint256 amountOut)
```

### _cancelJob

```solidity
function _cancelJob(bytes32 _jobId) public
```

### _getWeb3FunctionHash

```solidity
function _getWeb3FunctionHash(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, struct AutoPay.connextModule _connextModule, struct AutoPay.gelatoModule _gelatoModule) public view returns (bytes)
```

### _gelatoTimeJobCreator

```solidity
function _gelatoTimeJobCreator(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, struct AutoPay.connextModule _connextModule, struct AutoPay.gelatoModule _gelatoModule, bytes _web3FunctionArgsHex) internal returns (bytes32)
```

### _gelatoTimeJobCreator

```solidity
function _gelatoTimeJobCreator(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, struct AutoPay.connextModule _connextModule, struct AutoPay.gelatoModule _gelatoModule) internal returns (bytes32)
```

### connextModule

```solidity
struct connextModule {
  uint256 _toChain;
  uint32 _destinationDomain;
  address _destinationContract;
}
```

### gelatoModule

```solidity
struct gelatoModule {
  uint256 _cycles;
  uint256 _startTime;
  uint256 _interval;
  string _web3FunctionHash;
}
```

### token

```solidity
struct token {
  address _fromToken;
  address _toToken;
}
```

### Allowance

```solidity
error Allowance(uint256 allowance, uint256 amount, address token)
```

### _createTimeAutomate

```solidity
function _createTimeAutomate(address _to, uint256 _amount, struct AutoPay.token _token, struct AutoPay.connextModule _connextModule, struct AutoPay.gelatoModule _gelatoModule) public
```

### _createMultipleTimeAutomate

```solidity
function _createMultipleTimeAutomate(address[] _to, uint256[] _amount, struct AutoPay.token[] _token, struct AutoPay.connextModule[] _connextModule, struct AutoPay.gelatoModule _gelatoModule) external
```

### _timeAutomateCron

```solidity
function _timeAutomateCron(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, struct AutoPay.connextModule _connextModule, struct AutoPay.gelatoModule _gelatoModule, uint256 _relayerFeeInTransactingAsset) external
```

### _transferGas

```solidity
function _transferGas(address payable _to, address _paymentToken, uint256 _amount) external
```

### depositGas

```solidity
function depositGas(address payable _to, address _paymentToken, uint256 _amount) external payable
```

### getBalanceOfToken

```solidity
function getBalanceOfToken(address _address) public view returns (uint256)
```

### _getAutomateJobId

```solidity
function _getAutomateJobId(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, struct AutoPay.connextModule _connextModule, struct AutoPay.gelatoModule _gelatoModule) public pure returns (bytes32)
```

## Conditional

### receive

```solidity
receive() external payable
```

### fallback

```solidity
fallback() external payable
```

### FEES

```solidity
uint256 FEES
```

### Option

```solidity
enum Option {
  TIME,
  PRICE_FEED,
  CONTRACT_VARIBLES
}
```

### FundsDeposited

```solidity
event FundsDeposited(address sender, address token, uint256 amount)
```

### FundsWithdrawn

```solidity
event FundsWithdrawn(address receiver, address initiator, address token, uint256 amount)
```

### connext

```solidity
contract IConnext connext
```

### swapRouter

```solidity
contract ISwapRouter swapRouter
```

### WETH

```solidity
address WETH
```

### user

```solidity
struct user {
  address _user;
  uint256 _totalCycles;
  uint256 _executedCycles;
  bytes32 _gelatoTaskID;
}
```

### _createdJobs

```solidity
mapping(bytes32 => struct Conditional.user) _createdJobs
```

### userBalance

```solidity
mapping(address => mapping(address => uint256)) userBalance
```

### constructor

```solidity
constructor(contract IConnext _connext, contract ISwapRouter _swapRouter, address payable _ops) public
```

### isTransferring

```solidity
bool isTransferring
```

### isTransfer

```solidity
modifier isTransfer()
```

### onlySource

```solidity
modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source)
```

### JobCreated

```solidity
event JobCreated(address taskCreator, address execAddress, bytes32 taskId, address token, uint256 amount, address receiver, uint256 inteval, enum Conditional.Option option)
```

### JobSuccess

```solidity
event JobSuccess(uint256 txFee, address feeToken, address execAddress, bytes execData, bytes32 taskId, bool callSuccess)
```

### XTransferData

```solidity
event XTransferData(address sender, address receiver, address selectedToken, int96 flowRate, uint256 amount, uint256 streamStatus, uint256 startTime, uint256 bufferFee, uint256 networkFee, uint32 destinationDomain)
```

### XReceiveData

```solidity
event XReceiveData(address originSender, uint32 origin, address asset, uint256 amount, bytes32 transferId, uint256 receiveTimestamp, address senderAccount, address receiverAccount, int256 flowRate)
```

### checkBalance

```solidity
function checkBalance() public view returns (uint256)
```

### xTransfer

```solidity
function xTransfer(address recipient, address destinationContract, uint32 destinationDomain, address fromToken, address toToken, uint256 amount, uint256 slippage, uint256 relayerFeeInTransactingAsset) public
```

### xReceive

```solidity
function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes _callData) external returns (bytes)
```

### swapExactInputSingle

```solidity
function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn) public returns (uint256 amountOut)
```

### _cancelJob

```solidity
function _cancelJob(bytes32 _jobId) public
```

### connextModule

```solidity
struct connextModule {
  uint256 _toChain;
  uint32 _destinationDomain;
  address _destinationContract;
  uint256 _relayerFeeInTransactingAsset;
}
```

### gelatoModule

```solidity
struct gelatoModule {
  uint256 _cycles;
  uint256 _startTime;
  uint256 _interval;
}
```

### _gelatoPriceFeedJobCreator

```solidity
function _gelatoPriceFeedJobCreator(address _from, address _to, uint256 _amount, int256 _price, address _fromToken, address _toToken, struct Conditional.connextModule _connextModule, struct Conditional.gelatoModule _gelatoModule) internal returns (bytes32)
```

### CONDITION_NOT_MET

```solidity
error CONDITION_NOT_MET(int256, int256)
```

### price

```solidity
int256 price
```

### changePrice

```solidity
function changePrice(int256 _price) public
```

### _createPriceFeedAutomate

```solidity
function _createPriceFeedAutomate(address _to, uint256 _amount, int256 _price, address _fromToken, address _toToken, struct Conditional.connextModule _connextModule, struct Conditional.gelatoModule _gelatoModule) public
```

### _createMultiplePriceFeedAutomate

```solidity
function _createMultiplePriceFeedAutomate(address[] _to, uint256[] _amount, int256 _price, address _fromToken, address _toToken, struct Conditional.connextModule _connextModule, struct Conditional.gelatoModule _gelatoModule) external
```

### _priceFeedAutomateCron

```solidity
function _priceFeedAutomateCron(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, int256 _price, struct Conditional.connextModule _connextModule, struct Conditional.gelatoModule _gelatoModule) public payable
```

### _createContractAutomate

```solidity
function _createContractAutomate(address exec, bytes execData) external
```

### _transferGas

```solidity
function _transferGas(address payable _to, address _paymentToken, uint256 _amount) external
```

### depositGas

```solidity
function depositGas(address payable _to, address _paymentToken, uint256 _amount) external payable
```

### getBalanceOfToken

```solidity
function getBalanceOfToken(address _address) public view returns (uint256)
```

### _getAutomateJobId

```solidity
function _getAutomateJobId(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, struct Conditional.connextModule _connextModule, struct Conditional.gelatoModule _gelatoModule) public pure returns (bytes32)
```

## Treasury

## Unauthorized

```solidity
error Unauthorized()
```

## InvalidAgreement

```solidity
error InvalidAgreement()
```

## InvalidToken

```solidity
error InvalidToken()
```

## StreamAlreadyActive

```solidity
error StreamAlreadyActive()
```

## XStreamPool

This is a super app. On stream (create|update|delete), this contract sends a message
accross the bridge to the DestinationPool.

### FlowStartMessage

```solidity
event FlowStartMessage(address sender, address receiver, int96 flowRate, uint256 startTime)
```

_Emitted when flow message is sent across the bridge._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address |  |
| receiver | address |  |
| flowRate | int96 | Flow Rate, unadjusted to the pool. |
| startTime | uint256 |  |

### FlowTopupMessage

```solidity
event FlowTopupMessage(address sender, address receiver, int96 newFlowRate, uint256 topupTime, uint256 endTime)
```

### FlowEndMessage

```solidity
event FlowEndMessage(address sender, address receiver, int96 flowRate)
```

### XStreamFlowTrigger

```solidity
event XStreamFlowTrigger(address sender, address receiver, address selectedToken, int96 flowRate, uint256 amount, uint256 streamStatus, uint256 startTime, uint256 bufferFee, uint256 networkFee, uint32 destinationDomain)
```

### StreamOptions

```solidity
enum StreamOptions {
  START,
  TOPUP,
  END
}
```

### RebalanceMessageSent

```solidity
event RebalanceMessageSent(uint256 amount)
```

_Emitted when rebalance message is sent across the bridge._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount rebalanced (sent). |

### isCallbackValid

```solidity
modifier isCallbackValid(address _agreementClass, contract ISuperToken _token)
```

### connext

```solidity
contract IConnext connext
```

### host

```solidity
contract ISuperfluid host
```

### cfa

```solidity
contract IConstantFlowAgreementV1 cfa
```

### superToken

```solidity
contract ISuperToken superToken
```

### erc20Token

```solidity
contract IERC20 erc20Token
```

### constructor

```solidity
constructor(address payable _ops, address _host, address _cfa, address _connext, address _superToken, address _erc20Token) public
```

### receive

```solidity
receive() external payable
```

### fallback

```solidity
fallback() external payable
```

### rebalance

```solidity
function rebalance(uint32 destinationDomain, address destinationContract, uint256 relayerFeeInTransactingAsset) external
```

_Rebalances pools. This sends funds over the bridge to the destination._

### xTransfer

```solidity
function xTransfer(address _recipient, uint32 _originDomain, uint256 _amount, uint256 relayerFeeInTransactingAsset) internal
```

### deleteStream

```solidity
function deleteStream(address account) external
```

### createTask

```solidity
function createTask(address _user, uint256 _interval, uint256 _startTime) internal returns (bytes32)
```

### _sendFlowMessage

```solidity
function _sendFlowMessage(uint256 _streamActionType, address _receiver, int96 _flowRate, uint256 relayerFeeInTransactingAsset, uint256 slippage, uint256 cost, address bridgingToken, address destinationContract, uint32 destinationDomain) public
```

### _sendToManyFlowMessage

```solidity
function _sendToManyFlowMessage(address[] receivers, int96[] flowRates, uint96[] costs, uint256 _streamActionType, uint256 _relayerFee, uint256 slippage, address bridgingToken, address destinationContract, uint32 destinationDomain) external
```

### _sendRebalanceMessage

```solidity
function _sendRebalanceMessage(uint32 destinationDomain, address destinationContract, uint256 relayerFeeInTransactingAsset) internal
```

_Sends rebalance message with the full balance of this pool. No need to collect dust._

### StreamStart

```solidity
event StreamStart(address sender, address receiver, int96 flowRate, uint256 startTime)
```

### StreamUpdate

```solidity
event StreamUpdate(address sender, address receiver, int96 flowRate, uint256 startTime)
```

### StreamDelete

```solidity
event StreamDelete(address sender, address receiver)
```

### XReceiveData

```solidity
event XReceiveData(address originSender, uint32 origin, address asset, uint256 amount, bytes32 transferId, uint256 receiveTimestamp, address senderAccount, address receiverAccount, int256 flowRate)
```

### receiveFlowMessage

```solidity
function receiveFlowMessage(address _account, int96 _flowRate, uint256 _amount, uint256 _startTime, uint256 _streamActionType) internal
```

### StreamInfo

```solidity
struct StreamInfo {
  uint256 streamActionType;
  address sender;
  address receiver;
  int96 flowRate;
  uint256 startTime;
  uint256 relayerFee;
}
```

### xReceive

```solidity
function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes _callData) external returns (bytes)
```

### UpgradeToken

```solidity
event UpgradeToken(address baseToken, uint256 amount)
```

### approveSuperToken

```solidity
function approveSuperToken(address _asset, uint256 _amount) public
```

## IDestinationPool

### receiveFlowMessage

```solidity
function receiveFlowMessage(address, int96, uint256, uint256) external
```

### receiveRebalanceMessage

```solidity
function receiveRebalanceMessage() external
```

## OpsReady

_Inherit this contract to allow your smart contract to
- Make synchronous fee payments.
- Have call restrictions for functions to be automated._

### ops

```solidity
contract IOps ops
```

### dedicatedMsgSender

```solidity
address dedicatedMsgSender
```

### ETH

```solidity
address ETH
```

### onlyDedicatedMsgSender

```solidity
modifier onlyDedicatedMsgSender()
```

@dev
Only tasks created by _taskCreator defined in constructor can call
the functions with this modifier.

### constructor

```solidity
constructor(address _ops, address _taskCreator) internal
```

@dev
_taskCreator is the address which will create tasks for this contract.

### _transfer

```solidity
function _transfer(uint256 _fee, address _feeToken) internal
```

@dev
Transfers fee to gelato for synchronous fee payments.

_fee & _feeToken should be queried from IOps.getFeeDetails()

### _getFeeDetails

```solidity
function _getFeeDetails() internal view returns (uint256 fee, address feeToken)
```

## OpsTaskCreator

_Inherit this contract to allow your smart contract
to be a task creator and create tasks._

### fundsOwner

```solidity
address fundsOwner
```

### taskTreasury

```solidity
contract ITaskTreasuryUpgradable taskTreasury
```

### gelato1Balance

```solidity
contract IGelato1Balance gelato1Balance
```

### constructor

```solidity
constructor(address _ops, address _fundsOwner) internal
```

### withdrawFunds

```solidity
function withdrawFunds(uint256 _amount, address _token) external
```

@dev
Withdraw funds from this contract's Gelato balance to fundsOwner.

### _depositFunds

```solidity
function _depositFunds(uint256 _amount, address _token) internal
```

### _depositFunds1Balance

```solidity
function _depositFunds1Balance(uint256 _amount, address _token, address _sponsor) internal
```

### _createTask

```solidity
function _createTask(address _execAddress, bytes _execDataOrSelector, struct ModuleData _moduleData, address _feeToken) internal returns (bytes32)
```

### _cancelTask

```solidity
function _cancelTask(bytes32 _taskId) internal
```

### _resolverModuleArg

```solidity
function _resolverModuleArg(address _resolverAddress, bytes _resolverData) internal pure returns (bytes)
```

### _timeModuleArg

```solidity
function _timeModuleArg(uint256 _startTime, uint256 _interval) internal pure returns (bytes)
```

### _proxyModuleArg

```solidity
function _proxyModuleArg() internal pure returns (bytes)
```

### _singleExecModuleArg

```solidity
function _singleExecModuleArg() internal pure returns (bytes)
```

### _web3FunctionModuleArg

```solidity
function _web3FunctionModuleArg(string _web3FunctionHash, bytes _web3FunctionArgsHex) internal pure returns (bytes)
```

## Module

```solidity
enum Module {
  RESOLVER,
  TIME,
  PROXY,
  SINGLE_EXEC,
  WEB3_FUNCTION
}
```

## ModuleData

```solidity
struct ModuleData {
  enum Module[] modules;
  bytes[] args;
}
```

## IOps

### createTask

```solidity
function createTask(address execAddress, bytes execDataOrSelector, struct ModuleData moduleData, address feeToken) external returns (bytes32 taskId)
```

### cancelTask

```solidity
function cancelTask(bytes32 taskId) external
```

### getFeeDetails

```solidity
function getFeeDetails() external view returns (uint256, address)
```

### gelato

```solidity
function gelato() external view returns (address payable)
```

### taskTreasury

```solidity
function taskTreasury() external view returns (contract ITaskTreasuryUpgradable)
```

## ITaskTreasuryUpgradable

### depositFunds

```solidity
function depositFunds(address receiver, address token, uint256 amount) external payable
```

### withdrawFunds

```solidity
function withdrawFunds(address payable receiver, address token, uint256 amount) external
```

## IOpsProxyFactory

### getProxyOf

```solidity
function getProxyOf(address account) external view returns (address, bool)
```

## IGelato1Balance

### depositNative

```solidity
function depositNative(address _sponsor) external payable
```

### depositToken

```solidity
function depositToken(address _sponsor, address _token, uint256 _amount) external
```

## WETH9_

### deposit

```solidity
function deposit() external payable
```

### withdraw

```solidity
function withdraw(uint256 wad) external
```

