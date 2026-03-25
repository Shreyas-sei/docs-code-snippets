// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Counter — Simple counter contract for Sei EVM
/// @notice Demonstrates a basic Foundry workflow with increment, decrement, and fuzz testing
contract Counter {
    uint256 public number;

    event NumberSet(uint256 newNumber);
    event Incremented(uint256 newNumber);
    event Decremented(uint256 newNumber);
    event Reset();

    /// @notice Set the counter to a specific value
    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit NumberSet(newNumber);
    }

    /// @notice Increment the counter by 1
    function increment() public {
        number++;
        emit Incremented(number);
    }

    /// @notice Decrement the counter by 1
    /// @dev Reverts if the counter is already 0 (underflow protection)
    function decrement() public {
        require(number > 0, "Counter: cannot decrement below zero");
        number--;
        emit Decremented(number);
    }

    /// @notice Add a specified amount to the counter
    function add(uint256 amount) public {
        number += amount;
        emit NumberSet(number);
    }

    /// @notice Subtract a specified amount from the counter
    function subtract(uint256 amount) public {
        require(number >= amount, "Counter: subtraction underflow");
        number -= amount;
        emit NumberSet(number);
    }

    /// @notice Reset the counter to zero
    function reset() public {
        number = 0;
        emit Reset();
    }
}
