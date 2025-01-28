// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {WorldState} from "../../src/WorldState.sol";
import {FragmentNFTs} from "../../src/FragmentNFTs.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FragmentNFTsTest is Test {
    FragmentNFTs public fragmentNFTs;
    WorldState public worldState;
    address public owner;
    address public user;

    function setUp() public {
        // Setup initial state
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Deploy contracts
        worldState = new WorldState();

        // Create initial NFT IDs array [1,2,3]
        uint256[] memory initialNftIds = new uint256[](3);
        initialNftIds[0] = 1;
        initialNftIds[1] = 2;
        initialNftIds[2] = 3;

        // Deploy FragmentNFTs with initial data
        vm.prank(owner);
        fragmentNFTs = new FragmentNFTs(
            owner,
            address(worldState),
            initialNftIds
        );
    }

    function test_MintFirstFragment() public {
        vm.prank(user);
        uint256 tokenId = fragmentNFTs.mint();

        // Verify token was minted to correct user
        assertEq(fragmentNFTs.ownerOf(tokenId), user);

        // Get fragment data
        FragmentNFTs.Fragment memory fragment = fragmentNFTs.getFragment(tokenId);

        // Verify fragment properties
        assertTrue(fragment.nft_id >= 1 && fragment.nft_id <= 3, "NFT ID out of range");
        assertTrue(fragment.fragment_id == 1, "First fragment ID should be 1");
        assertEq(uint256(fragment.world_state_s), uint256(WorldState.WorldState_s.NEXUS));
    }

    function test_MintAllFragmentsForOneNFT() public {
        vm.startPrank(user);

        uint256 maxMints = 12;
        uint256 targetNftId;
        uint256 completedFragments = 0;

        for(uint256 i = 0; i < maxMints && completedFragments < 4; i++) {
            uint256 tokenId = fragmentNFTs.mint();
            FragmentNFTs.Fragment memory fragment = fragmentNFTs.getFragment(tokenId);

            if(i == 0) {
                targetNftId = fragment.nft_id;
            }

            if(fragment.nft_id == targetNftId) {
                completedFragments++;
            }
        }

        vm.stopPrank();

        assertEq(fragmentNFTs.getFragmentsLeftForNFT(targetNftId), 0, "NFT should be completed");

        uint256[] memory remainingNfts = fragmentNFTs.getNFTsInCirculation();
        for(uint256 i = 0; i < remainingNfts.length; i++) {
            assertTrue(
                remainingNfts[i] != targetNftId,
                "Completed NFT should not be in circulation"
            );
        }
    }

    function test_RevertWhenNoNFTsAvailable() public {
        vm.startPrank(user);

        // Mint all possible fragments (3 NFTs * 4 fragments = 12 mints)
        for(uint256 i = 0; i < 12; i++) {
            fragmentNFTs.mint();
        }

        // Next mint should revert
        vm.expectRevert(FragmentNFTs.NoNFTsAvailable.selector);
        fragmentNFTs.mint();

        vm.stopPrank();
    }

    function testFuzz_MintWithDifferentUsers(address _user) public {
        vm.assume(_user != address(0));
        vm.assume(_user != address(this));
        // Ensure address is not a precompile
        vm.assume(uint160(_user) > 0xffff);
        // Avoid known contract addresses
        vm.assume(_user.code.length == 0);

        // Do the mint
        vm.startPrank(_user);
        uint256 tokenId = fragmentNFTs.mint();
        vm.stopPrank();

        // Verify ownership
        assertEq(fragmentNFTs.ownerOf(tokenId), _user);
    }

    function test_InitializeFirstFragment() public {
        vm.startPrank(user);

        uint256 tokenId = fragmentNFTs.mint();
        FragmentNFTs.Fragment memory fragment = fragmentNFTs.getFragment(tokenId);
        uint256 selectedNftId = fragment.nft_id;

        // Check fragments left is now 3 (4 - 1)
        assertEq(fragmentNFTs.getFragmentsLeftForNFT(selectedNftId), 3, "Should have 3 fragments left after first mint");

        vm.stopPrank();
    }

}
