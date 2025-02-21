// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FragmentNFTs} from "../../../src/FragmentNFTs.sol";
import {FragmentWorldState} from "../../../src/FragmentWorldState.sol";
import {FragmentMetadataLib} from "../../../src/FragmentMetadataLib.sol";
import {FragmentMetadataLibBaseTest} from "./FragmentMetadataLib.Base.t.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "solady/utils/Base64.sol";

contract FragmentMetadataLibURITest is FragmentMetadataLibBaseTest {
    /// @notice Tests stored in this contract:
    /// - Token URI generation and validation
    /// - Base64 encoding and decoding
    /// - Image URI construction
    /// - Complete metadata generation

    function setUp() public override {
        super.setUp();
    }

    /// ============================================
    /// =========== Basic URI Tests ==============
    /// ============================================

    function test_TokenURIReturnsValue() public {
        (, , string memory uri) = _mintTokenAndGetMetadata();

        assertTrue(bytes(uri).length > 0, "Token URI should not be empty");
        assertTrue(_validateMetadataStructure(_decodeMetadataUri(uri)), "Invalid metadata structure");
    }

    function test_TokenURIHasBase64Prefix() public {
        (, , string memory uri) = _mintTokenAndGetMetadata();

        assertTrue(
            _startsWith(uri, "data:application/json;base64,"),
            "Token URI should be base64 encoded"
        );
    }

    /// ============================================
    /// ========= Base64 Processing =============
    /// ============================================

    function test_StripBase64Prefix() public view {
        // Create test metadata and URI
        FragmentMetadataLib.FragmentMetadata memory metadata = _createDefaultTestMetadata();
        string memory baseUri = "ipfs://test";
        string memory imageUri = metadataHelper.constructImageURI(baseUri, metadata);
        string memory attributes = metadataHelper.constructAttributes(metadata);

        // Create and encode test JSON
        string memory testJson = _createTestMetadataJson(
            "Test Fragment",
            "Test Description",
            imageUri,
            attributes
        );

        string memory fullUri = string(
            abi.encodePacked("data:application/json;base64,", testJson)
        );

        string memory stripped = _stripBase64Prefix(fullUri);
        assertEq(stripped, testJson, "Base64 prefix stripping failed");
    }

    function test_DecodeBase64Json() public {
        (, FragmentNFTs.Fragment memory fragData, string memory uri) = _mintTokenAndGetMetadata();

        // Strip the prefix
        string memory base64Content = _stripBase64Prefix(uri);

        // Decode using the method from the working example
        bytes memory decodedBytes = Base64.decode(base64Content);
        string memory decodedJson = string(decodedBytes);

        console.log("Decoded JSON:", decodedJson); // Add this to see the actual structure

        // Validate the structure first
        assertTrue(_validateMetadataStructure(decodedJson), "Invalid JSON structure");

        // Test for the presence of the NFT ID in a more flexible way
        string memory nftIdString = Strings.toString(fragData.fragmentNftId);
    assertTrue(
        _containsString(decodedJson, nftIdString),
        "NFT ID not found in metadata"
    );
    }

    /// ============================================
    /// ========= Image URI Construction =========
    /// ============================================

    function test_ConstructImageURI() public view {
        FragmentMetadataLib.FragmentMetadata memory metadata = _createCustomTestMetadata(
            FragmentWorldState.WorldState.NEXUS,
            1,
            2,
            3
        );

        string memory baseUri = "ipfs://QmExample";
        string memory result = metadataHelper.constructImageURI(baseUri, metadata);
        string memory expected = "ipfs://QmExample/1_2.json";

        assertEq(result, expected, "Image URI construction failed");
    }

    function test_ConstructImageURI_EmptyBaseUri() public view {
        FragmentMetadataLib.FragmentMetadata memory metadata = _createCustomTestMetadata(
            FragmentWorldState.WorldState.NEXUS,
            1,
            2,
            3
        );

        string memory result = metadataHelper.constructImageURI("", metadata);
        string memory expected = "/1_2.json";
        assertEq(result, expected, "Empty base URI handling failed");
    }

    /// ============================================
    /// ======= Complete URI Generation ==========
    /// ============================================

    function test_CompleteTokenURIGeneration() public {
        // Mint token and get metadata
        (uint256 tokenId, FragmentNFTs.Fragment memory fragData, string memory uri) = _mintTokenAndGetMetadata();

        console.log("\n=== Token Metadata Generation Test ===");
        console.log("Token ID:", tokenId);
        console.log("Fragment NFT ID:", fragData.fragmentNftId);
        console.log("Fragment ID:", fragData.fragmentId);

        // Decode and validate URI
        string memory jsonContent = _decodeMetadataUri(uri);
        console.log("\nDecoded Metadata:", jsonContent);

        // Validate structure
        assertTrue(_validateMetadataStructure(jsonContent), "Invalid metadata structure");

        // Validate specific fields
        string[] memory requiredFields = new string[](3);
        requiredFields[0] = string(abi.encodePacked("Fragment #", Strings.toString(tokenId)));
        requiredFields[1] = "Fragment NFT for collection";
        requiredFields[2] = Strings.toString(fragData.fragmentNftId);

        assertTrue(
            _validateMetadataField(jsonContent, "name", requiredFields[0]),
            "Invalid name in metadata"
        );
        assertTrue(
            _validateMetadataField(jsonContent, "description", requiredFields[1]),
            "Invalid description in metadata"
        );
        assertTrue(
            _containsString(jsonContent, requiredFields[2]),
            "Missing NFT ID in metadata"
        );

        console.log("\n=== Validation Complete ===");
    }
}
