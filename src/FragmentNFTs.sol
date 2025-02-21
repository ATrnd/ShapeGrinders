// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {FragmentWorldState} from "./FragmentWorldState.sol";
import {FragmentMetadataLib} from "./FragmentMetadataLib.sol";

/**
 * @title Fragment NFTs
 * @author ATrnd
 * @notice This contract manages the creation, verification, and burning of fragment NFTs
 * @dev Implements ERC721 standard with additional fragment-specific functionality
 */
contract FragmentNFTs is ERC721URIStorage, Ownable, ReentrancyGuard {
    using FragmentMetadataLib for FragmentMetadataLib.FragmentMetadata;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to burn a set that's already been burned
    error FragmentModule__SetAlreadyBurned();

    /// @notice Thrown when set verification fails during burning
    error FragmentModule__SetVerificationFailed();

    /// @notice Thrown when attempting to verify a non-existent NFT ID
    error FragmentModule__NonexistentNftId();

    /// @notice Thrown when no fragment NFTs are available for minting
    error FragmentModule__NoFragmentNFTsAvailable();

    /// @notice Thrown when attempting to verify an incomplete fragment set
    error FragmentModule__IncompleteSet();

    /// @notice Thrown when caller doesn't own all fragments in a set
    error FragmentModule__NotOwnerOfAll();

    /// @notice Thrown when fragments in a set have mismatched world states
    error FragmentModule__WorldStateMismatch();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a complete set of fragments is burned
    /// @param fragmentBurner Address that initiated the burn
    /// @param fragmentNftId ID of the fragment NFT set that was burned
    /// @param fragmentWorldState World state of the burned fragment set
    event FragmentSetBurned(
        address indexed fragmentBurner,
        uint256 indexed fragmentNftId,
        FragmentWorldState.WorldState fragmentWorldState
    );

    /*//////////////////////////////////////////////////////////////
                              DATA TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Defines the properties of a fragment NFT
    /// @param fragmentWorldState Current world state of the fragment
    /// @param fragmentNftId ID of the complete NFT this fragment belongs to
    /// @param fragmentId Unique identifier within the fragment set (1-4)
    struct Fragment {
        FragmentWorldState.WorldState fragmentWorldState;
        uint256 fragmentNftId;
        uint256 fragmentId;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Reference to the WorldState contract for state management
    /// @dev Immutable reference set during contract deployment
    FragmentWorldState public s_fragmentWorldStateContract;

    /// @notice Constants for fragment management
    /// @dev These values are fundamental to the fragment system and cannot be changed
    uint256 private constant MINTED_FRAGMENT_INCREMENT = 1;
    uint256 private constant MAX_FRAGMENTS_PER_NFT = 4;

    /// @notice Base URI for IPFS metadata storage
    /// @dev Can be updated by contract owner
    string private s_baseIpfsUri;

    /// @notice Array of NFT IDs available for minting
    /// @dev Dynamically updated as fragments are minted and sets completed
    uint256[] private s_availableFragmentNftIds;

    /// @notice Counter for tracking the next token ID to be minted
    /// @dev Increments by 1 for each new fragment
    uint256 public s_nextFragmentTokenId;

    /// @notice Tracks burned NFT sets by NFT ID and burner address
    /// @dev Maps NFT ID => burner address => burned status
    mapping(uint256 => mapping(address => bool)) private s_fragmentBurnedSets;

    /// @notice Tracks the number of fragments minted for each NFT ID
    /// @dev Maps NFT ID => count of minted fragments
    mapping(uint256 => uint256) private s_mintedFragmentsCount;

    /// @notice Maps NFT IDs to their index in the available NFTs array
    /// @dev Used for efficient removal of completed sets
    mapping(uint256 => uint256) private s_fragmentNftIdToAvailableIndex;

    /// @notice Stores fragment data for each token ID
    /// @dev Maps token ID => Fragment struct
    mapping(uint256 => Fragment) public s_fragmentData;

    /// @notice Maps token IDs to their Fragment NFT IDs
    /// @dev Maps token ID => NFT ID
    mapping(uint256 => uint256) private s_tokenIdToFragmentNftId;

    /// @notice Maps NFT ID and fragment ID to the token ID
    /// @dev Maps NFT ID => fragment ID (1-4) => token ID
    mapping(uint256 => mapping(uint256 => uint256)) private s_fragmentNftIdToFragmentTokenId;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the Fragment NFTs contract
    /// @dev Sets up initial state with owner, WorldState contract, and available NFT IDs
    /// @param _initialOwner Address that will own and control the contract
    /// @param _fragmentWorldStateContract Address of the deployed WorldState contract
    /// @param _initialNftIds Array of NFT IDs that will be available for minting
    constructor(
        address _initialOwner,
        address _fragmentWorldStateContract,
        uint256[] memory _initialNftIds
    ) ERC721("FragmentNFTs", "FRAG") Ownable(_initialOwner) {
        s_fragmentWorldStateContract = FragmentWorldState(_fragmentWorldStateContract);
        s_availableFragmentNftIds = _initialNftIds;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints a new fragment NFT
    /// @dev Randomly selects an NFT ID and mints a fragment for it
    /// @return The ID of the newly minted token
    /// @custom:security nonReentrant
    function mint() public nonReentrant returns (uint256) {
        _validateFragmentNFTsAvailable();

        uint256 randomIndex = s_fragmentWorldStateContract.generateRandomIndex(
            s_availableFragmentNftIds.length,
            s_nextFragmentTokenId
        );

        uint256 selectedFragmentNftId = s_availableFragmentNftIds[randomIndex];
        uint256 fragmentCountId = _getNextAvailableFragmentId(selectedFragmentNftId);
        s_nextFragmentTokenId = _getNextFragmentTokenId(s_nextFragmentTokenId);

        _initializeFirstFragment(selectedFragmentNftId, randomIndex);

        s_fragmentData[s_nextFragmentTokenId] = Fragment({
            fragmentWorldState: FragmentWorldState.WorldState.NEXUS,
            fragmentNftId: selectedFragmentNftId,
            fragmentId: fragmentCountId
        });

        s_mintedFragmentsCount[selectedFragmentNftId] += MINTED_FRAGMENT_INCREMENT;
        s_fragmentNftIdToFragmentTokenId[selectedFragmentNftId][fragmentCountId] = s_nextFragmentTokenId;
        s_tokenIdToFragmentNftId[s_nextFragmentTokenId] = selectedFragmentNftId;

        _removeNFTIfCompleted(selectedFragmentNftId);
        _safeMint(msg.sender, s_nextFragmentTokenId);
        _setTokenURI(s_nextFragmentTokenId, _constructTokenURI(s_nextFragmentTokenId));

        return s_nextFragmentTokenId;
    }

    /// @notice Public wrapper to verify if a given NFT ID has a complete set owned by the caller
    /// @param fragmentNftId The NFT ID to verify
    /// @return verified True if verification passed
    /// @return fragmentWorldState The matching world state of the set
    function verifyFragmentSet(uint256 fragmentNftId) public view returns (
        bool verified,
        FragmentWorldState.WorldState fragmentWorldState
    ) {
        return _verifyFragmentSet(fragmentNftId);
    }

    /// @notice Public wrapper to burn a complete set of fragments
    /// @param fragmentNftId The NFT ID of the set to burn
    /// @return success True if burning was successful
    /// @custom:security nonReentrant
    function burnFragmentSet(uint256 fragmentNftId) public nonReentrant returns (bool success) {
        return _burnFragmentSet(fragmentNftId);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets all available fragment NFT IDs
    /// @return Array of NFT IDs still available for minting
    function getNFTsInCirculation() public view returns (uint256[] memory) {
        return s_availableFragmentNftIds;
    }

    /// @notice Gets the number of fragments left to mint for an NFT
    /// @param fragmentNftId The NFT ID to query
    /// @return Number of fragments that can still be minted
    function getFragmentsLeftForNFT(uint256 fragmentNftId) public view returns (uint256) {
        return MAX_FRAGMENTS_PER_NFT - s_mintedFragmentsCount[fragmentNftId];
    }

    /// @notice Retrieves fragment data for a specific token
    /// @param tokenId The token ID to query
    /// @return Fragment data structure containing the fragment's properties
    function getFragmentData(uint256 tokenId) public view returns (Fragment memory) {
        return s_fragmentData[tokenId];
    }

    /// @notice Gets the Fragment NFT ID associated with a token ID
    /// @param tokenId The token ID to lookup
    /// @return The NFT ID this fragment belongs to
    function getFragmentNftIdByTokenId(uint256 tokenId) public view returns (uint256) {
        return s_tokenIdToFragmentNftId[tokenId];
    }

    /// @notice Gets all token IDs for fragments of a specific NFT
    /// @param nftId The NFT ID to query
    /// @return Array of token IDs belonging to the NFT
    function getFragmentTokenIds(uint256 nftId) public view returns (uint256[] memory) {
        uint256 fragmentCount = s_mintedFragmentsCount[nftId];
        uint256[] memory tokenIds = new uint256[](fragmentCount);

        for (uint256 i = 0; i < fragmentCount; i++) {
            tokenIds[i] = s_fragmentNftIdToFragmentTokenId[nftId][i + 1];
        }

        return tokenIds;
    }

    /// @notice Public wrapper to get the next fragment token ID
    /// @param fragmentTokenId Current token ID
    /// @return nextFragmentTokenId Next token ID in sequence
    function getNextFragmentTokenId(uint256 fragmentTokenId) public pure returns(uint256 nextFragmentTokenId) {
        return _getNextFragmentTokenId(fragmentTokenId);
    }

    /// @notice Public wrapper to get the next available fragment ID for an NFT
    /// @param fragmentNftId The NFT ID to query
    /// @return nextFragmentId The next available fragment ID
    function getNextAvailableFragmentId(uint256 fragmentNftId) public view returns (uint256 nextFragmentId) {
        return _getNextAvailableFragmentId(fragmentNftId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the token URI for a fragment
    /// @dev Uses FragmentMetadataLib to generate the complete URI
    /// @param fragmentTokenId Token ID to generate URI for
    /// @return Complete token URI as a string
    function _constructTokenURI(uint256 fragmentTokenId) internal view returns (string memory) {
        Fragment memory fragment = s_fragmentData[fragmentTokenId];

        FragmentMetadataLib.FragmentMetadata memory metadata = FragmentMetadataLib.FragmentMetadata({
            fragmentWorldState: fragment.fragmentWorldState,
            fragmentNftId: fragment.fragmentNftId,
            fragmentId: fragment.fragmentId,
            fragmentTokenId: fragmentTokenId
        });

        return FragmentMetadataLib.createTokenURI(s_baseIpfsUri, metadata);
    }

    /// @notice Internal verification of fragment set completion
    /// @dev Core logic for set verification, used by burn function
    /// @param fragmentNftId The NFT ID to verify
    /// @return verified True if verification passed
    /// @return fragmentWorldState The matching world state of the set
    function _verifyFragmentSet(uint256 fragmentNftId) internal view returns (
        bool verified,
        FragmentWorldState.WorldState fragmentWorldState
    ) {
        if (s_mintedFragmentsCount[fragmentNftId] == 0) {
            revert FragmentModule__NonexistentNftId();
        }

        uint256[] memory fragmentTokenIds = getFragmentTokenIds(fragmentNftId);
        if (fragmentTokenIds.length != MAX_FRAGMENTS_PER_NFT) {
            revert FragmentModule__IncompleteSet();
        }

        fragmentWorldState = s_fragmentData[fragmentTokenIds[0]].fragmentWorldState;

        for (uint256 i = 0; i < MAX_FRAGMENTS_PER_NFT; i++) {
            uint256 fragmentTokenId = fragmentTokenIds[i];

            if (ownerOf(fragmentTokenId) != msg.sender) {
                revert FragmentModule__NotOwnerOfAll();
            }

            if (s_fragmentData[fragmentTokenId].fragmentWorldState != fragmentWorldState) {
                revert FragmentModule__WorldStateMismatch();
            }
        }

        return (true, fragmentWorldState);
    }

    /// @notice Internal implementation of fragment set burning
    /// @dev Core logic for burning complete sets
    /// @param fragmentNftId The NFT ID of the set to burn
    /// @return success True if burning was successful
    function _burnFragmentSet(uint256 fragmentNftId) internal returns (bool success) {
        if (_isFragmentSetBurned(fragmentNftId)) {
            revert FragmentModule__SetAlreadyBurned();
        }

        (bool verified, FragmentWorldState.WorldState fragmentState) = _verifyFragmentSet(fragmentNftId);
        if (!verified) {
            revert FragmentModule__SetVerificationFailed();
        }

        s_fragmentBurnedSets[fragmentNftId][msg.sender] = true;

        uint256[] memory fragmentTokenIds = getFragmentTokenIds(fragmentNftId);
        for (uint256 i = 0; i < MAX_FRAGMENTS_PER_NFT; i++) {
            uint256 fragmentTokenId = fragmentTokenIds[i];
            _burn(fragmentTokenId);
        }

        emit FragmentSetBurned(msg.sender, fragmentNftId, fragmentState);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes tracking for the first fragment of an NFT
    /// @dev Only sets the index if this is the first fragment minted
    /// @param fragmentNftId The NFT ID to initialize
    /// @param randomIndex The index in the available NFTs array
    function _initializeFirstFragment(uint256 fragmentNftId, uint256 randomIndex) private {
        if(s_mintedFragmentsCount[fragmentNftId] == 0) {
            s_fragmentNftIdToAvailableIndex[fragmentNftId] = randomIndex;
        }
    }

    /// @notice Removes an NFT from circulation if all fragments are minted
    /// @dev Checks if fragment count equals or exceeds maximum
    /// @param fragmentNftId The NFT ID to check and potentially remove
    function _removeNFTIfCompleted(uint256 fragmentNftId) private {
        if (s_mintedFragmentsCount[fragmentNftId] >= MAX_FRAGMENTS_PER_NFT) {
            _removeNFTFromCirculation(fragmentNftId);
        }
    }

    /// @notice Removes an NFT from the available circulation
    /// @dev Updates array and index mapping to maintain consistency
    /// @param fragmentNftId The NFT ID to remove
    function _removeNFTFromCirculation(uint256 fragmentNftId) private {
        uint256 index = s_fragmentNftIdToAvailableIndex[fragmentNftId];
        uint256 lastIndex = s_availableFragmentNftIds.length - 1;

        if (index != lastIndex) {
            uint256 lastNftId = s_availableFragmentNftIds[lastIndex];
            s_availableFragmentNftIds[index] = lastNftId;
            s_fragmentNftIdToAvailableIndex[lastNftId] = index;
        }

        s_availableFragmentNftIds.pop();
        delete s_fragmentNftIdToAvailableIndex[fragmentNftId];
    }

    /// @notice Validates that fragments are available for minting
    /// @dev Reverts if no fragments are available
    function _validateFragmentNFTsAvailable() private view {
        if (s_availableFragmentNftIds.length == 0) {
            revert FragmentModule__NoFragmentNFTsAvailable();
        }
    }

    /// @notice Checks if a fragment set has been burned
    /// @param fragmentNftId The NFT ID to check
    /// @return True if the set was burned by the caller
    function _isFragmentSetBurned(uint256 fragmentNftId) private view returns (bool) {
        return s_fragmentBurnedSets[fragmentNftId][msg.sender];
    }

    /// @notice Internal implementation for getting the next fragment token ID
    /// @dev Simple increment function kept internal for consistency
    /// @param fragmentTokenId Current token ID
    /// @return nextFragmentTokenId Next token ID in sequence
    function _getNextFragmentTokenId(uint256 fragmentTokenId) private pure returns(uint256 nextFragmentTokenId) {
        return fragmentTokenId + 1;
    }

    /// @notice Internal implementation for getting the next available fragment ID
    /// @dev Calculates next ID based on minted count
    /// @param fragmentNftId The NFT ID to get next fragment for
    /// @return nextFragmentId The next available fragment ID
    function _getNextAvailableFragmentId(uint256 fragmentNftId) private view returns (uint256 nextFragmentId) {
        return (s_mintedFragmentsCount[fragmentNftId] + 1);
    }
}

// ref {{{
// pragma solidity ^0.8.28;
//
// import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
// import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
// import {FragmentWorldState} from "./FragmentWorldState.sol";
// import {FragmentMetadataLib} from "./FragmentMetadataLib.sol";
// using FragmentMetadataLib for FragmentMetadataLib.FragmentMetadata;
//
// contract FragmentNFTs is ERC721URIStorage, Ownable, ReentrancyGuard {
//
//     error FragmentModule__SetAlreadyBurned();
//     error FragmentModule__SetVerificationFailed();
//     error FragmentModule__NonexistentNftId();
//     error FragmentModule__NoFragmentNFTsAvailable();
//     error FragmentModule__IncompleteSet();
//     error FragmentModule__NotOwnerOfAll();
//     error FragmentModule__WorldStateMismatch();
//
//     event FragmentSetBurned(
//         address indexed fragmentBurner,
//         uint256 indexed fragmentNftId,
//         FragmentWorldState.WorldState fragmentWorldState
//     );
//
//     /// @notice Structure defining a fragment's properties
//     /// @param fragmentWorldState The current state of the world for this fragment
//     /// @param fragmentNftId The ID of the complete NFT this fragment belongs to
//     /// @param fragmentId The unique identifier of this fragment within its NFT
//     struct Fragment {
//         FragmentWorldState.WorldState fragmentWorldState;
//         uint256 fragmentNftId;
//         uint256 fragmentId;
//     }
//
//     /// @notice Reference to the WorldState contract for state management
//     FragmentWorldState public s_fragmentWorldStateContract;
//
//     /// @notice Base URI for IPFS metadata storage
//     string private s_baseIpfsUri;
//
//     /// @notice Counter for for fragment increments
//     uint256 private constant MINTED_FRAGMENT_INCREMENT = 1;
//
//     /// @notice Maximum number of fragments that can be minted for each NFT
//     uint256 private constant MAX_FRAGMENTS_PER_NFT = 4;
//
//     /// @notice Array of NFT IDs available for minting
//     uint256[] private s_availableFragmentNftIds;
//
//     /// @notice Counter for tracking the next token ID to be minted
//     uint256 public s_nextFragmentTokenId;
//
//     /// @notice Tracks the number of fragments minted for each NFT ID
//     mapping(uint256 => uint256) private s_mintedFragmentsCount;
//
//     /// @notice Maps NFT IDs to their index in the availableNftIds array
//     // s_fragmentNftIdToAvailableIndex
//     mapping(uint256 => uint256) private s_fragmentNftIdToAvailableIndex;
//
//     /// @notice Stores fragment data for each token ID
//     mapping(uint256 => Fragment) public s_fragmentData;
//
//     /// @notice Maps token IDs to their Fragment NFT IDs for easy lookup
//     mapping(uint256 => uint256) private s_tokenIdToFragmentNftId;
//
//     /// @notice Maps NFT ID and fragment ID to the token ID
//     /// @dev First key is NFT ID, second key is fragment ID (1-4), value is token ID
//     // s_fragmentNftIdToFragmentTokenId
//     mapping(uint256 => mapping(uint256 => uint256)) private s_fragmentNftIdToFragmentTokenId;
//
//     /// @notice Tracks burned NFT sets by NFT ID and burner address
//     mapping(uint256 => mapping(address => bool)) private s_fragmentBurnedSets;
//
//
//     // =====================
//     // --- [CONSTRUCTOR] ---
//     // =====================
//
//     /// @notice Initializes the contract with required parameters
//     /// @param _initialOwner Address of the contract owner
//     /// @param _fragmentWorldStateContract Address of the WorldState contract
//     /// @param _initialNftIds Array of initial NFT IDs available for minting
//     constructor(
//         address _initialOwner,
//         address _fragmentWorldStateContract,
//         uint256[] memory _initialNftIds
//     ) ERC721("FragmentNFTs", "FRAG") Ownable(_initialOwner) {
//         s_fragmentWorldStateContract = FragmentWorldState(_fragmentWorldStateContract);
//         s_availableFragmentNftIds = _initialNftIds;
//     }
//
//
//     // ========================
//     // --- [CORE FUNCTIONS] ---
//     // ========================
//
//     /// @notice Mints a new fragment NFT
//     /// @dev Randomly selects an NFT ID and mints a fragment for it
//     /// @return The ID of the newly minted token
//     function mint() public nonReentrant returns (uint256) {
//
//         // revert if no fragment nfts available
//         _validateFragmentNFTsAvailable();
//
//         // generate random index with modulo operator, always less than max
//         uint256 randomIndex = s_fragmentWorldStateContract.generateRandomIndex(
//             s_availableFragmentNftIds.length,
//             s_nextFragmentTokenId
//         );
//
//         // use the random index, the select an available Fragment Nft Id from the pool of 'legit' fragment Nft ids
//         uint256 selectedFragmentNftId = s_availableFragmentNftIds[randomIndex];
//
//         // select the next available fragment (count) ID, (each fragment has 4 available fragments and all of those can be minted, and once all minted we remove that fragment nft from circulation)
//         uint256 fragmentCountId = _getNextAvailableFragmentId(selectedFragmentNftId);
//
//         // get the next available token ID for our fragment NFT (this one is a manual iterator to keep track of each NFT)
//         s_nextFragmentTokenId = _getNextFragmentTokenID(s_nextFragmentTokenId);
//
//         // when a fragment gets selected for the first time, we store the `randomIndex` of that Fragment NFT, and connect it to their index
//         // s_fragmentNftIdToAvailableIndex because we don't actually know the location of our NFTs by default, we must do this step first in order to get a proper handle
//         // on NFT removal later
//         _initializeFirstFragment(selectedFragmentNftId, randomIndex);
//
//         // now we store the world state, the actual NFT id, and the Fragment (count) ID for later lookups
//         s_fragmentData[selectedFragmentNftId] = Fragment(
//             FragmentWorldState.WorldState.NEXUS,
//             selectedFragmentNftId,
//             fragmentCountId
//         );
//
//         // next we increment the fragment count by one, so we can get the _getNextAvailableFragmentId right in the next mint
//         s_mintedFragmentsCount[selectedFragmentNftId] += MINTED_FRAGMENT_INCREMENT;
//
//         // okay here we create a lookup mapping which can be used with the data we have if we own a fragment to get all minted fragments of the same nft
//         s_fragmentNftIdToFragmentTokenId[selectedFragmentNftId][fragmentCountId] = s_nextFragmentTokenId;
//
//         // Store the mapping of token ID to Fragment NFT ID
//         s_tokenIdToFragmentNftId[s_nextFragmentTokenId] = selectedFragmentNftId;
//
//         // here we remove the fragment NFT id from circulation (note :: rename for more clarity) and we remove it from the array which we use,
//         // to get fragment NFT ids from so ideally, when a fragment NFT gets all it's fragments (4) it's getting removed from circulation,
//         // so users cant select it
//         // (note the function inner variable names need renaming aswell)
//         _removeNFTIfCompleted(selectedFragmentNftId);
//
//         // we mint, the token to the caller
//         _safeMint(msg.sender, s_nextFragmentTokenId);
//
//         // we build the token URI
//         _setTokenURI(s_nextFragmentTokenId, _constructTokenURI(s_nextFragmentTokenId));
//
//         // we return the ID
//         return s_nextFragmentTokenId;
//
//     }
//
//     /// @notice Verifies if a given NFT ID has a complete set owned by the caller
//     /// @param fragmentNftId The NFT ID to verify
//     /// @return verified True if verification passed
//     /// @return fragmentWorldState The matching world state of the set
//     function _verifyFragmentSet(uint256 fragmentNftId) public view returns (bool verified, FragmentWorldState.WorldState fragmentWorldState) {
//
//         // Check if NFT ID has any fragments minted
//         if (s_mintedFragmentsCount[fragmentNftId] == 0) {
//             revert FragmentModule__NonexistentNftId();
//         }
//
//         // Get all token IDs for this fragment NFT
//         uint256[] memory fragmentTokenIds = getFragmentTokenIds(fragmentNftId);
//
//         // Verify we have a complete set (4 fragments)
//         if (fragmentTokenIds.length != MAX_FRAGMENTS_PER_NFT) {
//             revert FragmentModule__IncompleteSet();  // Custom error for incomplete sets
//         }
//
//         // Get world state of first fragment as reference
//         fragmentWorldState = s_fragmentData[fragmentTokenIds[0]].fragmentWorldState;
//
//         // Verify each fragment in the set
//         for (uint256 i = 0; i < MAX_FRAGMENTS_PER_NFT; i++) {
//
//             // Get current fragment token ID
//             uint256 fragmentTokenId = fragmentTokenIds[i];
//
//             // Verify caller owns this fragment
//             if (ownerOf(fragmentTokenId) != msg.sender) {
//                 revert FragmentModule__NotOwnerOfAll();  // Custom error for ownership check
//             }
//
//             // Verify fragment has matching world state
//             if (s_fragmentData[fragmentTokenId].fragmentWorldState != fragmentWorldState) {
//                 revert FragmentModule__WorldStateMismatch();  // Custom error for state mismatch
//             }
//
//         }
//         return (true, fragmentWorldState);
//     }
//
//     /// @notice Burns a complete set of fragments if all conditions are met
//     /// @param fragmentNftId The NFT ID of the set to burn
//     /// @return success True if burning was successful
//     function burnFragmentSet(uint256 fragmentNftId) external nonReentrant returns (bool success) {
//         // Verify set hasn't been burned
//         if (_isFragmentSetBurned(fragmentNftId)) {
//             revert FragmentModule__SetAlreadyBurned();
//         }
//
//         // Verify set completion and ownership
//         (bool verified, FragmentWorldState.WorldState fragmentState) = _verifyFragmentSet(fragmentNftId);
//         if (!verified) {
//             revert FragmentModule__SetVerificationFailed();
//         }
//
//         // Mark set as burned before actual burning (reentrancy protection)
//         s_fragmentBurnedSets[fragmentNftId][msg.sender] = true;
//
//         // Get all fragment token IDs and burn them
//         uint256[] memory fragmentTokenIds = getFragmentTokenIds(fragmentNftId);
//         for (uint256 i = 0; i < MAX_FRAGMENTS_PER_NFT; i++) {
//             uint256 fragmentTokenId = fragmentTokenIds[i];
//
//             // Burn the token (this handles ownership and approval cleanup)
//             _burn(fragmentTokenId);
//         }
//
//         emit FragmentSetBurned(msg.sender, fragmentNftId, fragmentState);
//         return true;
//     }
//
//     function _initializeFirstFragment(uint256 fragmentNftId, uint256 randomIndex) private {
//         if(s_mintedFragmentsCount[fragmentNftId] == 0) {
//             s_fragmentNftIdToAvailableIndex[fragmentNftId] = randomIndex;
//         }
//     }
//
//     function _removeNFTIfCompleted(uint256 fragmentNftId) private {
//         if (s_mintedFragmentsCount[fragmentNftId] == MAX_FRAGMENTS_PER_NFT || s_mintedFragmentsCount[fragmentNftId] > MAX_FRAGMENTS_PER_NFT) {
//             _removeNFTFromCirculation(fragmentNftId);
//         }
//     }
//
//     function _removeNFTFromCirculation(uint256 fragmentNftId) private {
//         uint256 index = s_fragmentNftIdToAvailableIndex[fragmentNftId];
//         uint256 lastIndex = s_availableFragmentNftIds.length - 1;
//
//         if (index != lastIndex) {
//             uint256 lastNftId = s_availableFragmentNftIds[lastIndex];
//             s_availableFragmentNftIds[index] = lastNftId;
//             s_fragmentNftIdToAvailableIndex[lastNftId] = index;
//         }
//
//         s_availableFragmentNftIds.pop();
//         delete s_fragmentNftIdToAvailableIndex[fragmentNftId];
//     }
//
//     // fragmentTokenId
//     function _constructTokenURI(uint256 fragmentTokenId) internal view returns (string memory) {
//         Fragment memory fragment = s_fragmentData[fragmentTokenId];
//
//         FragmentMetadataLib.FragmentMetadata memory metadata = FragmentMetadataLib.FragmentMetadata({
//             fragmentWorldState: fragment.fragmentWorldState,
//             fragmentNftId: fragment.fragmentNftId,
//             fragmentId: fragment.fragmentId,
//             fragmentTokenId: fragmentTokenId
//         });
//
//         return FragmentMetadataLib.createTokenURI(s_baseIpfsUri, metadata);
//     }
//
//     /// @notice Checks if a fragment set has been burned
//     /// @param fragmentNftId The NFT ID to check
//     /// @return burned True if the set was burned by this caller
//     function _isFragmentSetBurned(uint256 fragmentNftId) private view returns (bool) {
//         return s_fragmentBurnedSets[fragmentNftId][msg.sender];
//     }
//
//     function _getNextAvailableFragmentId(uint256 fragmentNftId) public view returns (uint256 nextFragmentID) {
//         nextFragmentID = (s_mintedFragmentsCount[fragmentNftId] + 1);
//     }
//
//     // fragmentTokenId
//     // nextFragmentTokenId
//     function _getNextFragmentTokenID(uint256 fragmentTokenId) public pure returns(uint256 nextFragmentTokenId) {
//         nextFragmentTokenId = fragmentTokenId + 1;
//     }
//
//     function _validateFragmentNFTsAvailable() private view {
//         if (s_availableFragmentNftIds.length == 0) revert FragmentModule__NoFragmentNFTsAvailable();
//     }
//
//     function getNFTsInCirculation() public view returns (uint256[] memory) {
//         return s_availableFragmentNftIds;
//     }
//
//     // fragmentNftId
//     function getFragmentsLeftForNFT(uint256 fragmentNftId) public view returns (uint256) {
//         return MAX_FRAGMENTS_PER_NFT - s_mintedFragmentsCount[fragmentNftId];
//     }
//
//     function getFragmentData(uint256 tokenId) public view returns (Fragment memory) {
//         return s_fragmentData[tokenId];
//     }
//
//     /// @notice Gets the Fragment NFT ID associated with a token ID
//     /// @param tokenId The token ID to lookup
//     /// @return The Fragment NFT ID for this token
//     function getFragmentNftIdByTokenId(uint256 tokenId) public view returns (uint256) {
//         return s_tokenIdToFragmentNftId[tokenId];
//     }
//
//     /// @notice Gets all token IDs for fragments of a specific NFT
//     /// @param nftId The NFT ID to query
//     /// @return Array of token IDs for all minted fragments of the NFT
//     function getFragmentTokenIds(uint256 nftId) public view returns (uint256[] memory) {
//         uint256 fragmentCount = s_mintedFragmentsCount[nftId];
//         uint256[] memory tokenIds = new uint256[](fragmentCount);
//
//         // Iterate through all possible fragment IDs (1 to fragmentCount)
//         for (uint256 i = 0; i < fragmentCount; i++) {
//             // Get token ID from mapping (fragment IDs start at 1)
//             tokenIds[i] = s_fragmentNftIdToFragmentTokenId[nftId][i + 1];
//         }
//
//         return tokenIds;
//     }
//
// }

// }}}
