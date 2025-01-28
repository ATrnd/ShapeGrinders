// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {WorldState} from "./WorldState.sol";

/// @title Fragment Metadata Library
/// @author ATrnd
/// @notice Library for handling Fragment NFT metadata generation and encoding
/// @dev Provides utilities for constructing NFT metadata URIs and JSON formatting
/// @dev Implements ERC721 metadata standard with custom attributes
library FragmentMetadataLib {
    using Strings for uint256;

    /// @notice Structure containing all metadata for a fragment
    /// @param worldState The current state enum from WorldState contract
    /// @param nftId The ID of the complete NFT this fragment belongs to
    /// @param fragmentId The unique identifier of this fragment within its NFT
    /// @param tokenId The ERC721 token ID of this fragment
    struct FragmentMetadata {
        WorldState.WorldState_s worldState;
        uint256 nftId;
        uint256 fragmentId;
        uint256 tokenId;
    }

    /// @notice Creates the complete base64 encoded token URI
    /// @dev Combines image URI and attributes into a base64 encoded JSON string
    /// @dev Format follows OpenSea metadata standards
    /// @param baseUri Base IPFS URI where fragment images are stored
    /// @param metadata Fragment metadata structure containing all necessary data
    /// @return Base64 encoded JSON string containing complete token metadata
    function createTokenURI(
        string memory baseUri,
        FragmentMetadata memory metadata
    ) internal pure returns (string memory) {
        string memory imageUri = _constructImageURI(baseUri, metadata);
        string memory attributes = _constructAttributes(metadata);

        bytes memory jsonData = abi.encodePacked(
            '{',
            '"name": "Fragment #', metadata.tokenId.toString(), '",',
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

    /// @notice Constructs the IPFS image URI for a fragment
    /// @dev Combines base URI with fragment identifiers to create unique image path
    /// @param baseUri Base IPFS URI where images are stored
    /// @param metadata Fragment metadata containing necessary IDs
    /// @return Complete IPFS URI string pointing to fragment's image
    function _constructImageURI(
        string memory baseUri,
        FragmentMetadata memory metadata
    ) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                baseUri,
                "/",
                metadata.nftId.toString(),
                "_",
                metadata.fragmentId.toString(),
                ".json"
            )
        );
    }

    /// @notice Constructs the attributes JSON array for the fragment
    /// @dev Creates standardized metadata attributes following OpenSea format
    /// @param metadata Fragment metadata containing all attribute values
    /// @return JSON string containing formatted attributes array
    function _constructAttributes(
        FragmentMetadata memory metadata
    ) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '[',
                _createAttribute("World State", _worldStateToString(metadata.worldState)), ',',
                _createAttribute("NFT ID", metadata.nftId.toString()), ',',
                _createAttribute("Fragment ID", metadata.fragmentId.toString()),
                ']'
            )
        );
    }

    /// @notice Creates a single metadata attribute JSON object
    /// @dev Formats a key-value pair as a trait object
    /// @param traitType The name/type of the attribute
    /// @param value The value of the attribute
    /// @return JSON string for a single attribute
    function _createAttribute(
        string memory traitType,
        string memory value
    ) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "', traitType, '", "value": "', value, '"}'
            )
        );
    }

    /// @notice Converts WorldState enum to its string representation
    /// @dev Maps each enum value to its corresponding string name
    /// @param state The WorldState enum to convert
    /// @return String representation of the world state
    function _worldStateToString(
        WorldState.WorldState_s state
    ) private pure returns (string memory) {
        if (state == WorldState.WorldState_s.NEXUS) return "NEXUS";
        if (state == WorldState.WorldState_s.FLUX) return "FLUX";
        if (state == WorldState.WorldState_s.CORE) return "CORE";
        if (state == WorldState.WorldState_s.GEAR) return "GEAR";
        return "UNKNOWN";
    }
}
