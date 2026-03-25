// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
    uint256 private value;

    function store(uint256 num) public {
        value = num;
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}
