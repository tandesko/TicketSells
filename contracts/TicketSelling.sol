//SPDX-License-Identifier: LGPL-3.0-or.later

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketSelling is Ownable {
    mapping(address => uint256) buyerTickets;
    address[] buyers;

    uint256 public leaveTime;
    uint256 public ticketsAmount;
    uint256 public ticketsBoughtAmount;
    uint256 public ticketPrice;
    bool public sellsOpened = true;

    event TrainDeparture();
    event TrainCanceled();

    modifier onlyBefore(uint256 _time) {
        require(block.timestamp < _time, "Train already leaved!");
        _;
    }

    modifier onlyAfter(uint256 _time) {
        require(block.timestamp > _time, "Train haven't departured or cancelled yet!");
        _;
    }

    constructor (uint amount, uint price, uint256 time) {
        ticketsAmount = amount;
        ticketPrice = price;
        leaveTime = time;
        ticketsBoughtAmount = 0;
    }

    function buyTickets(uint256 seats) external payable onlyBefore(leaveTime) {
        require(ticketsBoughtAmount < ticketsAmount, "No free seats!");
        require(ticketPrice * seats != msg.value, "Not exact sum!");
        if (buyerTickets[msg.sender] == 0) {
            buyerTickets[msg.sender] = seats;
            buyers.push(msg.sender);
        } else 
            buyerTickets[msg.sender] += seats;
        ticketsBoughtAmount += seats;
    }

    function departTrain() external onlyOwner onlyAfter(leaveTime) {
        require(sellsOpened, "Sells have already closed!");
        sellsOpened = false;
        _refundSeller();
        emit TrainDeparture();
    }

    function cancelTrain() external onlyOwner {
        require(sellsOpened, "Sells have already closed!");
        sellsOpened = false;
        for (uint256 i = 0; i < buyers.length; i++) {
            (bool success, ) = buyers[i].call{
                value: buyerTickets[buyers[i]] * ticketPrice
            }("");
            require(success, "Transaction for buyer failed");
        }
        emit TrainCanceled();
    }

    function _refundSeller() private onlyAfter(leaveTime) {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transaction refund failed!");
    }
}
