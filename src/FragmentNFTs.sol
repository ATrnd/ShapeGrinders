// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {WorldState} from "./WorldState.sol";
import {FragmentMetadataLib} from "./FragmentMetadataLib.sol";
using FragmentMetadataLib for FragmentMetadataLib.FragmentMetadata;

/// @title Fragment NFT Collection Contract
/// @author ATrnd
/// @notice This contract manages a collection of fragment NFTs that combine to form complete NFTs
/// @dev Implements ERC721 standard with dynamic URI generation and fragment management
contract FragmentNFTs is ERC721URIStorage, Ownable {

    /// @notice Thrown when attempting to mint when no NFTs are available
    error NoNFTsAvailable();

    /// @notice Thrown when attempting to query a non-existent token
    error TokenDoesNotExist();

    /// @notice Thrown when attempting to mint a fragment for an NFT that's already complete
    error AllFragmentsMinted(uint256 nftId);

    using Strings for uint256;

    /// @notice Structure defining a fragment's properties
    /// @param world_state_s The current state of the world for this fragment
    /// @param nft_id The ID of the complete NFT this fragment belongs to
    /// @param fragment_id The unique identifier of this fragment within its NFT
    struct Fragment {
        WorldState.WorldState_s world_state_s;
        uint256 nft_id;
        uint256 fragment_id;
    }

    /// @notice Maximum number of fragments that can be minted for each NFT
    uint256 private constant MAX_FRAGMENTS_PER_NFT = 4;

    /// @notice Base URI for IPFS metadata storage
    string private baseIpfsUri_s;

    /// @notice Reference to the WorldState contract for state management
    WorldState public worldStateContract_s;

    /// @notice Array of NFT IDs available for minting
    uint256[] private availableNftIds_s;

    /// @notice Counter for tracking the next token ID to be minted
    uint256 private nextTokenId_s;

    /// @notice Maps NFT IDs to their index in the availableNftIds array
    mapping(uint256 => uint256) private nftIdToArrayIndex_s;

    /// @notice Tracks the number of fragments minted for each NFT ID
    mapping(uint256 => uint256) private mintedFragmentsCount_s;

    /// @notice Stores fragment data for each token ID
    mapping(uint256 => Fragment) public fragmentData_s;

    /// @notice Initializes the contract with required parameters
    /// @param _initialOwner_s Address of the contract owner
    /// @param _worldStateContract_s Address of the WorldState contract
    /// @param _initialNftIds Array of initial NFT IDs available for minting
    constructor(
        address _initialOwner_s,
        address _worldStateContract_s,
        uint256[] memory _initialNftIds
    ) ERC721("FragmentNFTs", "FRAG") Ownable(_initialOwner_s) {
        worldStateContract_s = WorldState(_worldStateContract_s);
        availableNftIds_s = _initialNftIds;
    }

    /// @notice Mints a new fragment NFT
    /// @dev Randomly selects an NFT ID and mints a fragment for it
    /// @return The ID of the newly minted token
    function mint() public returns (uint256) {
        if (availableNftIds_s.length == 0) revert NoNFTsAvailable();

        uint256 randomIndex = worldStateContract_s.generateRandomIndex(
            availableNftIds_s.length,
            nextTokenId_s
        );

        uint256 selectedNftId = availableNftIds_s[randomIndex];
        initializeFirstFragment(selectedNftId, randomIndex);
        uint256 fragmentId = getNextAvailableFragmentId(selectedNftId);

        nextTokenId_s++;
        _safeMint(msg.sender, nextTokenId_s);
        mintedFragmentsCount_s[selectedNftId]++;

        fragmentData_s[nextTokenId_s] = Fragment(
            WorldState.WorldState_s.NEXUS,
            selectedNftId,
            fragmentId
        );

        removeNFTIfCompleted(selectedNftId);
        _setTokenURI(nextTokenId_s, constructTokenURI(nextTokenId_s));

        return nextTokenId_s;
    }

    /// @notice Sets the base URI for fragment images on IPFS
    /// @dev Only callable by contract owner
    /// @param _baseImageUri New base URI for images
    function setBaseImageUri(string memory _baseImageUri) public onlyOwner {
        baseIpfsUri_s = _baseImageUri;
    }

    /// @notice Retrieves fragment data for a specific token
    /// @param tokenId The ID of the token to query
    /// @return Fragment data structure containing the fragment's properties
    function getFragment(uint256 tokenId) public view returns (Fragment memory) {
        if (ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();
        return fragmentData_s[tokenId];
    }

    /// @notice Gets the list of NFT IDs still available for minting
    /// @return Array of available NFT IDs
    function getNFTsInCirculation() public view returns (uint256[] memory) {
        return availableNftIds_s;
    }

    /// @notice Gets the number of fragments that can still be minted for an NFT
    /// @param nftId The ID of the NFT to query
    /// @return Number of remaining fragments that can be minted
    function getFragmentsLeftForNFT(uint256 nftId) public view returns (uint256) {
        return MAX_FRAGMENTS_PER_NFT - mintedFragmentsCount_s[nftId];
    }

    function constructTokenURI(uint256 tokenId) internal view returns (string memory) {
        Fragment memory fragment = fragmentData_s[tokenId];

        FragmentMetadataLib.FragmentMetadata memory metadata = FragmentMetadataLib.FragmentMetadata({
            worldState: fragment.world_state_s,
            nftId: fragment.nft_id,
            fragmentId: fragment.fragment_id,
            tokenId: tokenId
        });

        return FragmentMetadataLib.createTokenURI(baseIpfsUri_s, metadata);
    }

    /// @notice Converts world state enum to string
    /// @param state The world state to convert
    /// @return String representation of the world state
    function getWorldStateString(WorldState.WorldState_s state) internal pure returns (string memory) {
        if (state == WorldState.WorldState_s.NEXUS) return "NEXUS";
        if (state == WorldState.WorldState_s.FLUX) return "FLUX";
        if (state == WorldState.WorldState_s.CORE) return "CORE";
        if (state == WorldState.WorldState_s.GEAR) return "GEAR";
        return "UNKNOWN";
    }

    /// @notice Removes an NFT from circulation when all fragments are minted
    /// @param nftId The NFT ID to remove
    function removeNFTFromCirculation(uint256 nftId) private {
        uint256 index = nftIdToArrayIndex_s[nftId];
        uint256 lastIndex = availableNftIds_s.length - 1;

        if (index != lastIndex) {
            uint256 lastNftId = availableNftIds_s[lastIndex];
            availableNftIds_s[index] = lastNftId;
            nftIdToArrayIndex_s[lastNftId] = index;
        }

        availableNftIds_s.pop();
        delete nftIdToArrayIndex_s[nftId];
    }

    /// @notice Initializes tracking for the first fragment of an NFT
    /// @param nftId The NFT ID to initialize
    /// @param randomIndex The index in the available NFTs array
    function initializeFirstFragment(uint256 nftId, uint256 randomIndex) private {
        if(mintedFragmentsCount_s[nftId] == 0) {
            nftIdToArrayIndex_s[nftId] = randomIndex;
        }
    }

    /// @notice Removes an NFT ID from circulation if all its fragments have been minted
    /// @dev Checks if fragment count equals MAX_FRAGMENTS_PER_NFT (4) and removes if true
    /// @param nftId The NFT ID to check for completion and potentially remove
    function removeNFTIfCompleted(uint256 nftId) private {
        if (mintedFragmentsCount_s[nftId] == MAX_FRAGMENTS_PER_NFT) {
            removeNFTFromCirculation(nftId);
        }
    }

    /// @notice Gets the next available fragment ID for an NFT
    /// @param nftId The NFT ID to get the next fragment for
    /// @return The next available fragment ID
    function getNextAvailableFragmentId(uint256 nftId) private view returns (uint256) {
        uint256 currentCount = mintedFragmentsCount_s[nftId];
        if (currentCount >= MAX_FRAGMENTS_PER_NFT) revert AllFragmentsMinted(nftId);
        return currentCount + 1;
    }

}
