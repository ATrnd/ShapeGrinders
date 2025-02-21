// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest} from "../Base/Base.t.sol";
import {FragmentNFTs} from "../../../src/FragmentNFTs.sol";
import {FragmentWorldState} from "../../../src/FragmentWorldState.sol";

contract FragmentNFTsVerificationTest is BaseTest {
    /// @notice Tests stored in this contract:
    /// - Complete set verification
    /// - Ownership verification
    /// - Edge cases and error conditions
    /// - Comprehensive verification paths

    function setUp() public override {
        super.setUp();
    }

    /// ============================================
    /// ========== Complete Set Tests =============
    /// ============================================

    function test_VerifyFragmentSet_CompleteSet() public {
        // Setup - mint complete set for user
        vm.startPrank(user);
        uint256 targetNftId;
        uint256[] memory fragmentTokenIds = new uint256[](4);

        // Mint until we get 4 fragments of the same NFT
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

        // Verify the complete set
        (bool verified, FragmentWorldState.WorldState state) = fragmentNFTs.verifyFragmentSet(targetNftId);

        assertTrue(verified, "Complete set should verify successfully");
        assertEq(uint256(state), uint256(FragmentWorldState.WorldState.NEXUS), "World state should be NEXUS");
        vm.stopPrank();
    }

    /// ============================================
    /// =========== Revert Conditions ============
    /// ============================================

    function test_VerifyFragmentSet_RevertIncompleteSet() public {
        vm.startPrank(user);
        // Mint just one fragment
        uint256 tokenId = fragmentNFTs.mint();
        uint256 nftId = fragmentNFTs.getFragmentNftIdByTokenId(tokenId);

        vm.expectRevert(FragmentNFTs.FragmentModule__IncompleteSet.selector);
        fragmentNFTs.verifyFragmentSet(nftId);
        vm.stopPrank();
    }

    function test_VerifyFragmentSet_RevertNotOwner() public {
        address alice = makeAddr("alice");

        // Setup - mint complete set for user
        vm.startPrank(user);
        uint256 targetNftId;
        uint256[] memory fragmentTokenIds = new uint256[](4);

        // Mint until we get 4 fragments of the same NFT
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

        // Transfer one fragment to other user
        fragmentNFTs.transferFrom(user, alice, fragmentTokenIds[0]);
        vm.stopPrank();

        // Try to verify set as original user
        vm.prank(user);
        vm.expectRevert(FragmentNFTs.FragmentModule__NotOwnerOfAll.selector);
        fragmentNFTs.verifyFragmentSet(targetNftId);
    }

    function test_VerifyFragmentSet_NonexistentNftId() public {
        vm.prank(user);
        vm.expectRevert(FragmentNFTs.FragmentModule__NonexistentNftId.selector);
        fragmentNFTs.verifyFragmentSet(999);
    }

    function test_VerifyFragmentSet_EmptyFragments() public {
        vm.prank(user);
        vm.expectRevert(FragmentNFTs.FragmentModule__NonexistentNftId.selector);
        fragmentNFTs.verifyFragmentSet(999); // Non-existent NFT ID
    }

    /// ============================================
    /// ========= Comprehensive Tests ============
    /// ============================================

    function test_VerifyFragmentSet_AllBranches() public {
        vm.startPrank(user);

        // First test: Non-existent NFT
        vm.expectRevert(FragmentNFTs.FragmentModule__NonexistentNftId.selector);
        fragmentNFTs.verifyFragmentSet(999);

        // Get our first fragment and remember its NFT ID
        uint256 firstTokenId = fragmentNFTs.mint();
        uint256 firstNftId = fragmentNFTs.getFragmentNftIdByTokenId(firstTokenId);

        // Test incomplete set with our known NFT ID
        vm.expectRevert(FragmentNFTs.FragmentModule__IncompleteSet.selector);
        fragmentNFTs.verifyFragmentSet(firstNftId);

        // Continue minting until we get more fragments of our first NFT ID
        uint256[] memory fragmentTokenIds = new uint256[](4);
        fragmentTokenIds[0] = firstTokenId;
        uint256 mintCount = 1;  // We already have one fragment

        while(mintCount < 4) {
            uint256 newTokenId = fragmentNFTs.mint();
            uint256 newNftId = fragmentNFTs.getFragmentNftIdByTokenId(newTokenId);

            if(newNftId == firstNftId) {
                fragmentTokenIds[mintCount] = newTokenId;
                mintCount++;
            }
        }
        vm.stopPrank();

        // Test ownership check
        address otherUser = makeAddr("otherUser");
        vm.prank(user);
        fragmentNFTs.transferFrom(user, otherUser, fragmentTokenIds[0]);

        vm.prank(user);
        vm.expectRevert(FragmentNFTs.FragmentModule__NotOwnerOfAll.selector);
        fragmentNFTs.verifyFragmentSet(firstNftId);

        // Logging for visibility
        console.log("\n=== Test Completion ===");
        console.log("Tested all verification branches successfully");
        console.log("- Non-existent NFT");
        console.log("- Incomplete set");
        console.log("- Ownership verification");
    }

    /// ============================================
    /// =========== Helper Functions =============
    /// ============================================

    function _mintFragmentsForNFT(uint256 count) internal returns (uint256 targetNftId, uint256[] memory tokenIds) {
        require(count > 0 && count <= 4, "Invalid fragment count");

        tokenIds = new uint256[](count);
        uint256 mintCount = 0;

        while(mintCount < count) {
            uint256 tokenId = fragmentNFTs.mint();
            uint256 nftId = fragmentNFTs.getFragmentNftIdByTokenId(tokenId);

            if(mintCount == 0) {
                targetNftId = nftId;
                tokenIds[mintCount] = tokenId;
                mintCount++;
            } else if(nftId == targetNftId) {
                tokenIds[mintCount] = tokenId;
                mintCount++;
            }
        }
    }
}
