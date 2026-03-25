// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    // ─── Initial State ─────────────────────────────────────────────────────────

    function test_InitialValue() public view {
        assertEq(counter.number(), 0);
    }

    // ─── setNumber ─────────────────────────────────────────────────────────────

    function test_SetNumber() public {
        counter.setNumber(42);
        assertEq(counter.number(), 42);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    // ─── increment ─────────────────────────────────────────────────────────────

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function test_IncrementMultiple() public {
        counter.increment();
        counter.increment();
        counter.increment();
        assertEq(counter.number(), 3);
    }

    function testFuzz_IncrementFromValue(uint256 startValue) public {
        // Avoid overflow — bound to safe range
        startValue = bound(startValue, 0, type(uint256).max - 1);
        counter.setNumber(startValue);
        counter.increment();
        assertEq(counter.number(), startValue + 1);
    }

    // ─── decrement ─────────────────────────────────────────────────────────────

    function test_Decrement() public {
        counter.setNumber(5);
        counter.decrement();
        assertEq(counter.number(), 4);
    }

    function test_DecrementFail_BelowZero() public {
        vm.expectRevert("Counter: cannot decrement below zero");
        counter.decrement();
    }

    function testFuzz_Decrement(uint256 startValue) public {
        // Avoid underflow — start from at least 1
        startValue = bound(startValue, 1, type(uint256).max);
        counter.setNumber(startValue);
        counter.decrement();
        assertEq(counter.number(), startValue - 1);
    }

    // ─── add ───────────────────────────────────────────────────────────────────

    function test_Add() public {
        counter.setNumber(10);
        counter.add(5);
        assertEq(counter.number(), 15);
    }

    function testFuzz_Add(uint256 initial, uint256 amount) public {
        // Prevent overflow
        initial = bound(initial, 0, type(uint128).max);
        amount = bound(amount, 0, type(uint128).max);
        counter.setNumber(initial);
        counter.add(amount);
        assertEq(counter.number(), initial + amount);
    }

    // ─── subtract ──────────────────────────────────────────────────────────────

    function test_Subtract() public {
        counter.setNumber(20);
        counter.subtract(7);
        assertEq(counter.number(), 13);
    }

    function test_SubtractFail_Underflow() public {
        counter.setNumber(5);
        vm.expectRevert("Counter: subtraction underflow");
        counter.subtract(10);
    }

    function testFuzz_Subtract(uint256 initial, uint256 amount) public {
        initial = bound(initial, 0, type(uint128).max);
        amount = bound(amount, 0, initial);
        counter.setNumber(initial);
        counter.subtract(amount);
        assertEq(counter.number(), initial - amount);
    }

    // ─── reset ─────────────────────────────────────────────────────────────────

    function test_Reset() public {
        counter.setNumber(999);
        counter.reset();
        assertEq(counter.number(), 0);
    }

    // ─── Events ────────────────────────────────────────────────────────────────

    function test_EmitsNumberSetEvent() public {
        vm.expectEmit(false, false, false, true);
        emit Counter.NumberSet(42);
        counter.setNumber(42);
    }

    function test_EmitsIncrementedEvent() public {
        vm.expectEmit(false, false, false, true);
        emit Counter.Incremented(1);
        counter.increment();
    }

    function test_EmitsResetEvent() public {
        counter.setNumber(10);
        vm.expectEmit(false, false, false, false);
        emit Counter.Reset();
        counter.reset();
    }

    // ─── Invariant / Property Tests ────────────────────────────────────────────

    /// @notice After any sequence of add operations, number >= initial value
    function testFuzz_AddNeverDecreases(uint256 initial, uint256 a, uint256 b) public {
        initial = bound(initial, 0, type(uint64).max);
        a = bound(a, 0, type(uint64).max);
        b = bound(b, 0, type(uint64).max);

        counter.setNumber(initial);
        counter.add(a);
        counter.add(b);

        assertGe(counter.number(), initial);
    }
}
