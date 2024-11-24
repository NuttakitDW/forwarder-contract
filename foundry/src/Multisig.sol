// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Multisig {
    address public superAdmin;
    address[] public committee;
    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public approvals;
    uint256 public nextTransactionId;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    mapping(uint256 => Transaction) public transactions;

    event Deposit(address indexed sender, uint256 amount);
    event TransactionCreated(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event ApprovalReceived(uint256 indexed txId, address indexed approver);
    event TransactionExecuted(uint256 indexed txId);
    event EmergencyWithdrawal(address indexed superAdmin, uint256 amount);

    modifier onlyCommittee() {
        require(isCommitteeMember(msg.sender), "Not a committee member");
        _;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Only super admin can call");
        _;
    }

    constructor(address _superAdmin, address[] memory _committee, uint256 _threshold) {
        require(_superAdmin != address(0), "Invalid super admin address");
        require(_committee.length > 0, "Committee cannot be empty");
        require(_threshold > 0 && _threshold <= _committee.length, "Invalid threshold");

        superAdmin = _superAdmin;
        committee = _committee;
        threshold = _threshold;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function isCommitteeMember(address account) public view returns (bool) {
        for (uint256 i = 0; i < committee.length; i++) {
            if (committee[i] == account) {
                return true;
            }
        }
        return false;
    }

    function createTransaction(address to, uint256 value, bytes calldata data) external onlyCommittee {
        uint256 txId = nextTransactionId++;
        transactions[txId] = Transaction(to, value, data, false);
        emit TransactionCreated(txId, to, value, data);
    }

    function approveTransaction(uint256 txId) external onlyCommittee {
        require(transactions[txId].to != address(0), "Transaction does not exist");
        require(!transactions[txId].executed, "Transaction already executed");
        require(!approvals[txId][msg.sender], "Already approved");

        approvals[txId][msg.sender] = true;
        emit ApprovalReceived(txId, msg.sender);

        if (getApprovalCount(txId) >= threshold) {
            executeTransaction(txId);
        }
    }

    function executeTransaction(uint256 txId) public {
        require(transactions[txId].to != address(0), "Transaction does not exist");
        require(!transactions[txId].executed, "Transaction already executed");
        require(getApprovalCount(txId) >= threshold, "Not enough approvals");

        Transaction storage txn = transactions[txId];
        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(txId);
    }

    function getApprovalCount(uint256 txId) public view returns (uint256 count) {
        for (uint256 i = 0; i < committee.length; i++) {
            if (approvals[txId][committee[i]]) {
                count++;
            }
        }
    }

    function emergencyWithdraw(uint256 amount, address payable to) external onlySuperAdmin {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit EmergencyWithdrawal(superAdmin, amount);
    }

    function withdrawERC20(address tokenAddress, uint256 amount, address to) external onlySuperAdmin {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(token.transfer(to, amount), "Token transfer failed");
    }
}
