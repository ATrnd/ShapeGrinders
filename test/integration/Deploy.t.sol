// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DeployScript} from "../../script/Deploy.s.sol";
import {FragmentWorldState} from "../../src/FragmentWorldState.sol";

contract DeployTest is Test {
    DeployScript public deployer;
    address public deployerAddress;

    function setUp() public {
        deployerAddress = makeAddr("deployer");
        vm.deal(deployerAddress, 100 ether);
        deployer = new DeployScript(deployerAddress);
    }

    function test_DeployScript() public {
        // Run deployment
        deployer.run();

        // Get deployed contract address
        address worldStateAddress = address(deployer.world_state());

        // Verify contract deployment
        assertTrue(worldStateAddress != address(0), "WorldState not deployed");
        assertTrue(worldStateAddress.code.length > 0, "No code at WorldState address");

        // Verify initial state
        FragmentWorldState worldState = FragmentWorldState(worldStateAddress);
        assertEq(
            uint256(worldState.s_worldState()),
            uint256(FragmentWorldState.WorldState.NEXUS),
            "Initial state should be NEXUS"
        );

        // Verify deployer
        assertEq(deployer.deployer(), deployerAddress, "Incorrect deployer address");
    }

    function test_DeployScript_SetUp() public {
        // Test that setUp executes without reverting
        deployer.setUp();
    }

    function test_DeployScript_GasUsage() public {
        // Measure gas usage
        uint256 gasStart = gasleft();
        deployer.run();
        uint256 gasUsed = gasStart - gasleft();

        // Log gas usage for analysis
        console.log("Gas used for deployment:", gasUsed);

        // Verify gas usage is within reasonable limits
        assertTrue(gasUsed < 5_000_000, "Deployment gas too high");
    }

}
