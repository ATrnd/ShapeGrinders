// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FragmentNFTs} from "../../../src/FragmentNFTs.sol";
import {FragmentWorldState} from "../../../src/FragmentWorldState.sol";
import {FragmentMetadataLib} from "../../../src/FragmentMetadataLib.sol";
import {FragmentMetadataLibBaseTest} from "./FragmentMetadataLib.Base.t.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract FragmentMetadataLibAttributesTest is FragmentMetadataLibBaseTest {
    /// @notice Tests stored in this contract:
    /// - Attribute creation and validation
    /// - Empty and special character handling
    /// - World state string conversion
    /// - Attribute construction with various inputs

    function setUp() public override {
        super.setUp();
    }

    /// ============================================
    /// ======== Basic Attribute Tests ===========
    /// ============================================

    function test_CreateAttribute() public view {
        string memory result = metadataHelper.createAttribute("Test Trait", "Test Value");
        string memory expected = '{"trait_type": "Test Trait", "value": "Test Value"}';

        assertEq(result, expected, "Basic attribute creation failed");
    }

    function test_CreateAttribute_EmptyValues() public view {
        string memory result = metadataHelper.createAttribute("", "");
        string memory expected = '{"trait_type": "", "value": ""}';

        assertEq(result, expected, "Empty attribute handling failed");
    }

    function test_CreateAttribute_SpecialCharacters() public view {
        string memory result = metadataHelper.createAttribute(
            "Test/Special:Chars",
            "Value#With@Special"
        );
        string memory expected = '{"trait_type": "Test/Special:Chars", "value": "Value#With@Special"}';

        assertEq(result, expected, "Special characters handling failed");
    }

    /// ============================================
    /// ====== Attribute Construction Tests =======
    /// ============================================

    function test_ConstructAttributes() public view {
        FragmentMetadataLib.FragmentMetadata memory metadata = _createCustomTestMetadata(
            FragmentWorldState.WorldState.NEXUS,
            1,
            2,
            3
        );

        string memory result = metadataHelper.constructAttributes(metadata);

        // Check world state
        string memory worldStateAttr = '{"trait_type": "World State", "value": "NEXUS"}';
        assertTrue(
            _containsString(result, worldStateAttr),
            "World State attribute not found"
        );

        // Check NFT ID
        string memory nftIdAttr = string(
            abi.encodePacked('{"trait_type": "NFT ID", "value": "', Strings.toString(metadata.fragmentNftId), '"}')
        );
        assertTrue(
            _containsString(result, nftIdAttr),
            "NFT ID attribute not found"
        );

        // Check Fragment ID
        string memory fragmentIdAttr = string(
            abi.encodePacked('{"trait_type": "Fragment ID", "value": "', Strings.toString(metadata.fragmentId), '"}')
        );
        assertTrue(
            _containsString(result, fragmentIdAttr),
            "Fragment ID attribute not found"
        );
    }

    function test_ConstructAttributes_MaxValues() public view {
        FragmentMetadataLib.FragmentMetadata memory metadata = _createCustomTestMetadata(
            FragmentWorldState.WorldState.NEXUS,
            type(uint256).max,
            type(uint256).max,
            type(uint256).max
        );

        string memory result = metadataHelper.constructAttributes(metadata);

        // Create expected attribute pattern for max value
        string memory maxValueAttr = string(
            abi.encodePacked('{"trait_type": "NFT ID", "value": "', Strings.toString(type(uint256).max), '"}')
        );

        assertTrue(
            _containsString(result, maxValueAttr),
            "Max value attribute construction failed"
        );

        // Verify overall structure
        assertTrue(
            _containsString(result, '[') && _containsString(result, ']'),
            "Invalid JSON array structure"
        );
    }

    /// ============================================
    /// ======== World State Tests ==============
    /// ============================================

    function test_WorldStateToString_AllStates() public view {
        // Test NEXUS state
        assertEq(
            metadataHelper.worldStateToString(FragmentWorldState.WorldState.NEXUS),
            "NEXUS",
            "NEXUS conversion failed"
        );

        // Test FLUX state
        assertEq(
            metadataHelper.worldStateToString(FragmentWorldState.WorldState.FLUX),
            "FLUX",
            "FLUX conversion failed"
        );

        // Test CORE state
        assertEq(
            metadataHelper.worldStateToString(FragmentWorldState.WorldState.CORE),
            "CORE",
            "CORE conversion failed"
        );

        // Test GEAR state
        assertEq(
            metadataHelper.worldStateToString(FragmentWorldState.WorldState.GEAR),
            "GEAR",
            "GEAR conversion failed"
        );

        console.log("\n=== World State Conversion Test ===");
        console.log("Successfully verified all world state conversions");
    }

    /// ============================================
    /// ========= Comprehensive Tests ============
    /// ============================================

    function test_AttributeIntegration() public view {
        // Create metadata with various states and values
        FragmentMetadataLib.FragmentMetadata[] memory testCases = new FragmentMetadataLib.FragmentMetadata[](4);

        testCases[0] = _createCustomTestMetadata(FragmentWorldState.WorldState.NEXUS, 1, 1, 1);
        testCases[1] = _createCustomTestMetadata(FragmentWorldState.WorldState.FLUX, 2, 2, 2);
        testCases[2] = _createCustomTestMetadata(FragmentWorldState.WorldState.CORE, 3, 3, 3);
        testCases[3] = _createCustomTestMetadata(FragmentWorldState.WorldState.GEAR, 4, 4, 4);

        console.log("\n=== Testing Attribute Generation for All States ===");

        for (uint256 i = 0; i < testCases.length; i++) {
            string memory attributes = metadataHelper.constructAttributes(testCases[i]);

            console.log("\nTesting State:", metadataHelper.worldStateToString(testCases[i].fragmentWorldState));
            console.log("Generated Attributes:", attributes);

            // Check world state attribute
            string memory worldStateAttr = string(
                abi.encodePacked(
                    '{"trait_type": "World State", "value": "',
                    metadataHelper.worldStateToString(testCases[i].fragmentWorldState),
                    '"}'
                )
            );
            assertTrue(
                _containsString(attributes, worldStateAttr),
                "World state attribute not found"
            );

            // Check NFT ID attribute
            string memory nftIdAttr = string(
                abi.encodePacked(
                    '{"trait_type": "NFT ID", "value": "',
                    Strings.toString(testCases[i].fragmentNftId),
                    '"}'
                )
            );
            assertTrue(
                _containsString(attributes, nftIdAttr),
                "NFT ID attribute not found"
            );
        }
    }
}
