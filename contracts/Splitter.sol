//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOwnable {
    // Event emitted when ownership is transferred
    event OwnershipTransferred(address newOwner);

    // Transfers ownership to a new address
    function transferOwnership(address newOwner) external;

    // Returns the current owner of this contract
    function owner() external view returns (address);
}

interface IPausable {
    // Toggles the pause status of the contract
    // Hint: Who should be able to call this?
    function togglePause() external;

    // Returns if the contract is currently paused
    function paused() external view returns (bool);
}

interface ISplitter {
    // Event emitted when funds are deposited and split
    event DidDepositFunds(uint256 amount, address[] recipients);
    // Event emitted when funds are withdrawn
    event DidWithdrawFunds(uint256 amount, address recipient);

    // The caller deposits some amount of Ether and splits it among recipients evenly
    // This function cannot be called if the contract is paused
    function deposit(address[] calldata recipients) external payable;

    // The caller can withdraw a valid amount of Ether from the contract
    // This function cannot be called if the contract is paused
    function withdraw(uint256 amount) external;

    // Returns the current balance of an address
    function balanceOf(address addr) external view returns (uint256);
}

contract HW4 is IOwnable, IPausable, ISplitter {
    // Declare any necessary variables here
    address private _owner;
    bool private onlyNotPaused;
    uint256 private _each;
    mapping(address => uint256) private _balances;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    modifier pauseOff() {
        require(onlyNotPaused == false, "Pause On");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwner {
        onlyNotPaused = !onlyNotPaused;
    }

    function deposit(address[] calldata recipients)
        external
        payable
        override
        pauseOff
        onlyOwner
    {
        uint256 _amount = msg.value;
        _each = (_amount / recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            _balances[recipients[i]] += _each;
        }
        emit DidDepositFunds(_amount, recipients);
    }

    function withdraw(uint256 amount) external override pauseOff {
        if (amount <= _balances[msg.sender]) {
            address recipient = msg.sender;
            _balances[recipient] = _balances[recipient] - amount;
            payable(msg.sender).transfer(amount);
            emit DidWithdrawFunds(amount, recipient);
        } else {
            revert("Insufficient Funds");
        }
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function paused() external view override returns (bool) {
        return onlyNotPaused;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        uint256 realBalance = _balances[addr];
        return realBalance;
    }
}
