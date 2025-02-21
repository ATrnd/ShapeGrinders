// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Fragment World State Contract
 * @author ATrnd
 * @notice Manages world state for Fragment NFTs and provides temporary random number generation
 * @dev Core contract for world state management with a basic RNG implementation
 */
contract FragmentWorldState {
    /**
     * @notice Possible states in the Fragment world
     * @dev Used to track the current state of fragments and the overall world
     */
    enum WorldState { NEXUS, FLUX, CORE, GEAR }

    /**
     * @notice Current state of the Fragment world
     * @dev Public state variable tracking current world phase
     */
    WorldState public s_worldState;

    /**
     * @notice Initializes the contract with NEXUS as the default world state
     */
    constructor() {
        s_worldState = WorldState.NEXUS;
    }

    /**
     * @notice Generates a pseudo-random index within a given range
     * @dev WARNING: This is a temporary implementation using block.timestamp.
     * It is not secure for production.
     * @param maxLength The maximum value (exclusive) for the generated index
     * @param salt Additional entropy source for randomness
     * @return A pseudo-random number between 0 and maxLength-1
     */
    function generateRandomIndex(uint256 maxLength, uint256 salt) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            salt
        ))) % maxLength;
    }
}
