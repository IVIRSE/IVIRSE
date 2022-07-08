// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AdminConsensus.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *@author duong.nt
 *@title smartcontract AdminConsensus - @author tuan.dq
 *@title  Smart contract for admin can get tokens if there is enough consensus from other admins.
*/


contract TransferWithMultiSig is AdminConsensus {

   /***
    @notice event that a transaction has been created
   */
    event SubmitTransaction(
        address indexed owner,
        uint256 txIndex,
        address indexed to,
        uint256 value
    );

    /**
    *@notice event confirm address owner signed for transaction with txIndex 
    */
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    /**
    *@notice event confirm address owner refuse to confirm for transaction with txIndex
    */
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    /**
    *@notice event that a transaction was done successfully
    */
    event TransferToken(address indexed signator, uint256 indexed txIndex);

    /**
    *@dev token address variable
    */
    IERC20 private _token;

    /**
    *@dev array save all transaction
    */
    Transaction[] private _transactions;

    struct Transaction {
        uint256 txIndex;
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    /**
    *@dev mapping from tx index => owner => bool
    */ 
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < _transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!_transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier isAccepted(uint256 _txIndex) {
        require(_transactions[_txIndex].numConfirmations * 2 > _admins.length, "Not enough consensus!");
        _;
    }

    constructor(address tokenAddress_) {

        _token = IERC20(tokenAddress_);
        
    }

    /**
    *@dev function create transaction
    */
    function submitTransaction(
        address receiver,
        uint256 amount
    ) public onlyAdmin {
        require(_token.balanceOf(address(this)) >= amount, "not enought token");
        uint256 index = _transactions.length;

        _transactions.push(
            Transaction({
                txIndex: index,
                to: receiver,
                value: amount,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, index, receiver, amount);
    }

    /**
    *@dev function comfirm transaction
    *
    */
    function confirmTransaction(uint256 indexTx)
        public
        onlyAdmin
        txExists(indexTx)
        notExecuted(indexTx)
        notConfirmed(indexTx)
    {
        Transaction storage transaction = _transactions[indexTx];
        transaction.numConfirmations += 1;
        isConfirmed[indexTx][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, indexTx);
    }

    /**
    *@dev function reject transaction
    */
    function revokeConfirmation(uint256 indexTx)
        public
        onlyAdmin
        txExists(indexTx)
        notExecuted(indexTx)
    {
        Transaction storage transaction = _transactions[indexTx];

        require(isConfirmed[indexTx][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[indexTx][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, indexTx);
    }

    /**
    *@dev function transfer token
    *
    */
    function transferTokenToAddr(uint256 indexTx)
        public
        onlyAdmin
        txExists(indexTx)
        notExecuted(indexTx)
        isAccepted(indexTx)
    {
        Transaction storage transaction = _transactions[indexTx];

        require(_token.balanceOf(address(this)) >= transaction.value, "not enought token");
        
        _token.transfer(transaction.to, transaction.value);
        
        _transactions[indexTx].executed = true;

        emit TransferToken(msg.sender, indexTx);
    }

    function getAllTransactions() public view returns(Transaction[] memory) {
        return _transactions;
    }

    function getTransaction(uint256 indexTx)
        public
        view
        returns (
            address to,
            uint256 value,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = _transactions[indexTx];

        return (
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations
        );
    }

}