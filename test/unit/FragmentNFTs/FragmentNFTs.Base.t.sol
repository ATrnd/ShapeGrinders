// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "../Base/Base.t.sol";

contract FragmentNFTsBaseTest is BaseTest {
    /// @notice Tests stored in this contract:
    /// - Core contract setup validation
    /// - Base configuration tests
    /// - Simple state checks

    function setUp() public override {
        super.setUp();
        // No additional setup needed for base tests
    }

    /// ============================================
    /// ============= Contract Setup ===============
    /// ============================================

    function test_FragmentWorldStateContractAddress() public view {
        assertEq(
            address(fragmentNFTs.s_fragmentWorldStateContract()),
            address(fragmentWorldState),
            "FragmentWorldState contract address mismatch"
        );
    }

    /// ============================================
    /// =========== Base Configuration ============
    /// ============================================

    function test_BaseIpfsUriDefault() public {
        uint256 tokenId = 1;
        vm.prank(user);
        fragmentNFTs.mint();

        // The token URI should start with "data:application/json;base64,"
        // since there's no base IPFS URI set
        string memory tokenUri = fragmentNFTs.tokenURI(tokenId);
        vm.stopPrank();
        assertTrue(
            _startsWith(tokenUri, "data:application/json;base64,"),
            "Token URI should start with data:application/json;base64,"
        );
    }

    /// ============================================
    /// ============ Initial State ================
    /// ============================================

    function test_AvailableFragmentNftIds() public view {
        assertEq(
            initialFragmentNftIds.length,
            fragmentNFTs.getNFTsInCirculation().length,
            "initialFragmentNftIds length should match NFTsInCirculation on init"
        );
    }

}
