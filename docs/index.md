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

### _createdJobs

```solidity
mapping(bytes32 => struct AutoPay.user) _createdJobs
```

. mapping to store all ongoing jobs

_. key is the unique jobId_

### _web3functionHashes

```solidity
mapping(enum AutoPay.Option => string) _web3functionHashes
```

. mapping to store all web3 function hashes

_. key is the option enum_

### JobCreated

```solidity
event JobCreated(address _taskCreator, bytes32 _jobId, bytes32 _gelatoTaskId, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, bool _isForwardPaying, enum AutoPay.Option option)
```

.Event triggered when a job is created on the source chain

_._

### XTransferData

```solidity
event XTransferData(address sender, address receiver, address fromToken, address toToken, address destinationContract, uint256 amount, uint256 startTime, uint256 relayerFeeInTransactingAsset, uint32 destinationDomain)
```

.Event triggered when a xcall is made from source chain

_._

### XReceiveData

```solidity
event XReceiveData(address originSender, uint32 origin, address asset, uint256 amount, bytes32 transferId, uint256 receiveTimestamp, address senderAccount, address receiverAccount)
```

.Event triggered when a xcall is received on destination chain

_._

### ExecutedSourceChain

```solidity
event ExecutedSourceChain(bytes32 _jobId, address _from, uint256 _timesExecuted, uint256 _fundsUsed, uint256 _amountOut, bool _isForwardPaying)
```

.Event triggered when a job is executed on source chain

_._

### onlySource

```solidity
modifier onlySource(address _originSender, uint32 _origin, uint32 _originDomain, address _source)
```

.Modifier to check at only source contract calls an xcall to destination chain

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _originSender | address | . address of origin contract(address(this)) |
| _origin | uint32 | . connext domain of source chain |
| _originDomain | uint32 | . connext domain of source chain |
| _source | address | . contract address of origin contract passed as arguement |

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

| Name | Type | Description |
| ---- | ---- | ----------- |
| _connext | contract IConnext | . address of connext router |
| _swapRouter | contract ISwapRouter | .address of uniswap router |
| _ops | address payable | . address of gelato ops automate |
| _WETH | address | . address of WETH contract |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### checkBalance

```solidity
function checkBalance() public view returns (uint256)
```

. Function to check the ether(native) balance of the contract

_._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256  . balance in wei(native) |

### xTransfer

```solidity
function xTransfer(address from, address recipient, address destinationContract, uint32 destinationDomain, address fromToken, address toToken, uint256 amount, uint256 slippage, uint256 relayerFeeInTransactingAsset) internal
```

. Function called to connext on source chain to transfer xcall and funds

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | . address of the user who is sending the funds |
| recipient | address | . address of the user who is receiving the funds |
| destinationContract | address | . address of the contract on the destination chain |
| destinationDomain | uint32 | . connext domain of the destination chain |
| fromToken | address | . address of the token to be sent |
| toToken | address | . address of the token to be received |
| amount | uint256 | . amount of tokens to be sent |
| slippage | uint256 | . maximum slippage in BPS |
| relayerFeeInTransactingAsset | uint256 | . relayer fee in transacting asset |

### xReceive

```solidity
function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes _callData) internal returns (bytes)
```

.Function called to connext on destination chain to receive xcall and funds

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _transferId | bytes32 | . connext xcall unique transfer id |
| _amount | uint256 | . amount of asset recieved on the destination chain |
| _asset | address | . address of token received |
| _originSender | address | . address of source contract of AutoPay |
| _origin | uint32 | . domain of origin chain |
| _callData | bytes | . calldata passed in xcall |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes | bytes  . |

### directSwapperCall

```solidity
function directSwapperCall(address _swapper, bytes swapData) public payable returns (uint256 amountOut)
```

### _setupAndSwap

```solidity
function _setupAndSwap(address _fromAsset, address _toAsset, uint256 _amountIn, address _swapper, bytes _swapData) internal returns (uint256 amountOut)
```

. Function to swap assets using swapper and calldata

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _fromAsset | address | . token address of from token |
| _toAsset | address | . token address of to token |
| _amountIn | uint256 | . amount of tokens to be swapped |
| _swapper | address | . address of swapper router |
| _swapData | bytes | . swapdata provider by swap APIs (1inch, 0x) |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountOut | uint256 | . amount of tokens recieved after swap |

### swapExactInputSingle

```solidity
function swapExactInputSingle(address _fromToken, address _toToken, uint256 amountIn) internal returns (uint256 amountOut)
```

. Function to swap on chain (uniswap v3, v2)

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _fromToken | address | . token address of from token |
| _toToken | address | . token address of to token |
| amountIn | uint256 | . amount of tokens to be swapped |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountOut | uint256 | . amount of tokens recieved after swap |

### _cancelJob

```solidity
function _cancelJob(bytes32 _jobId) public
```

.Function called by taskcreator to cancel the job

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _jobId | bytes32 | . unique jobId created for each task |

### _getWeb3FunctionHash

```solidity
function _getWeb3FunctionHash(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, bool _isForwardPaying) public view returns (bytes)
```

. Function to get the jobId for time automate

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _from | address | . address of the user who is sending the funds |
| _to | address | . address of the user who is receiving the funds |
| _amount | uint256 | . amount of tokens to be sent |
| _fromToken | address | . address of the token to be sent |
| _toToken | address | . address of the token to be received |
| _toChain | uint256 | . chainId of the destination chain |
| _destinationDomain | uint32 | . connext domain of the destination chain |
| _destinationContract | address | . address of the contract on the destination chain |
| _cycles | uint256 | . number of cycles to be executed |
| _startTime | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| _interval | uint256 | . time interval between each cycle (in seconds) |
| _isForwardPaying | bool |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes | bytes  . returns uniqure jobId (bytes32) |

### _gelatoTimeJobCreator

```solidity
function _gelatoTimeJobCreator(uint256 _startTime, uint256 _interval, bytes _web3FunctionArgsHex) internal returns (bytes32)
```

.Function called to create task on gelato

_.returns gelatoTaxId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _startTime | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| _interval | uint256 | . time interval between each cycle (in seconds) |
| _web3FunctionArgsHex | bytes | . calldata for the task |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32  . returns gelatoTaskId |

### _createTimeAutomate

```solidity
function _createTimeAutomate(address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, bool _isForwardPaying) public
```

. Function to create a scheduled time automate

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | . address of the user who is receiving the funds |
| _amount | uint256 | . amount of tokens to be sent |
| _fromToken | address | . address of the token to be sent |
| _toToken | address | . address of the token to be received |
| _toChain | uint256 | . chainId of the destination chain |
| _destinationDomain | uint32 | . connext domain of the destination chain |
| _destinationContract | address | . address of the contract on the destination chain |
| _cycles | uint256 | . number of cycles to be executed |
| _startTime | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| _interval | uint256 | . time interval between each cycle (in seconds) |
| _isForwardPaying | bool |  |

### _createMultipleTimeAutomate

```solidity
function _createMultipleTimeAutomate(address[] _to, uint256[] _amount, address[] _fromToken, address[] _toToken, uint256[] _toChain, uint32[] _destinationDomain, address[] _destinationContract, uint256[] _cycles, uint256[] _startTime, uint256[] _interval, bool isForwardPaying) external
```

. Function to create multiple scheduled time automates

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address[] | . array of addresses of the user who is receiving the funds |
| _amount | uint256[] | . array of amounts of tokens to be sent |
| _fromToken | address[] | . array of addresses of the token to be sent |
| _toToken | address[] | . array of addresses of the token to be received |
| _toChain | uint256[] | . array of chainIds of the destination chain |
| _destinationDomain | uint32[] | . array of connext domains of the destination chain |
| _destinationContract | address[] | . array of addresses of the contract on the destination chain |
| _cycles | uint256[] | . array of number of cycles to be executed |
| _startTime | uint256[] | . array of times when the first cycle should be executed (unixtime in seconds) |
| _interval | uint256[] | . array of time intervals between each cycle (in seconds) |
| isForwardPaying | bool |  |

### _timeAutomateCron

```solidity
function _timeAutomateCron(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval, uint256 _relayerFeeInTransactingAsset, bool _isForwardPaying, address _swapper, bytes _swapData) public
```

. Function called by gelato to execute the task

_. can only be called by gelato (dedicatedMsgSender)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _from | address | . address of the user who is sending the funds |
| _to | address | . address of the user who is receiving the funds |
| _amount | uint256 | . amount of tokens to be sent |
| _fromToken | address | . address of the token to be sent |
| _toToken | address | . address of the token to be received |
| _toChain | uint256 | . chainId of the destination chain |
| _destinationDomain | uint32 | . connext domain of the destination chain |
| _destinationContract | address | . address of the contract on the destination chain |
| _cycles | uint256 | . number of cycles to be executed |
| _startTime | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| _interval | uint256 | . time interval between each cycle (in seconds) |
| _relayerFeeInTransactingAsset | uint256 | . relayer fee in transacting asset |
| _isForwardPaying | bool |  |
| _swapper | address | . address of swapper router |
| _swapData | bytes | . swapdata provider by swap APIs (1inch, 0x) |

### _getAutomateJobId

```solidity
function _getAutomateJobId(address _from, address _to, uint256 _amount, address _fromToken, address _toToken, uint256 _toChain, uint32 _destinationDomain, address _destinationContract, uint256 _cycles, uint256 _startTime, uint256 _interval) public pure returns (bytes32)
```

. Function which creates a unique jobId for each task

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _from | address | . address of the user who is sending the funds |
| _to | address | . address of the user who is receiving the funds |
| _amount | uint256 | . amount of tokens to be sent |
| _fromToken | address | . address of the token to be sent |
| _toToken | address | . address of the token to be received |
| _toChain | uint256 | . chainId of the destination chain |
| _destinationDomain | uint32 | . connext domain of the destination chain |
| _destinationContract | address | . address of the contract on the destination chain |
| _cycles | uint256 | . number of cycles to be executed |
| _startTime | uint256 | . time when the first cycle should be executed (unixtime in seconds) |
| _interval | uint256 | . time interval between each cycle (in seconds) |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32  . returns unique jobId |

### updateTreasury

```solidity
function updateTreasury(address _treasury) external
```

. Function to update the treasury contract  address.

_. can only be called by owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _treasury | address | address of the new treasury contract |

### updateWeb3functionHashes

```solidity
function updateWeb3functionHashes(enum AutoPay.Option[] _types, string[] _hashes) external
```

. Function to update the web3 function hashes.

_. can only be called by owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _types | enum AutoPay.Option[] | . array of options |
| _hashes | string[] | . array of hashes |

### updateFee

```solidity
function updateFee(uint256 _fee) external
```

. Function to update the gelato fees.

_. can only be called by owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _fee | uint256 | . new fee |

### _forceCancelGelato

```solidity
function _forceCancelGelato(bytes32 _gelatoTaskID) external
```

. Function to force cancel gelato task

_. can only be called by owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _gelatoTaskID | bytes32 | . gelato task id |

### _getJob

```solidity
function _getJob(bytes32 _jobId) external view returns (address, uint256, uint256, bytes32)
```

. Function to get the job details

_._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _jobId | bytes32 | . unique jobId created for each task |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address  . address of the user who created the job |
| [1] | uint256 | uint256  . total number of cycles |
| [2] | uint256 | uint256  . number of cycles executed |
| [3] | bytes32 | bytes32  . gelato task id |

## Treasury

### userTokenBalance

```solidity
mapping(address => mapping(address => uint256)) userTokenBalance
```

### _tokenCredits

```solidity
mapping(address => struct EnumerableSet.AddressSet) _tokenCredits
```

### _whitelistedServices

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

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### depositFunds

```solidity
function depositFunds(address _receiver, address _token, uint256 _amount) external payable
```

Function to deposit Funds which will be used to execute transactions on various services

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _receiver | address | Address receiving the credits |
| _token | address | Token to be credited, use "0xeeee...." for ETH |
| _amount | uint256 | Amount to be credited |

### withdrawFunds

```solidity
function withdrawFunds(address payable _receiver, address _token, uint256 _amount) external
```

Function to withdraw Funds back to the _receiver

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _receiver | address payable | Address receiving the credits |
| _token | address | Token to be credited, use "0xeeee...." for ETH |
| _amount | uint256 | Amount to be credited |

### useFunds

```solidity
function useFunds(address _token, uint256 _amount, address _user) external
```

Function called by whitelisted services to handle payments, e.g. Ops"

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | address | Token to be used for payment by users |
| _amount | uint256 | Amount to be deducted |
| _user | address | Address of user whose balance will be deducted |

### addWhitelistedService

```solidity
function addWhitelistedService(address _service) external
```

Add new service that can call useFunds. Gelato Governance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _service | address | New service to add |

### removeWhitelistedService

```solidity
function removeWhitelistedService(address _service) external
```

Remove old service that can call useFunds. Gelato Governance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _service | address | Old service to remove |

### getCreditTokensByUser

```solidity
function getCreditTokensByUser(address _user) external view returns (address[])
```

Helper func to get all deposited tokens by a user

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | User to get the balances from |

### getWhitelistedServices

```solidity
function getWhitelistedServices() external view returns (address[])
```

