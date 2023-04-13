// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import {console} from "./console.sol";
import "./ExampleExternalContract.sol";

/// @title Challenge 1 SpeedRunETH
/// @author rktbay
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental dummy private key and etherscan keys left on purpose
contract Staker {
    event Stake(address stakerAddress, uint256 contractBalance);

    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier notCompleted() {
        //variable from other contracts becomes treated as a function, hence ()
        require(
            exampleExternalContract.completed() == false,
            "ExampleExternalContract already executed"
        );
        _;
    }

    //added state variables for staking
    mapping(address => uint256) public balances; //track balances of stakers
    uint256 public constant threshold = 1 ether; // staking threshold per user?
    uint256 public deadline = block.timestamp + 72 hours; //stake period
    bool public openForWithdraw = false;

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        //store the ETH will be added to this contract's balance
        console.log("balance before: %s", address(this).balance);
        console.log(
            "amount being sent, probably displayed as WEI , %s",
            msg.value
        );
        console.log("balance after staking:  %s", address(this).balance);

        //track individual balances, also add balance if user stakes multiple times
        balances[msg.sender] += msg.value;

        emit Stake(msg.sender, address(this).balance); //emit Event so frontend can receive
    }

    function timeLeft() public view returns (uint256) {
        //ternary warmup, return 0 if past deadline, else return time remaining b4 deadline
        if (block.timestamp > deadline) {
            return 0;
        } else {
            return (deadline - block.timestamp);
        }
    }

    function execute() public notCompleted {
        require(block.timestamp >= deadline, "staking / deadline not yet over");
        //can only call after deadline
        //anyone can call this when deadline is met,
        //if staking balance meets threshold within the deadline
        if (address(this).balance >= threshold) {
            //balance is in wei, google says
            exampleExternalContract.complete{value: address(this).balance}();
        } else if (address(this).balance < threshold) {
            openForWithdraw = true;
        }
    }

    function withdraw() public payable notCompleted {
        require(openForWithdraw, "withdrawals not yet allowed");
        require(balances[msg.sender] > 0, "Nothing staked");
        address payable _to = payable(msg.sender);
        //only send monies back if it is from the right address(msg.sender)
        (bool sent, bytes memory data) = _to.call{value: balances[msg.sender]}(
            ""
        );
        require(sent, "Failed to return staked $$$");
        //clear staked balances when you withdraw lmao
        balances[msg.sender] = 0;
    }

    //chechkpoint 4, havent compiled and check checkpoint 3 codes though
    receive() external payable {
        if (exampleExternalContract.completed()) {
            // Return the Ether to the sender
            payable(msg.sender).transfer(msg.value);
        } else {
            stake(); //[OK] If you send ETH directly to the contract address does it update your balance?
        }
    }
}
