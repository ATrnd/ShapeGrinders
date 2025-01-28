// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {WorldState} from "../../src/WorldState.sol";

contract WorldStateTest is Test {
    WorldState public worldState;
    
    function setUp() public {
        worldState = new WorldState();
    }

    function test_FuzzFragmentId(address user, uint256 timestamp) public {
        vm.assume(timestamp > 0);
        vm.warp(timestamp);
        vm.prank(user);
        
        uint256 id = worldState.generateFragmentId();
        assertTrue(id >= 1 && id <= 12, "Fuzz: FragmentId out of range");
    }

}
