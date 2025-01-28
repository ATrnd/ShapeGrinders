// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {WorldState} from "../src/WorldState.sol";

contract DeployScript is Script {
    WorldState public world_state;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        world_state = new WorldState();
        vm.stopBroadcast();
    }

}
