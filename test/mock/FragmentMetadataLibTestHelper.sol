// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {FragmentMetadataLib} from "../../src/FragmentMetadataLib.sol";
import {FragmentWorldState} from "../../src/FragmentWorldState.sol";

contract FragmentMetadataLibTestHelper {
    using FragmentMetadataLib for FragmentMetadataLib.FragmentMetadata;

    function constructImageURI(string memory baseUri, FragmentMetadataLib.FragmentMetadata memory metadata)
        public pure returns (string memory)
    {
        return FragmentMetadataLib.constructImageURI(baseUri, metadata);
    }

    function constructAttributes(FragmentMetadataLib.FragmentMetadata memory metadata)
        public pure returns (string memory)
    {
        return FragmentMetadataLib.constructAttributes(metadata);
    }

    function createAttribute(string memory traitType, string memory value)
        public pure returns (string memory)
    {
        return FragmentMetadataLib.createAttribute(traitType, value);
    }

    function worldStateToString(FragmentWorldState.WorldState worldState)
        public pure returns (string memory)
    {
        return FragmentMetadataLib.worldStateToString(worldState);
    }
}
