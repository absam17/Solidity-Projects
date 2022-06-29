// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract MSW
{
    address[] public owners;
    mapping(address=>bool) isOwner;
    uint rc;
    address payable users;
    Transaction[] public transactions;
    mapping(uint=>mapping(address=>bool)) isConfirmed;
        
    event wallet_created(string MSG,address[] OWNERS_LIST);
    event transaction_added(string MSG,uint Tx_id,uint AMOUNT,address RECEPIENT);
    event transaction_confirmed(string MSG,uint Tx_id,address CONFIRMED_BY ,uint VOTES);
    event confirmation_removed(string MSG,uint Tx_id,address CONFIRMATIION_REMOVED_BY,uint VOTES);
    event transaction_executed(string MSG,uint Tx_id,uint AMOUNT,address receiver);
    event deposit_successfull(uint AMOUNT);

    constructor(address[] memory ad,uint Req_confirmations)
    {
        require(ad.length>0 && Req_confirmations>0 && Req_confirmations<=ad.length,"wrong input");
        rc=Req_confirmations;
        for(uint i=0;i<ad.length;i++)
        {
            
            address ow=ad[i];
            
            require(ow!=address(0),"Invalid owner");
            require(!isOwner[ow],"not unique owners");
            isOwner[ow]=true;
            owners.push(ow);
        }
        require(isOwner[msg.sender],"you cannot create others wallet");
        emit wallet_created("Wallet Created Successfully",owners);
    }

    struct Transaction
    {
        uint amount;
        address to;
        uint noc;
        bool isExecuted;
        
    }

    modifier _isOwner
    {
        require(isOwner[msg.sender],"you are not an owner of this wallet");_;
    }
    modifier notConfirmed(uint tx_id)
    {
        require(!isConfirmed[tx_id][msg.sender],"you can confirm only once");_;
    }
    modifier isNotExecuted(uint tx_id)
    {
        require(!transactions[tx_id].isExecuted,"already executed this transaction");_;
    }
    modifier txexists(uint tx_id)
    {
        require(tx_id<transactions.length,"tx does not exists");_;
    }

    function AddTransaction(uint amt, address receiver)public _isOwner
    {
        
        transactions.push(Transaction({amount:amt,to:receiver,noc:0,isExecuted:false}));
        isConfirmed[transactions.length-1][msg.sender]=true;
        transactions[transactions.length-1].noc+=1;

        emit transaction_added("Transaction Added Successfully",transactions.length-1,amt,receiver);
    }

    function GiveConfirmation(uint tx_id)public _isOwner txexists(tx_id) isNotExecuted(tx_id) notConfirmed(tx_id)
    {
        isConfirmed[tx_id][msg.sender]=true;
        transactions[tx_id].noc+=1;

        emit transaction_confirmed("Transaction Confirmed",tx_id,msg.sender,transactions[tx_id].noc);
    }
    function RemoveConfirmation(uint tx_id)public _isOwner txexists(tx_id) isNotExecuted(tx_id) notConfirmed(tx_id)
    {
        isConfirmed[tx_id][msg.sender]=false;
        transactions[tx_id].noc-=1;

        emit confirmation_removed("Confirmation Removed Successfully",tx_id,msg.sender,transactions[tx_id].noc);
    }
    function ExecuteTransaction(uint tx_id)public payable _isOwner txexists(tx_id) isNotExecuted(tx_id)  
    {
        require(address(this).balance>=((transactions[tx_id].amount)*1000000000000000000),"not enough balance in wallet");
        require(transactions[tx_id].noc>=rc,"Not a majority");
        users = payable (transactions[tx_id].to);
        users.transfer((transactions[tx_id].amount)*1000000000000000000);
        transactions[tx_id].isExecuted=true;

        emit transaction_executed("Transaction Successfull",tx_id,(transactions[tx_id].amount),(transactions[tx_id].to));
    }
    function Deposit()public payable
    {
        emit deposit_successfull(msg.value);
    }
    function CheckBalance()public view returns(uint)
    {
        return address(this).balance;
    }
}
