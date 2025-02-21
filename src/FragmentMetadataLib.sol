// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {FragmentWorldState} from "./FragmentWorldState.sol";

/**
 * @title Fragment Metadata Library
 * @author ATrnd
 * @notice Library for handling Fragment NFT metadata generation and manipulation
 * @dev Provides functions for creating and formatting NFT metadata including attributes and URIs
 */
library FragmentMetadataLib {
    using Strings for uint256;

    /**
     * @notice Structure containing all metadata for a Fragment NFT
     * @param fragmentWorldState Current world state of the fragment
     * @param fragmentNftId ID of the complete NFT this fragment belongs to
     * @param fragmentId Unique identifier within the fragment set (1-4)
     * @param fragmentTokenId Token ID of this specific fragment
     */
    struct FragmentMetadata {
        FragmentWorldState.WorldState fragmentWorldState;
        uint256 fragmentNftId;
        uint256 fragmentId;
        uint256 fragmentTokenId;
    }

    /**
     * @notice Creates a complete token URI for a Fragment NFT
     * @dev Generates a base64 encoded JSON string containing all metadata
     * @param baseUri Base URI for the token's image
     * @param metadata Struct containing all fragment metadata
     * @return Complete token URI as a base64 encoded JSON string
     */
    function createTokenURI(string memory baseUri, FragmentMetadata memory metadata) internal pure returns (string memory) {
        string memory imageUri = constructImageURI(baseUri, metadata);
        string memory attributes = constructAttributes(metadata);

        bytes memory jsonData = abi.encodePacked(
            '{',
            '"name": "Fragment #', metadata.fragmentTokenId.toString(), '",',
            '"description": "Fragment NFT for collection",',
            '"image": "', imageUri, '",',
            '"attributes": ', attributes,
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(jsonData)
            )
        );
    }

    /**
     * @notice Constructs the image URI for a fragment
     * @dev Combines base URI with fragment identifiers
     * @param baseUri Base URI for the image storage location
     * @param metadata Fragment metadata containing ID information
     * @return Complete image URI string
     */
    function constructImageURI(string memory baseUri, FragmentMetadata memory metadata) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                baseUri,
                "/",
                metadata.fragmentNftId.toString(),
                "_",
                metadata.fragmentId.toString(),
                ".json"
            )
        );
    }

    /**
     * @notice Creates a JSON array of attributes for the fragment
     * @dev Generates metadata attributes including world state and IDs
     * @param metadata Fragment metadata to generate attributes from
     * @return JSON string containing all fragment attributes
     */
    function constructAttributes(FragmentMetadata memory metadata) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '[',
                createAttribute("World State", worldStateToString(metadata.fragmentWorldState)), ',',
                createAttribute("NFT ID", metadata.fragmentNftId.toString()), ',',
                createAttribute("Fragment ID", metadata.fragmentId.toString()),
                ']'
            )
        );
    }

    /**
     * @notice Creates a single attribute object for metadata
     * @dev Formats a trait type and value as a JSON object
     * @param traitType The name/type of the attribute
     * @param value The value of the attribute
     * @return JSON string representing the attribute
     */
    function createAttribute(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "', traitType, '", "value": "', value, '"}'
            )
        );
    }

    /**
     * @notice Converts world state enum to string representation
     * @dev Maps FragmentWorldState enum values to their string equivalents
     * @param worldState The world state to convert
     * @return String representation of the world state
     */
    function worldStateToString(FragmentWorldState.WorldState worldState) internal pure returns (string memory) {
        if (worldState == FragmentWorldState.WorldState.NEXUS) return "NEXUS";
        if (worldState == FragmentWorldState.WorldState.FLUX) return "FLUX";
        if (worldState == FragmentWorldState.WorldState.CORE) return "CORE";
        if (worldState == FragmentWorldState.WorldState.GEAR) return "GEAR";
        return "UNKNOWN";
    }
}
