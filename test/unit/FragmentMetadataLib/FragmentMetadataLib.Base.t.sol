// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest} from "../Base/Base.t.sol";
import {FragmentNFTs} from "../../../src/FragmentNFTs.sol";
import {FragmentWorldState} from "../../../src/FragmentWorldState.sol";
import {FragmentMetadataLib} from "../../../src/FragmentMetadataLib.sol";
import {FragmentMetadataLibTestHelper} from "../../mock/FragmentMetadataLibTestHelper.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract FragmentMetadataLibBaseTest is BaseTest {
    /// @notice Base contract for FragmentMetadataLib tests
    /// Provides common setup, types, and helper functions for metadata testing

    // Helper contract instance specific to metadata tests
    FragmentMetadataLibTestHelper internal metadataHelper;

    // Common test data structure
    struct TestMetadata {
        FragmentWorldState.WorldState worldState;
        uint256 nftId;
        uint256 fragmentId;
        uint256 tokenId;
    }

    function setUp() public virtual override {
        // Call parent setup first
        super.setUp();

        // Initialize metadata specific helper
        metadataHelper = new FragmentMetadataLibTestHelper();
    }

    /// ============================================
    /// =========== Helper Functions =============
    /// ============================================

    /// @notice Creates a test metadata struct with default values
    function _createDefaultTestMetadata() internal pure returns (FragmentMetadataLib.FragmentMetadata memory) {
        return FragmentMetadataLib.FragmentMetadata({
            fragmentWorldState: FragmentWorldState.WorldState.NEXUS,
            fragmentNftId: 1,
            fragmentId: 1,
            fragmentTokenId: 1
        });
    }

    /// @notice Creates a test metadata struct with custom values
    function _createCustomTestMetadata(
        FragmentWorldState.WorldState worldState,
        uint256 nftId,
        uint256 fragmentId,
        uint256 tokenId
    ) internal pure returns (FragmentMetadataLib.FragmentMetadata memory) {
        return FragmentMetadataLib.FragmentMetadata({
            fragmentWorldState: worldState,
            fragmentNftId: nftId,
            fragmentId: fragmentId,
            fragmentTokenId: tokenId
        });
    }

    /// @notice Decodes a base64 encoded JSON URI
    function _decodeMetadataUri(string memory uri) internal pure returns (string memory) {
        string memory base64Content = _stripBase64Prefix(uri);
        return string(Base64.decode(base64Content));
    }

    /// @notice Validates the basic structure of metadata JSON
    function _validateMetadataStructure(string memory jsonContent) internal pure returns (bool) {
        return (
            _containsString(jsonContent, '"name":') &&
            _containsString(jsonContent, '"description":') &&
            _containsString(jsonContent, '"image":') &&
            _containsString(jsonContent, '"attributes":')
        );
    }

    /// @notice Creates a complete metadata JSON string for testing
    function _createTestMetadataJson(
        string memory name,
        string memory description,
        string memory image,
        string memory attributes
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', image, '",',
                '"attributes": ', attributes,
                '}'
            )
        );
    }

    /// @notice Mints a test token and returns its metadata
    function _mintTokenAndGetMetadata() internal returns (
        uint256 tokenId,
        FragmentNFTs.Fragment memory fragData,
        string memory tokenUri
    ) {
        vm.prank(user);
        tokenId = fragmentNFTs.mint();
        fragData = fragmentNFTs.getFragmentData(tokenId);
        tokenUri = fragmentNFTs.tokenURI(tokenId);
        vm.stopPrank();
    }

    /// @notice Validates specific metadata field values
    function _validateMetadataField(
        string memory jsonContent,
        string memory fieldName,
        string memory expectedValue
    ) internal pure returns (bool) {
        string memory fieldCheck = string(
            abi.encodePacked('"', fieldName, '": "', expectedValue, '"')
        );
        return _containsString(jsonContent, fieldCheck);
    }

    /// @notice Generates test attribute data
    function _createTestAttributes() internal pure returns (string memory) {
        return '[{"trait_type": "Test", "value": "Value"}]';
    }

    /// @notice Asserts equality of two metadata structs
    function _assertMetadataEqual(
        FragmentMetadataLib.FragmentMetadata memory a,
        FragmentMetadataLib.FragmentMetadata memory b
    ) internal pure {
        require(
            a.fragmentWorldState == b.fragmentWorldState &&
            a.fragmentNftId == b.fragmentNftId &&
            a.fragmentId == b.fragmentId &&
            a.fragmentTokenId == b.fragmentTokenId,
            "Metadata mismatch"
        );
    }

    /// ============================================
    /// ============ Base URI Tests ==============
    /// ============================================

    function test_BaseSetup() public view {
        // Verify helper contract deployment
        assertTrue(address(metadataHelper) != address(0), "Metadata helper not initialized");

        // Verify we can create test metadata
        FragmentMetadataLib.FragmentMetadata memory testData = _createDefaultTestMetadata();
        assertEq(uint256(testData.fragmentWorldState), uint256(FragmentWorldState.WorldState.NEXUS), "Default world state incorrect");

        // Verify helper functions work
        string memory testJson = _createTestMetadataJson(
            "Test",
            "Description",
            "image.jpg",
            _createTestAttributes()
        );
        assertTrue(_validateMetadataStructure(testJson), "JSON structure validation failed");
    }
}
