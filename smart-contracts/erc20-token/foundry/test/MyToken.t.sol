// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;

    address public owner;
    address public alice;
    address public bob;

    string constant NAME = "MyToken";
    string constant SYMBOL = "MTK";
    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.prank(owner);
        token = new MyToken(NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY, owner);
    }

    // ─── Deployment ────────────────────────────────────────────────────────────

    function test_Name() public view {
        assertEq(token.name(), NAME);
    }

    function test_Symbol() public view {
        assertEq(token.symbol(), SYMBOL);
    }

    function test_Decimals() public view {
        assertEq(token.decimals(), DECIMALS);
    }

    function test_InitialSupply() public view {
        uint256 expected = INITIAL_SUPPLY * (10 ** DECIMALS);
        assertEq(token.totalSupply(), expected);
        assertEq(token.balanceOf(owner), expected);
    }

    function test_Owner() public view {
        assertEq(token.owner(), owner);
    }

    // ─── Transfers ─────────────────────────────────────────────────────────────

    function test_Transfer() public {
        uint256 amount = 100 * (10 ** DECIMALS);
        vm.prank(owner);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_TransferFail_InsufficientBalance() public {
        uint256 amount = 100 * (10 ** DECIMALS);
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, amount);
    }

    function testFuzz_Transfer(uint256 amount) public {
        uint256 ownerBalance = token.balanceOf(owner);
        amount = bound(amount, 0, ownerBalance);

        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), ownerBalance - amount);
    }

    // ─── Minting ───────────────────────────────────────────────────────────────

    function test_Mint() public {
        uint256 mintAmount = 500 * (10 ** DECIMALS);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(owner);
        token.mint(alice, mintAmount);

        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), supplyBefore + mintAmount);
    }

    function test_MintFail_NotOwner() public {
        uint256 mintAmount = 500 * (10 ** DECIMALS);
        vm.prank(alice);
        vm.expectRevert();
        token.mint(alice, mintAmount);
    }

    function testFuzz_Mint(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(owner);
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), supplyBefore + amount);
    }

    // ─── Burning ───────────────────────────────────────────────────────────────

    function test_Burn() public {
        uint256 burnAmount = 100 * (10 ** DECIMALS);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(owner);
        token.burn(burnAmount);

        assertEq(token.totalSupply(), supplyBefore - burnAmount);
    }

    function testFuzz_Burn(uint256 amount) public {
        uint256 ownerBalance = token.balanceOf(owner);
        amount = bound(amount, 0, ownerBalance);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(owner);
        token.burn(amount);

        assertEq(token.totalSupply(), supplyBefore - amount);
    }

    // ─── Pausable ──────────────────────────────────────────────────────────────

    function test_Pause() public {
        vm.prank(owner);
        token.pause();
        assertTrue(token.paused());

        uint256 amount = 100 * (10 ** DECIMALS);
        vm.prank(owner);
        vm.expectRevert();
        token.transfer(alice, amount);
    }

    function test_Unpause() public {
        vm.prank(owner);
        token.pause();

        vm.prank(owner);
        token.unpause();
        assertFalse(token.paused());

        uint256 amount = 100 * (10 ** DECIMALS);
        vm.prank(owner);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_PauseFail_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        token.pause();
    }

    // ─── Allowances ────────────────────────────────────────────────────────────

    function test_Approve() public {
        uint256 amount = 200 * (10 ** DECIMALS);
        vm.prank(owner);
        token.approve(alice, amount);
        assertEq(token.allowance(owner, alice), amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 200 * (10 ** DECIMALS);
        vm.prank(owner);
        token.approve(alice, amount);

        vm.prank(alice);
        token.transferFrom(owner, bob, amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(owner, alice), 0);
    }
}
