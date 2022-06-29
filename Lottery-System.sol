// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;


contract lot
{
    uint L_id=0;
    address[] public manager;
    mapping(uint=>mapping(address=>uint)) LotteryCount;
    mapping(uint=>uint) Starting_Tickets;
    struct Lottery{
        uint Lottery_id;
        uint Ethers_required;
        uint Tickets_available;
        address payable[] players;
        uint  _CollectedAmount;
        address broker;
    }
    mapping(uint=>bool) Lottery_exists;
    mapping(uint=>bool) Lottery_status;
    Lottery[] Lott;
    mapping(uint=>Lottery) map;


    event LotteryBought(address BUYER, uint COUNT);
    event DrawStatus(string);

    function Create_Lottery(uint EntryFees, uint Tickets_count)public payable
    {
        require(msg.value==EntryFees*1e18,"Give proper Stake");
        require(EntryFees>0 && Tickets_count>3,"Add proper details for creating lottery");

        manager.push(msg.sender);
        Lott.push(Lottery({Lottery_id:L_id, Ethers_required:EntryFees, Tickets_available:Tickets_count, players:new address payable[](0), _CollectedAmount:0,broker:msg.sender}));
        map[L_id]=Lott[L_id];
        Starting_Tickets[L_id]=Tickets_count;
        Lottery_exists[L_id++]=true;
    }
    function BuyTicket(uint LotteryID) external payable
    {
        require(Lottery_exists[LotteryID],"Lottery doesnot exists");
        require(!Lottery_status[LotteryID],"Lottery already Drawn");
        require(map[LotteryID].Tickets_available>0,"Sorry, Lottery is full");
        require(msg.value==(map[LotteryID].Ethers_required)*1e18 ,"please pay proper fees only");
        require(LotteryCount[LotteryID][msg.sender] < uint(Starting_Tickets[LotteryID]) ,"You cannot buy more lotteries");
        map[LotteryID].players.push(payable(msg.sender));
        LotteryCount[LotteryID][msg.sender]++;
        map[LotteryID]._CollectedAmount+=map[LotteryID].Ethers_required;
        map[LotteryID].Tickets_available-=1;

        emit LotteryBought(msg.sender,LotteryCount[LotteryID][msg.sender]);
    }
    function MyCount(uint LotteryID)public view returns(uint)
    {
        return LotteryCount[LotteryID][msg.sender];
    }
    function TicketsAvailable(uint LotteryID)public view returns(uint)
    {
        return map[LotteryID].Tickets_available;
    }
    function random()internal view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,block.number)));
    }
    function DrawLottery(uint LotteryID)public
    {
        uint LI=LotteryID;
        require(Lottery_exists[LI],"Lottery doesnot exists");
        require(msg.sender==map[LI].broker,"You are not the manager");
        require(!Lottery_status[LI],"Lottery already Drawn");
        require(map[LI].Tickets_available==0,"Lottery is not full yet");
        uint TotalAmount=map[LI]._CollectedAmount;
        address payable winner=map[LI].players[random()%map[LI].players.length];
        winner.transfer(85*TotalAmount*1e16);
        address payable owner=payable(msg.sender);
        owner.transfer(10*TotalAmount*1e16 + 1e18*map[LI].Ethers_required);
        Lottery_status[LI]=true;

        emit DrawStatus("Successfully transmitted winning amount");
    }
    function ContractBalance()public view returns(uint)
    {
        return address(this).balance;
    }
    
}