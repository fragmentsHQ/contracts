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

### connext

```solidity
contract IConnext connext
```

### swapRouter

```solidity
contract ISwapRouter swapRouter
```

### treasury

```solidity
contract ITreasury treasury
```

### WETH

```solidity
address WETH
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

### user

```solidity
struct user {
  address _user;
  uint256 _totalCycles;
  uint256 _executedCycles;
  bytes32 _gelatoTaskID;
}
```

### \_createdJobs

```solidity
mapping(bytes32 => struct AutoPay.user) _createdJobs
```

### \_web3functionHashes

```solidity
mapping(enum AutoPay.Option => string) _web3functionHashes
```

### JobCreated

```solidity
event JobCreated(address _taskCreator, bytes32 _jobId, bytes32 _gelatoTaskId, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, enum AutoPay.Option option)
```

### JobCreated

```solidity
event JobCreated(address _taskCreator, bytes32 _jobId, bytes32 _gelatoTaskId, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, enum AutoPay.Option option)
```

### JobSuccess

```solidity
event JobSuccess(uint256 txFee, address feeToken, address execAddress, bytes execData, bytes32 taskId, bool callSuccess)
```

### XTransferData

```solidity
event XTransferData(address sender, address receiver, address fromToken, address toToken, address destinationContract, uint256 amount, uint256 startTime, uint256 relayerFeeInTransactingAsset, uint32 destinationDomain)
```

### XReceiveData

```solidity
event XReceiveData(address originSender, uint32 origin, address asset, uint256 amount, bytes32 transferId, uint256 receiveTimestamp, address senderAccount, address receiverAccount)
```

### ExecutedSourceChain

```solidity
event ExecutedSourceChain(bytes32 _jobId, address _from, uint256 _timesExecuted, uint256 _fundsUsed, uint256 _amountOut)
```

### onlySource

```solidity
modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source)
```

.Modifier to check at only source contract calls an xcall to destination chain

_._

#### Parameters

| Name           | Type    | Description                                               |
| -------------- | ------- | --------------------------------------------------------- |
| \_originSender | address | . address of origin contract(address(this))               |
| \_origin       | uint32  | . connext domain of source chain                          |
| \_originDomain | uint32  | . connext domain of source chain                          |
| \_source       | address | . contract address of origin contract passed as arguement |

### Allowance

```solidity
error Allowance(uint256 allowance, uint256 amount, address token)
```

### AmountLessThanRelayer

```solidity
error AmountLessThanRelayer(uint256 _amount, uint256 _relayerFeeInTransactingAsset)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(contract IConnext _connext, contract ISwapRouter _swapRouter, address payable _ops, address _WETH) public
```

.Initialise function called by the proxy when deployed

_._

#### Parameters

| Name         | Type                 | Description                      |
| ------------ | -------------------- | -------------------------------- |
| \_connext    | contract IConnext    | . address of connext router      |
| \_swapRouter | contract ISwapRouter | .address of uniswap router       |
| \_ops        | address payable      | . address of gelato ops automate |
| \_WETH       | address              | . address of WETH contract       |

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

\_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

````solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### checkBalance

```solidity
function checkBalance() public view returns (uint256)
````

. Function to check the ether(native) balance of the contract

_._

#### Return Values

| Name | Type    | Description                      |
| ---- | ------- | -------------------------------- |
| [0]  | uint256 | uint256 . balance in wei(native) |

### xTransfer

```solidity
function xTransfer(address from, address recipient, address destinationContract, uint32 destinationDomain, address fromToken, address toToken, uint256 amount, uint256 slippage, uint256 relayerFeeInTransactingAsset) public
```

. Function called to connext on source chain to transfer xcall and funds

_._

#### Parameters

| Name                         | Type    | Description                                        |
| ---------------------------- | ------- | -------------------------------------------------- |
| from                         | address | . address of the user who is sending the funds     |
| recipient                    | address | . address of the user who is receiving the funds   |
| destinationContract          | address | . address of the contract on the destination chain |
| destinationDomain            | uint32  | . connext domain of the destination chain          |
| fromToken                    | address | . address of the token to be sent                  |
| toToken                      | address | . address of the token to be received              |
| amount                       | uint256 | . amount of tokens to be sent                      |
| slippage                     | uint256 | . maximum slippage in BPS                          |
| relayerFeeInTransactingAsset | uint256 | . relayer fee in transacting asset                 |

### xReceive

```solidity
function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes _callData) internal returns (bytes)
```

.Function called to connext on destination chain to receive xcall and funds

_._

#### Parameters

| Name           | Type    | Description                                         |
| -------------- | ------- | --------------------------------------------------- |
| \_transferId   | bytes32 | . connext xcall unique transfer id                  |
| \_amount       | uint256 | . amount of asset recieved on the destination chain |
| \_asset        | address | . address of token received                         |
| \_originSender | address | . address of source contract of AutoPay             |
| \_origin       | uint32  | . domain of origin chain                            |
| \_callData     | bytes   | . calldata passed in xcall                          |

#### Return Values

| Name | Type  | Description |
| ---- | ----- | ----------- |
| [0]  | bytes | bytes .     |

### directSwapperCall

```solidity
function directSwapperCall(address _swapper, bytes swapData) public payable returns (uint256 amountOut)
```

### \_setupAndSwap

```solidity
function _setupAndSwap(address _fromAsset, address _toAsset, uint256 _amountIn, address _swapper, bytes _swapData) public returns (uint256 amountOut)
```

. Function to swap assets using swapper and calldata

_._

#### Parameters

| Name        | Type    | Description                                  |
| ----------- | ------- | -------------------------------------------- |
| \_fromAsset | address | . token address of from token                |
| \_toAsset   | address | . token address of to token                  |
| \_amountIn  | uint256 | . amount of tokens to be swapped             |
| \_swapper   | address | . address of swapper router                  |
| \_swapData  | bytes   | . swapdata provider by swap APIs (1inch, 0x) |

#### Return Values

| Name      | Type    | Description                            |
| --------- | ------- | -------------------------------------- |
| amountOut | uint256 | . amount of tokens recieved after swap |

### swapExactInputSingle

```solidity
function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn) public returns (uint256 amountOut)
```

. Function to swap on chain (uniswap v3, v2)

_._

#### Parameters

| Name        | Type    | Description                      |
| ----------- | ------- | -------------------------------- |
| \_fromToken | address | . token address of from token    |
| \_toToken   | address | . token address of to token      |
| amountIn    | uint256 | . amount of tokens to be swapped |

#### Return Values

| Name      | Type    | Description                            |
| --------- | ------- | -------------------------------------- |
| amountOut | uint256 | . amount of tokens recieved after swap |

### \_cancelJob

```solidity
function _cancelJob(bytes32 _jobId) public
```

.Function called by taskcreator to cancel the job

_._

#### Parameters

| Name    | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| \_jobId | bytes32 | . unique jobId created for each task |

### \_getWeb3FunctionHash

```solidity
function _getWeb3FunctionHash(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public view returns (bytes)
```

. Function to get the jobId for time automate

_._

#### Parameters

| Name                  | Type    | Description                                                          |
| --------------------- | ------- | -------------------------------------------------------------------- |
| \_from                | address | . address of the user who is sending the funds                       |
| \_to                  | address | . address of the user who is receiving the funds                     |
| \_amount              | uint256 | . amount of tokens to be sent                                        |
| \_fromToken           | address | . address of the token to be sent                                    |
| \_toToken             | address | . address of the token to be received                                |
| \_toChain             | uint256 | . chainId of the destination chain                                   |
| \_destinationDomain   | uint32  | . connext domain of the destination chain                            |
| \_destinationContract | address | . address of the contract on the destination chain                   |
| \_cycles              | uint256 | . number of cycles to be executed                                    |
| \_startTime           | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| \_interval            | uint256 | . time interval between each cycle (in seconds)                      |

#### Return Values

| Name | Type  | Description                             |
| ---- | ----- | --------------------------------------- |
| [0]  | bytes | bytes . returns uniqure jobId (bytes32) |

### \_gelatoTimeJobCreator

```solidity
function _gelatoTimeJobCreator(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, string _web3FunctionHash, bytes _web3FunctionArgsHex) internal returns (bytes32)
```

.

_._

#### Parameters

| Name                  | Type    | Description |
| --------------------- | ------- | ----------- |
| \_from                | address | .           |
| \_to                  | address | .           |
| \_amount              | uint256 | .           |
| \_fromToken           | address | .           |
| \_toToken             | address | .           |
| \_toChain             | uint256 | .           |
| \_destinationDomain   | uint32  | .           |
| \_destinationContract | address | .           |
| \_cycles              | uint256 | .           |
| \_startTime           | uint256 | .           |
| \_interval            | uint256 | .           |
| \_web3FunctionHash    | string  | .           |
| \_web3FunctionArgsHex | bytes   | .           |

#### Return Values

| Name | Type    | Description |
| ---- | ------- | ----------- |
| [0]  | bytes32 | bytes32 .   |

### \_createTimeAutomate

```solidity
function _createTimeAutomate(address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public
```

. Function to create a scheduled time automate

_._

#### Parameters

| Name                  | Type    | Description                                                          |
| --------------------- | ------- | -------------------------------------------------------------------- |
| \_to                  | address | . address of the user who is receiving the funds                     |
| \_amount              | uint256 | . amount of tokens to be sent                                        |
| \_fromToken           | address | . address of the token to be sent                                    |
| \_toToken             | address | . address of the token to be received                                |
| \_toChain             | uint256 | . chainId of the destination chain                                   |
| \_destinationDomain   | uint32  | . connext domain of the destination chain                            |
| \_destinationContract | address | . address of the contract on the destination chain                   |
| \_cycles              | uint256 | . number of cycles to be executed                                    |
| \_startTime           | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| \_interval            | uint256 | . time interval between each cycle (in seconds)                      |

### \_createMultipleTimeAutomate

```solidity
function _createMultipleTimeAutomate(address[] _to, uint256[] _amount, address[] _fromToken, address[] _toToken, uint256[] _toChain, uint32[] _destinationDomain, address[] _destinationContract, uint256[] _cycles, uint256[] _startTime, uint256[] _interval) external
```

. Function to create multiple scheduled time automates

_._

#### Parameters

| Name                  | Type      | Description                                                                    |
| --------------------- | --------- | ------------------------------------------------------------------------------ |
| \_to                  | address[] | . array of addresses of the user who is receiving the funds                    |
| \_amount              | uint256[] | . array of amounts of tokens to be sent                                        |
| \_fromToken           | address[] | . array of addresses of the token to be sent                                   |
| \_toToken             | address[] | . array of addresses of the token to be received                               |
| \_toChain             | uint256[] | . array of chainIds of the destination chain                                   |
| \_destinationDomain   | uint32[]  | . array of connext domains of the destination chain                            |
| \_destinationContract | address[] | . array of addresses of the contract on the destination chain                  |
| \_cycles              | uint256[] | . array of number of cycles to be executed                                     |
| \_startTime           | uint256[] | . array of times when the first cycle should be executed (unixtime in seconds) |
| \_interval            | uint256[] | . array of time intervals between each cycle (in seconds)                      |

### \_timeAutomateCron

```solidity
function _timeAutomateCron(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, uint256 _relayerFeeInTransactingAsset, address _swapper, bytes _swapData) public
```

.

_._

#### Parameters

| Name                           | Type    | Description |
| ------------------------------ | ------- | ----------- |
| \_from                         | address | .           |
| \_to                           | address | .           |
| \_amount                       | uint256 | .           |
| \_fromToken                    | address | .           |
| \_toToken                      | address | .           |
| \_toChain                      | uint256 | .           |
| \_destinationDomain            | uint32  | .           |
| \_destinationContract          | address | .           |
| \_cycles                       | uint256 | .           |
| \_startTime                    | uint256 | .           |
| \_interval                     | uint256 | .           |
| \_relayerFeeInTransactingAsset | uint256 | .           |
| \_swapper                      | address | .           |
| \_swapData                     | bytes   | .           |

### \_getWeb3FunctionHash

```solidity
function _getWeb3FunctionHash(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, address _tokenA, address _tokenB, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public view returns (bytes)
```

.

_._

#### Parameters

| Name                  | Type    | Description |
| --------------------- | ------- | ----------- |
| \_from                | address | .           |
| \_to                  | address | .           |
| \_amount              | uint256 | .           |
| \_price               | uint256 | .           |
| \_fromToken           | address | .           |
| \_toToken             | address | .           |
| \_tokenA              | address | .           |
| \_tokenB              | address | .           |
| \_toChain             | uint256 | .           |
| \_destinationDomain   | uint32  | .           |
| \_destinationContract | address | .           |
| \_cycles              | uint256 | .           |
| \_startTime           | uint256 | .           |
| \_interval            | uint256 | .           |

#### Return Values

| Name | Type  | Description |
| ---- | ----- | ----------- |
| [0]  | bytes | bytes .     |

### \_gelatoConditionalJobCreator

```solidity
function _gelatoConditionalJobCreator(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, address _tokenA, address _tokenB, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, string _web3FunctionHash, bytes _web3FunctionArgsHex) internal returns (bytes32)
```

.

_._

#### Parameters

| Name                  | Type    | Description |
| --------------------- | ------- | ----------- |
| \_from                | address | .           |
| \_to                  | address | .           |
| \_amount              | uint256 | .           |
| \_price               | uint256 | .           |
| \_fromToken           | address | .           |
| \_toToken             | address | .           |
| \_tokenA              | address | .           |
| \_tokenB              | address | .           |
| \_toChain             | uint256 | .           |
| \_destinationDomain   | uint32  | .           |
| \_destinationContract | address | .           |
| \_cycles              | uint256 | .           |
| \_startTime           | uint256 | .           |
| \_interval            | uint256 | .           |
| \_web3FunctionHash    | string  | .           |
| \_web3FunctionArgsHex | bytes   | .           |

#### Return Values

| Name | Type    | Description |
| ---- | ------- | ----------- |
| [0]  | bytes32 | bytes32 .   |

### \_createConditionalAutomate

```solidity
function _createConditionalAutomate(address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, address _tokenA, address _tokenB, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, string _web3FunctionHash) public
```

.

_._

#### Parameters

| Name                  | Type    | Description |
| --------------------- | ------- | ----------- |
| \_to                  | address | .           |
| \_amount              | uint256 | .           |
| \_price               | uint256 | .           |
| \_fromToken           | address | .           |
| \_toToken             | address | .           |
| \_tokenA              | address | .           |
| \_tokenB              | address | .           |
| \_toChain             | uint256 | .           |
| \_destinationDomain   | uint32  | .           |
| \_destinationContract | address | .           |
| \_cycles              | uint256 | .           |
| \_startTime           | uint256 | .           |
| \_interval            | uint256 | .           |
| \_web3FunctionHash    | string  | .           |

### \_createMultipleConditionalAutomate

```solidity
function _createMultipleConditionalAutomate(address[] _to, uint256[] _amount, uint256[] _price, address[] _fromToken, address[] _toToken, address[] _tokenA, address[] _tokenB, uint256[] _toChain, uint32[] _destinationDomain, address[] _destinationContract, uint256[] _cycles, uint256[] _startTime, uint256[] _interval, string _web3FunctionHash) external
```

.

_._

#### Parameters

| Name                  | Type      | Description |
| --------------------- | --------- | ----------- |
| \_to                  | address[] | .           |
| \_amount              | uint256[] | .           |
| \_price               | uint256[] | .           |
| \_fromToken           | address[] | .           |
| \_toToken             | address[] | .           |
| \_tokenA              | address[] | .           |
| \_tokenB              | address[] | .           |
| \_toChain             | uint256[] | .           |
| \_destinationDomain   | uint32[]  | .           |
| \_destinationContract | address[] | .           |
| \_cycles              | uint256[] | .           |
| \_startTime           | uint256[] | .           |
| \_interval            | uint256[] | .           |
| \_web3FunctionHash    | string    | .           |

### \_conditionalAutomateCron

```solidity
function _conditionalAutomateCron(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, uint256 _relayerFeeInTransactingAsset, address _swapper, bytes _swapData) public
```

.

_._

#### Parameters

| Name                           | Type    | Description |
| ------------------------------ | ------- | ----------- |
| \_from                         | address | .           |
| \_to                           | address | .           |
| \_amount                       | uint256 | .           |
| \_price                        | uint256 | .           |
| \_fromToken                    | address | .           |
| \_toToken                      | address | .           |
| \_toChain                      | uint256 | .           |
| \_destinationDomain            | uint32  | .           |
| \_destinationContract          | address | .           |
| \_cycles                       | uint256 | .           |
| \_startTime                    | uint256 | .           |
| \_interval                     | uint256 | .           |
| \_relayerFeeInTransactingAsset | uint256 | .           |
| \_swapper                      | address | .           |
| \_swapData                     | bytes   | .           |

### \_transferGas

```solidity
function _transferGas() external payable
```

.

_._

### getBalanceOfToken

```solidity
function getBalanceOfToken(address _address) public view returns (uint256)
```

.

_._

#### Parameters

| Name      | Type    | Description |
| --------- | ------- | ----------- |
| \_address | address | .           |

#### Return Values

| Name | Type    | Description |
| ---- | ------- | ----------- |
| [0]  | uint256 | uint256 .   |

### \_getConditionalJobId

```solidity
function _getConditionalJobId(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public pure returns (bytes32)
```

.

_._

#### Parameters

| Name                  | Type    | Description |
| --------------------- | ------- | ----------- |
| \_from                | address | .           |
| \_to                  | address | .           |
| \_amount              | uint256 | .           |
| \_price               | uint256 | .           |
| \_fromToken           | address | .           |
| \_toToken             | address | .           |
| \_toChain             | uint256 | .           |
| \_destinationDomain   | uint32  | .           |
| \_destinationContract | address | .           |
| \_cycles              | uint256 | .           |
| \_startTime           | uint256 | .           |
| \_interval            | uint256 | .           |

#### Return Values

| Name | Type    | Description |
| ---- | ------- | ----------- |
| [0]  | bytes32 | bytes32 .   |

### \_getAutomateJobId

```solidity
function _getAutomateJobId(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public pure returns (bytes32)
```

.

_._

#### Parameters

| Name                  | Type    | Description |
| --------------------- | ------- | ----------- |
| \_from                | address | .           |
| \_to                  | address | .           |
| \_amount              | uint256 | .           |
| \_fromToken           | address | .           |
| \_toToken             | address | .           |
| \_toChain             | uint256 | .           |
| \_destinationDomain   | uint32  | .           |
| \_destinationContract | address | .           |
| \_cycles              | uint256 | .           |
| \_startTime           | uint256 | .           |
| \_interval            | uint256 | .           |

#### Return Values

| Name | Type    | Description |
| ---- | ------- | ----------- |
| [0]  | bytes32 | bytes32 .   |

### updateTreasury

```solidity
function updateTreasury(address _treasury) external
```

.

_._

#### Parameters

| Name       | Type    | Description |
| ---------- | ------- | ----------- |
| \_treasury | address | .           |

### updateWeb3functionHashes

```solidity
function updateWeb3functionHashes(enum AutoPay.Option[] _types, string[] _hashes) external
```

.

_._

#### Parameters

| Name     | Type                  | Description |
| -------- | --------------------- | ----------- |
| \_types  | enum AutoPay.Option[] | .           |
| \_hashes | string[]              | .           |

## AutomateReady

\_Inherit this contract to allow your smart contract to

- Make synchronous fee payments.
- Have call restrictions for functions to be automated.\_

### automate

```solidity
contract IAutomate automate
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
Only tasks created by \_taskCreator defined in constructor can call
the functions with this modifier.

### \_\_initialize

```solidity
function __initialize(address _automate, address _taskCreator) public
```

@dev
\_taskCreator is the address which will create tasks for this contract.

### \_transfer

```solidity
function _transfer(uint256 _fee, address _feeToken) internal
```

@dev
Transfers fee to gelato for synchronous fee payments.

\_fee & \_feeToken should be queried from IAutomate.getFeeDetails()

### \_getFeeDetails

```solidity
function _getFeeDetails() internal view returns (uint256 fee, address feeToken)
```

## AutomateTaskCreator

_Inherit this contract to allow your smart contract
to be a task creator and create tasks._

### fundsOwner

```solidity
address fundsOwner
```

### gelato1Balance

```solidity
contract IGelato1Balance gelato1Balance
```

### ATC\_\_initialize

```solidity
function ATC__initialize(address _automate, address _fundsOwner) public
```

### \_depositFunds1Balance

```solidity
function _depositFunds1Balance(uint256 _amount, address _token, address _sponsor) internal
```

### \_createTask

```solidity
function _createTask(address _execAddress, bytes _execDataOrSelector, struct ModuleData _moduleData, address _feeToken) internal returns (bytes32)
```

### \_cancelTask

```solidity
function _cancelTask(bytes32 _taskId) internal
```

### \_resolverModuleArg

```solidity
function _resolverModuleArg(address _resolverAddress, bytes _resolverData) internal pure returns (bytes)
```

### \_timeModuleArg

```solidity
function _timeModuleArg(uint256 _startTime, uint256 _interval) internal pure returns (bytes)
```

### \_proxyModuleArg

```solidity
function _proxyModuleArg() internal pure returns (bytes)
```

### \_singleExecModuleArg

```solidity
function _singleExecModuleArg() internal pure returns (bytes)
```

### \_web3FunctionModuleArg

```solidity
function _web3FunctionModuleArg(string _web3FunctionHash, bytes _web3FunctionArgsHex) internal pure returns (bytes)
```

## ITreasury

### FundsDeposited

```solidity
event FundsDeposited(address sender, address token, uint256 amount)
```

Events ///

### FundsWithdrawn

```solidity
event FundsWithdrawn(address receiver, address initiator, address token, uint256 amount)
```

### depositFunds

```solidity
function depositFunds(address receiver, address token, uint256 amount) external payable
```

External functions ///

### withdrawFunds

```solidity
function withdrawFunds(address payable receiver, address token, uint256 amount) external
```

### useFunds

```solidity
function useFunds(address token, uint256 amount, address user) external
```

### addWhitelistedService

```solidity
function addWhitelistedService(address service) external
```

### removeWhitelistedService

```solidity
function removeWhitelistedService(address service) external
```

### gelato

```solidity
function gelato() external view returns (address)
```

External view functions ///

### getCreditTokensByUser

```solidity
function getCreditTokensByUser(address user) external view returns (address[])
```

### getWhitelistedServices

```solidity
function getWhitelistedServices() external view returns (address[])
```

### userTokenBalance

```solidity
function userTokenBalance(address user, address token) external view returns (uint256)
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

## IAutomate

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

### taskModuleAddresses

```solidity
function taskModuleAddresses(enum Module) external view returns (address)
```

## IProxyModule

### opsProxyFactory

```solidity
function opsProxyFactory() external view returns (address)
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

## WETH9\_

### deposit

```solidity
function deposit() external payable
```

### withdraw

```solidity
function withdraw(uint256 wad) external
```

## Treasury

### userTokenBalance

```solidity
mapping(address => mapping(address => uint256)) userTokenBalance
```

### \_tokenCredits

```solidity
mapping(address => struct EnumerableSet.AddressSet) _tokenCredits
```

### \_whitelistedServices

```solidity
struct EnumerableSet.AddressSet _whitelistedServices
```

### FundsDeposited

```solidity
event FundsDeposited(address sender, address token, uint256 amount)
```

### FundsWithdrawn

```solidity
event FundsWithdrawn(address receiver, address initiator, address token, uint256 amount)
```

### onlyWhitelistedServices

```solidity
modifier onlyWhitelistedServices()
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

\_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

````solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### depositFunds

```solidity
function depositFunds(address _receiver, address _token, uint256 _amount) external payable
````

Function to deposit Funds which will be used to execute transactions on various services

#### Parameters

| Name       | Type    | Description                                    |
| ---------- | ------- | ---------------------------------------------- |
| \_receiver | address | Address receiving the credits                  |
| \_token    | address | Token to be credited, use "0xeeee...." for ETH |
| \_amount   | uint256 | Amount to be credited                          |

### withdrawFunds

```solidity
function withdrawFunds(address payable _receiver, address _token, uint256 _amount) external
```

Function to withdraw Funds back to the \_receiver

#### Parameters

| Name       | Type            | Description                                    |
| ---------- | --------------- | ---------------------------------------------- |
| \_receiver | address payable | Address receiving the credits                  |
| \_token    | address         | Token to be credited, use "0xeeee...." for ETH |
| \_amount   | uint256         | Amount to be credited                          |

### useFunds

```solidity
function useFunds(address _token, uint256 _amount, address _user) external
```

Function called by whitelisted services to handle payments, e.g. Ops"

#### Parameters

| Name     | Type    | Description                                    |
| -------- | ------- | ---------------------------------------------- |
| \_token  | address | Token to be used for payment by users          |
| \_amount | uint256 | Amount to be deducted                          |
| \_user   | address | Address of user whose balance will be deducted |

### addWhitelistedService

```solidity
function addWhitelistedService(address _service) external
```

Add new service that can call useFunds. Gelato Governance

#### Parameters

| Name      | Type    | Description        |
| --------- | ------- | ------------------ |
| \_service | address | New service to add |

### removeWhitelistedService

```solidity
function removeWhitelistedService(address _service) external
```

Remove old service that can call useFunds. Gelato Governance

#### Parameters

| Name      | Type    | Description           |
| --------- | ------- | --------------------- |
| \_service | address | Old service to remove |

### getCreditTokensByUser

```solidity
function getCreditTokensByUser(address _user) external view returns (address[])
```

Helper func to get all deposited tokens by a user

#### Parameters

| Name   | Type    | Description                   |
| ------ | ------- | ----------------------------- |
| \_user | address | User to get the balances from |

### getWhitelistedServices

```solidity
function getWhitelistedServices() external view returns (address[])
```

## ETH

```solidity
address ETH
```

## \_transfer

```solidity
function _transfer(address payable _to, address _paymentToken, uint256 _amount) internal
```

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

### receive

```solidity
receive() external payable
```

### fallback

```solidity
fallback() external payable
```

### FlowStartMessage

```solidity
event FlowStartMessage(address sender, address receiver, int96 flowRate, uint256 startTime)
```

_Emitted when flow message is sent across the bridge._

#### Parameters

| Name      | Type    | Description                        |
| --------- | ------- | ---------------------------------- |
| sender    | address |                                    |
| receiver  | address |                                    |
| flowRate  | int96   | Flow Rate, unadjusted to the pool. |
| startTime | uint256 |                                    |

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

| Name   | Type    | Description               |
| ------ | ------- | ------------------------- |
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
constructor() public
```

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

\_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

````solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### initialize

```solidity
function initialize(address payable _ops, address _host, address _cfa, address _connext, address _superToken, address _erc20Token) public
````

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

### \_sendFlowMessage

```solidity
function _sendFlowMessage(uint256 _streamActionType, address _receiver, int96 _flowRate, uint256 relayerFeeInTransactingAsset, uint256 slippage, uint256 cost, address bridgingToken, address destinationContract, uint32 destinationDomain) public
```

### \_sendToManyFlowMessage

```solidity
function _sendToManyFlowMessage(address[] receivers, int96[] flowRates, uint96[] costs, uint256 _streamActionType, uint256 _relayerFee, uint256 slippage, address bridgingToken, address destinationContract, uint32 destinationDomain) external
```

### \_sendRebalanceMessage

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

### treasury

```solidity
contract ITreasury treasury
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

### \_createdJobs

```solidity
mapping(bytes32 => struct Conditional.user) _createdJobs
```

### userBalance

```solidity
mapping(address => mapping(address => uint256)) userBalance
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(contract IConnext _connext, contract ISwapRouter _swapRouter, address payable _ops) public
```

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

\_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

````solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### onlySource

```solidity
modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source)
````

### JobCreated

```solidity
event JobCreated(address _taskCreator, bytes32 _jobId, bytes32 _gelatoTaskId, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, enum Conditional.Option option)
```

### JobSuccess

```solidity
event JobSuccess(uint256 txFee, address feeToken, address execAddress, bytes execData, bytes32 taskId, bool callSuccess)
```

### XTransferData

```solidity
event XTransferData(address sender, address receiver, address fromToken, address toToken, address destinationContract, uint256 amount, uint256 startTime, uint256 relayerFeeInTransactingAsset, uint32 destinationDomain)
```

### XReceiveData

```solidity
event XReceiveData(address originSender, uint32 origin, address asset, uint256 amount, bytes32 transferId, uint256 receiveTimestamp, address senderAccount, address receiverAccount)
```

### checkBalance

```solidity
function checkBalance() public view returns (uint256)
```

### updateTreasury

```solidity
function updateTreasury(address _treasury) external
```

### xTransfer

```solidity
function xTransfer(address from, address recipient, address destinationContract, uint32 destinationDomain, address fromToken, address toToken, uint256 amount, uint256 slippage, uint256 relayerFeeInTransactingAsset) public
```

### xReceive

```solidity
function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes _callData) internal returns (bytes)
```

### directSwapperCall

```solidity
function directSwapperCall(address _swapper, bytes swapData) external payable returns (uint256 amountOut)
```

Swap an exact amount of tokens for another token. Uses a direct call to the swapper to allow
easy swaps on the source side where the amount does not need to be changed.

#### Parameters

| Name      | Type    | Description                                                                     |
| --------- | ------- | ------------------------------------------------------------------------------- |
| \_swapper | address | Address of the swapper to use.                                                  |
| swapData  | bytes   | Data to pass to the swapper. This data is encoded for a particular swap router. |

### swapExactInputSingle

```solidity
function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn) internal returns (uint256 amountOut)
```

### \_cancelJob

```solidity
function _cancelJob(bytes32 _jobId) public
```

### \_getWeb3FunctionHash

```solidity
function _getWeb3FunctionHash(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, address _tokenA, address _tokenB, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public view returns (bytes)
```

### \_gelatoPriceFeedJobCreator

```solidity
function _gelatoPriceFeedJobCreator(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, address _tokenA, address _tokenB, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, string _web3FunctionHash, bytes _web3FunctionArgsHex) internal returns (bytes32)
```

### Allowance

```solidity
error Allowance(uint256 allowance, uint256 amount, address token)
```

### \_createPriceFeedAutomate

```solidity
function _createPriceFeedAutomate(address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, address _tokenA, address _tokenB, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, string _web3FunctionHash) public
```

### \_createMultiplePriceFeedAutomate

```solidity
function _createMultiplePriceFeedAutomate(address[] _to, uint256[] _amount, uint256[] _price, address[] _fromToken, address[] _toToken, address[] _tokenA, address[] _tokenB, uint256[] _toChain, uint32[] _destinationDomain, address[] _destinationContract, uint256[] _cycles, uint256[] _startTime, uint256[] _interval, string _web3FunctionHash) external
```

### AmountLessThanRelayer

```solidity
error AmountLessThanRelayer(uint256 _amount, uint256 _relayerFeeInTransactingAsset)
```

### \_priceFeedAutomateCron

```solidity
function _priceFeedAutomateCron(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, uint256 _relayerFeeInTransactingAsset) public payable
```

### getBalanceOfToken

```solidity
function getBalanceOfToken(address _address) public view returns (uint256)
```

### \_getAutomateJobId

```solidity
function _getAutomateJobId(address _from, address _to, uint256 _amount, uint256 _price, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public pure returns (bytes32)
```

## ISwapper

### swap

```solidity
function swap(uint256 _amountIn, address _tokenIn, address _tokenOut, bytes _swapData) external returns (uint256 amountOut)
```

### swapETH

```solidity
function swapETH(uint256 _amountIn, address _tokenOut, bytes _swapData) external payable returns (uint256 amountOut)
```
