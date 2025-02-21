// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FragmentWorldState} from "../src/FragmentWorldState.sol";

contract DeployScript is Script {
    FragmentWorldState public world_state;
    address public deployer;

    constructor(address _deployer) {
        deployer = _deployer;
    }

    function setUp() public {}

    function run() public {
        vm.startBroadcast(deployer);  // Use specific deployer address
        world_state = new FragmentWorldState();
        vm.stopBroadcast();
    }
}

// pragma solidity ^0.8.28;
//
// import {Script, console} from "forge-std/Script.sol";
// import {FragmentWorldState} from "../src/FragmentWorldState.sol";
//
// contract DeployScript is Script {
//     FragmentWorldState public world_state;
//
//     function setUp() public {}
//
//     function run() public {
//         vm.startBroadcast();
//         world_state = new FragmentWorldState();
//         vm.stopBroadcast();
//     }
//
// }
