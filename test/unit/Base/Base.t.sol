// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {FragmentWorldState} from "../../../src/FragmentWorldState.sol";
import {FragmentNFTs} from "../../../src/FragmentNFTs.sol";
import {FragmentMetadataLib} from "../../../src/FragmentMetadataLib.sol";
import {FragmentMetadataLibTestHelper} from "../../mock/FragmentMetadataLibTestHelper.sol";

contract BaseTest is Test {
    using stdJson for string;
    using Strings for uint256;

    // Common contract instances
    FragmentNFTs public fragmentNFTs;
    FragmentMetadataLibTestHelper public helper;
    FragmentWorldState public fragmentWorldState;

    // Common addresses
    address public owner;
    address public user;

    // Initial NFT IDs
    uint256[] public initialFragmentNftIds;

    function setUp() public virtual {
        // Setup addresses
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Setup contracts
        fragmentWorldState = new FragmentWorldState();
        helper = new FragmentMetadataLibTestHelper();

        // Setup initial NFT IDs
        initialFragmentNftIds = new uint256[](3);
        initialFragmentNftIds[0] = 1;
        initialFragmentNftIds[1] = 2;
        initialFragmentNftIds[2] = 3;

        // Deploy main contract
        vm.prank(owner);
        fragmentNFTs = new FragmentNFTs(
            owner,
            address(fragmentWorldState),
            initialFragmentNftIds
        );
    }

    // =======================
    // === Helper Functions ==
    // =======================

    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if(strBytes.length < prefixBytes.length) {
            return false;
        }

        for(uint i = 0; i < prefixBytes.length; i++) {
            if(strBytes[i] != prefixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function _stripBase64Prefix(string memory uri) internal pure returns (string memory) {
        bytes memory uriBytes = bytes(uri);
        string memory prefix = "data:application/json;base64,";
        bytes memory prefixBytes = bytes(prefix);

        require(uriBytes.length > prefixBytes.length, "Invalid URI format");

        bytes memory result = new bytes(uriBytes.length - prefixBytes.length);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = uriBytes[i + prefixBytes.length];
        }

        return string(result);
    }

    function _decodeBase64JsonContent(string memory uri) internal pure returns (string memory) {
        string memory base64Content = _stripBase64Prefix(uri);
        return string(Base64.decode(base64Content));
    }

    function _containsString(string memory source, string memory searchFor) internal pure returns (bool) {
        bytes memory sourceBytes = bytes(source);
        bytes memory searchBytes = bytes(searchFor);

        if (searchBytes.length > sourceBytes.length) return false;

        for (uint i = 0; i <= sourceBytes.length - searchBytes.length; i++) {
            bool found = true;
            for (uint j = 0; j < searchBytes.length; j++) {
                if (sourceBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }

    // Common setup functions for specific test scenarios
    function _mintCompleteSet() internal virtual returns (uint256 targetNftId, uint256[] memory fragmentTokenIds) {
        fragmentTokenIds = new uint256[](4);
        uint256 mintCount = 0;

        while(mintCount < 4) {
            uint256 tokenId = fragmentNFTs.mint();
            uint256 nftId = fragmentNFTs.getFragmentNftIdByTokenId(tokenId);

            if(mintCount == 0) {
                targetNftId = nftId;
                fragmentTokenIds[mintCount] = tokenId;
                mintCount++;
            } else if(nftId == targetNftId) {
                fragmentTokenIds[mintCount] = tokenId;
                mintCount++;
            }
        }
    }

    function _mintPartialSet(uint256 count) internal returns (uint256 targetNftId, uint256[] memory fragmentTokenIds) {
        require(count > 0 && count < 4, "Invalid partial set count");

        fragmentTokenIds = new uint256[](count);
        uint256 mintCount = 0;

        while(mintCount < count) {
            uint256 tokenId = fragmentNFTs.mint();
            uint256 nftId = fragmentNFTs.getFragmentNftIdByTokenId(tokenId);

            if(mintCount == 0) {
                targetNftId = nftId;
                fragmentTokenIds[mintCount] = tokenId;
                mintCount++;
            } else if(nftId == targetNftId) {
                fragmentTokenIds[mintCount] = tokenId;
                mintCount++;
            }
        }
    }

    /// ============================================
    /// ========= String Helper Tests ============
    /// ============================================

    function test_StartsWith() public pure {
        // Test basic matching
        assertTrue(_startsWith("Hello World", "Hello"), "Should match prefix");
        assertTrue(_startsWith("Test", "Test"), "Should match exact string");
        assertFalse(_startsWith("Hello", "Hello World"), "Should fail when prefix longer");
        assertFalse(_startsWith("Hello World", "world"), "Should fail on non-matching prefix");
        assertTrue(_startsWith("", ""), "Should handle empty strings");
    }

}
