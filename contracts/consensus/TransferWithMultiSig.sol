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
        uint value
    );

    /**
    *@notice event confirm address owner signed for transaction with txIndex 
    */
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);

    /**
    *@notice event confirm address owner refuse to confirm for transaction with txIndex
    */
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    /**
    *@notice event that a transaction was done successfully
    */
    event TransferToken(address indexed signator, uint indexed txIndex);

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
        uint value;
        bool executed;
        uint numConfirmations;
    }

    /**
    *@dev mapping from tx index => owner => bool
    */ 
    mapping(uint => mapping(address => bool)) public isConfirmed;

    modifier txExists(uint _txIndex) {
        require(_txIndex < _transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!_transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier isAccepted(uint _txIndex) {
        require(_transactions[_txIndex].numConfirmations * 2 >= _admins.length, "Not enough consensus!");
        _;
    }

    constructor(address tokenAddress_) {

        _token = IERC20(tokenAddress_);
        
    }

    /**
    *@dev function create transaction
    *
    * Chỉ địa chỉ là admin mới có thể gọi hàm
    * Hàm kiểm tra số dư của smartcontract xem có đủ để tạo giao dịch không
    * nếu thoả mãn sẽ thêm mới giao dịch vào mảng
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
    * Chỉ địa chỉ là admin mới được gọi hàm này "onlyAdmin"
    * Giao dịch phải tồn tại "txExists(indexTx)"
    * Giao dịch chưa được thực hiện "notExecuted(indexTx)"
    * Giao dịch chưa được xác nhận bởi địa chỉ msg.sender "notConfirmed(indexTx)"
    */
    function confirmTransaction(uint indexTx)
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
    *
    * Chỉ địa chỉ là admin mới được gọi hàm này "onlyAdmin"
    * Giao dịch phải tồn tại "txExists(indexTx)"
    * Giao dịch chưa được thực hiện "notExecuted(indexTx)"
    * Giao dịch đã được msg.sender kí xác nhận "require(isConfirmed[indexTx][msg.sender], "tx not confirmed");"
    */
    function revokeConfirmation(uint indexTx)
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
    * Chỉ địa chỉ là admin mới được gọi hàm này "onlyAdmin"
    * Giao dịch phải tồn tại "txExists(indexTx)"
    * Giao dịch chưa được thực hiện "notExecuted(indexTx)"
    * Đạt đủ sự đồng thuận từ những admin khác "isAccepted(indexTx)"
    */
    function transferTokenToAddr(uint indexTx)
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

    function getTransaction(uint indexTx)
        public
        view
        returns (
            address to,
            uint value,
            bool executed,
            uint numConfirmations
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