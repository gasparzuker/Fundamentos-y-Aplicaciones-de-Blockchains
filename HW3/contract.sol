// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

contract Gasp_Token {

    address public owner;
    uint256  private totalSupply_; //Amount of minted tokens
    mapping (address => uint) private balances;
    uint256 private price; //const 600


    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        price = 600;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Mint(address indexed to, uint256 value);

    event Sell(address indexed from, uint256 value);

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function getName() public view returns (string memory) {
        return "Gasp";
    }

    function getSymbol() public view returns (string memory) {
        return "G$";
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        emit Transfer(msg.sender, to, value);
    }

    function sell(uint256 value) public {
        require(balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender] - value;
        totalSupply_ = totalSupply_ - value;
        emit Sell(msg.sender, value);
    }

    function mint(address to, uint256 value) public isOwner returns (bool){
        balances[to] = balances[to] + value;
        totalSupply_ = totalSupply_ + value;
        emit Mint(to, value);
        return true;
    }

    function close() external  isOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");

        // Self-destruct the contract
        powner = (payable) owner
        selfdestruct(owner);
    }

    fallback() external payable {   }

    receive() external payable { }
} 
