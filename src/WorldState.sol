// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title World State Contract
/// @author ATrnd
/// @notice Manages global state and randomization for the Fragment NFT system
/// @dev Provides world state enums and random number generation for fragment minting
contract WorldState {
    /// @notice Enum representing different possible states of the world
    /// @dev Used to determine fragment properties and interactions
    /// @param NEXUS default World state (1)
    /// @param FLUX World state (2)
    /// @param CORE World state (3)
    /// @param GEAR World state (4)
    enum WorldState_s { NEXUS, FLUX, CORE, GEAR }

    /// @notice Current state of the world
    /// @dev Initialized to NEXUS in constructor
    WorldState_s public worldState_s;

    /// @notice Initializes the world state contract
    /// @dev Sets initial world state to NEXUS
    constructor() {
        worldState_s = WorldState_s.NEXUS;
    }

    /// @notice Generates a pseudo-random fragment ID
    /// @dev TEMPORARY TEST FUNCTION - Uses block.timestamp and msg.sender for randomization
    /// @dev This function is for testing purposes only and will be replaced with a secure randomization mechanism in production
    /// @return A number between 1 and 12 inclusive
    function generateFragmentId() public view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 12) + 1;
    }

    /// @notice Generates a pseudo-random index within a given range
    /// @dev TEMPORARY TEST FUNCTION - Uses block.timestamp, msg.sender, and a salt for randomization
    /// @dev This function is for testing purposes only and will be replaced with a secure randomization mechanism in production
    /// @param maxLength The maximum value for the range (exclusive)
    /// @param salt Additional entropy source to prevent prediction
    /// @return A number between 0 and maxLength-1 inclusive
    function generateRandomIndex(uint256 maxLength, uint256 salt) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            salt
        ))) % maxLength;
    }
}
