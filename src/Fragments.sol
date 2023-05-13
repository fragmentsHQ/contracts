// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/OpsTaskCreator.sol";

contract Fragments is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    OpsTaskCreator
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    address public merchantAddress;
    string public name;
    string public logoURI;
    uint256 public totalRevenue;
    bool internal isTransferring = false;
    address internal owner;
    uint256 public FEES = 0.01 ether;
    uint256 public FEES_PAID = 0;
    address public UniswapV3 = 0x3DC9462BFafD9Bea7442f538725257E7B92770E3;
    // address payable _ops = payable(0xc1C6805B857Bef1f412519C4A842522431aFed39);
    address payable _ops = payable(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);

    mapping(uint256 => subscriptionInfo) public subscriptions;
    uint256[] internal subscriptionId;

    mapping(address => subscribeInfo) public subsribes;

    receive() external payable {}

    constructor(
        address _owner,
        address _merchantAddress,
        string memory _name,
        string memory _logoURI
    ) OpsTaskCreator(_ops, _owner) {
        merchantAddress = _merchantAddress;
        name = _name;
        logoURI = _logoURI;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner Function");
        _;
    }

    modifier onlyMerchant() {
        require(
            merchantAddress == msg.sender,
            "Only Merchant Allowed Function"
        );
        _;
    }

    modifier isTransfer() {
        require(isTransferring == false, "already transferring!");
        _;
    }

    event subscriptionCreated(
        address indexed user,
        address indexed merchantAddress,
        uint256 indexed subscriptionId,
        string heading,
        string description,
        uint256 pricePerCycle,
        uint256 interval,
        uint256 timestamp
    );

    event subscribed(
        uint256 indexed subscriptionId,
        address indexed user,
        bytes32 indexed gelatoTxId,
        address token,
        string email,
        string chainId,
        uint256 timestamp,
        uint256 interval
    );

    struct subscriptionInfo {
        address merchant;
        string heading;
        string description;
        uint256 pricePerCycle;
        uint256 interval;
        uint256 timestamp;
    }

    struct subscribeInfo {
        uint256 subscriptionId;
        address token;
        string email;
        string chainId;
        uint256 timestamp;
        bytes32 gelatoTxId;
        uint256 interval;
    }

    function changeSwapContract(address _contract) external onlyOwner {
        UniswapV3 = _contract;
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function createSubscription(
        string memory _heading,
        string memory _description,
        uint256 _pricePerCycle,
        uint256 _interval,
        uint256 _id
    ) public onlyMerchant {
        subscriptionInfo storage newSubscription = subscriptions[_id];
        newSubscription.merchant = msg.sender;
        newSubscription.heading = _heading;
        newSubscription.description = _description;
        newSubscription.pricePerCycle = _pricePerCycle;
        newSubscription.interval = _interval;
        newSubscription.timestamp = block.timestamp;
        subscriptionId.push(_id);

        emit subscriptionCreated(
            msg.sender,
            address(this),
            _id,
            _heading,
            _description,
            _pricePerCycle,
            _interval,
            block.timestamp
        );
    }

    function checkSubscribe() public view returns (bool) {
        subscribeInfo memory res = subsribes[msg.sender];
        return res.subscriptionId != 0;
    }

    // uint256 public constant INTERVAL = 30 days;

    function createTask(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _interval
    ) internal returns (bytes32) {
        bytes memory execData = abi.encodeWithSelector(
            this.transferToMe.selector,
            _user,
            _token,
            _amount
        );

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _timeModuleArg(block.timestamp, _interval);
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        return id;
    }

    function subscribe(
        uint256 _subscriptionId,
        address _token,
        string memory _email,
        string memory _chainId,
        address _user
    ) public {
        // ERC20(_token).permit(_user, address(this), _amount, deadline, v, r, s);

        subscriptionInfo storage sub = subscriptions[_subscriptionId];
        require(sub.pricePerCycle != 0, "No Subscription found to subscribe !");

        uint256 dec = ERC20(_token).decimals();

        bytes32 id = createTask(
            _user,
            _token,
            (sub.pricePerCycle * (10 ** dec)),
            sub.interval
        );

        subscribeInfo storage newSubsribe = subsribes[_user];
        newSubsribe.subscriptionId = _subscriptionId;
        newSubsribe.token = _token;
        newSubsribe.email = _email;
        newSubsribe.chainId = _chainId;
        newSubsribe.gelatoTxId = id;
        newSubsribe.interval = sub.interval;
        newSubsribe.timestamp = block.timestamp;

        emit subscribed(
            _subscriptionId,
            _user,
            id,
            _token,
            _email,
            _chainId,
            newSubsribe.timestamp,
            sub.interval
        );
    }

    function cancelSubscribe(address _user) external {
        subscribeInfo memory res = subsribes[_user];
        require(res.subscriptionId != 0, "No subscribe found");

        _cancelTask(res.gelatoTxId);

        delete subsribes[_user];
    }

    function withDraw(address _token) external onlyMerchant isTransfer {
        uint256 balance = getBalanceOfToken(_token);
        isTransferring = true;
        UNI(UniswapV3).swapExactInputSingle(
            _token,
            (balance * 25) / 1000,
            payable(owner)
        );
        // ERC20(_token).transfer(owner, (balance*25)/1000);

        ERC20(_token).transfer(merchantAddress, (balance * 975) / 1000);
        isTransferring = false;
    }

    function transferToMe(
        address _owner,
        address _token,
        uint256 _amount
    ) external {
        ERC20(_token).transferFrom(_owner, address(this), _amount);

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return ERC20(_address).balanceOf(address(this));
    }
}
