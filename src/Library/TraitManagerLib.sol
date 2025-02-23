// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { LibString } from "solady/utils/LibString.sol";
import { INeandersmolTraitsStorage, Neander } from "../interface/INeandersmolTraitsStorage.sol";

/**
 * @title TraitManagerLib
 * @dev This library provides utility functions for managing and retrieving traits
 *      in the Neandersmol ecosystem. It allows for selecting, setting, and handling
 *      default trait values efficiently.
 *
 * @notice Used by the `DynamicTrait` contract to manage trait assignments, retrieval,
 *         and storage interactions.
 *
 * @dev The library includes:
 *      - Retrieving function selectors for trait setting.
 *      - Mapping trait types to their respective "None" trait IDs.
 *      - Fetching the default trait assigned to a token.
 *
 */
library TraitManagerLib {
    using LibString for string;

    string constant BACKGROUND = "Background";
    string constant SKY = "Sky";
    string constant LAND = "Land";
    string constant NEANDERSMOL = "Neandersmol";
    string constant SKIN = "Skin";
    string constant TOP = "Top";
    string constant JEWELRY = "Jewelry";
    string constant FACE = "Face";
    string constant HAIR = "Hair";
    string constant HAT = "Hat";
    string constant HAND = "Hand";
    string constant MASK = "Mask";
    string constant SPECIAL = "Special";

    bytes4 constant NONE_BACKGROUND = 0x00000001;
    bytes4 constant NONE_SKY = 0x00000002;
    bytes4 constant NONE_LAND = 0x00000003;
    bytes4 constant NONE_SKIN = 0x00000004;
    bytes4 constant NONE_TOP = 0x00000005;
    bytes4 constant NONE_JEWELRY = 0x00000006;
    bytes4 constant NONE_FACE = 0x00000007;
    bytes4 constant NONE_HAIR = 0x00000008;
    bytes4 constant NONE_HAT = 0x00000009;
    bytes4 constant NONE_HAND = 0x0000000a;
    bytes4 constant NONE_MASK = 0x0000000b;
    bytes4 constant NONE_SPECIAL = 0x0000000c;

    /**
     * @notice Retrieves the function selector for setting a specific trait in the storage contract.
     * @dev Maps a trait type to its corresponding function selector in `INeandersmolTraitsStorage`.
     * @param _ts The address of the Neandersmol Traits Storage contract.
     * @param _traitId The ID of the trait whose selector is being retrieved.
     * @return selector The function selector corresponding to the given trait type.
     */
    function getSelector(INeandersmolTraitsStorage _ts, bytes4 _traitId) internal view returns (bytes4 selector) {
        string memory traitType = _ts.getTrait(_traitId).traitType;
        if (traitType.eq(BACKGROUND)) {
            selector = INeandersmolTraitsStorage.setNeandersmolBackgroundTrait.selector;
        }
        if (traitType.eq(SKY)) {
            selector = INeandersmolTraitsStorage.setNeandersmolSkyTrait.selector;
        }
        if (traitType.eq(LAND)) {
            selector = INeandersmolTraitsStorage.setNeandersmolLandTrait.selector;
        }
        if (traitType.eq(NEANDERSMOL)) {
            selector = INeandersmolTraitsStorage.setNeandersmolTrait.selector;
        }
        if (traitType.eq(SKIN)) {
            selector = INeandersmolTraitsStorage.setNeandersmolSkinTrait.selector;
        }
        if (traitType.eq(TOP)) {
            selector = INeandersmolTraitsStorage.setNeandersmolTopTrait.selector;
        }
        if (traitType.eq(JEWELRY)) {
            selector = INeandersmolTraitsStorage.setNeandersmolJewelryTrait.selector;
        }
        if (traitType.eq(FACE)) {
            selector = INeandersmolTraitsStorage.setNeandersmolFaceTrait.selector;
        }
        if (traitType.eq(HAIR)) {
            selector = INeandersmolTraitsStorage.setNeandersmolHairTrait.selector;
        }
        if (traitType.eq(HAT)) {
            selector = INeandersmolTraitsStorage.setNeandersmolHatTrait.selector;
        }
        if (traitType.eq(HAND)) {
            selector = INeandersmolTraitsStorage.setNeandersmolHandTrait.selector;
        }
        if (traitType.eq(MASK)) {
            selector = INeandersmolTraitsStorage.setNeandersmolMaskTrait.selector;
        }
        if (traitType.eq(SPECIAL)) {
            selector = INeandersmolTraitsStorage.setNeandersmolSpecialTrait.selector;
        }
    }

    /**
     * @notice Retrieves the "None" trait ID for a given trait type.
     * @dev Maps a trait type string to a predefined trait ID representing "None".
     * @param _traitType The string representing the trait type.
     * @return traitId The bytes4 identifier representing the "None" trait.
     */
    function getNoneTraitId(string memory _traitType) internal pure returns (bytes4 traitId) {
        if (_traitType.eq(BACKGROUND)) {
            traitId = NONE_BACKGROUND;
        }
        if (_traitType.eq(SKY)) {
            traitId = NONE_SKY;
        }
        if (_traitType.eq(LAND)) {
            traitId = NONE_LAND;
        }
        if (_traitType.eq(SKIN)) {
            traitId = NONE_SKIN;
        }
        if (_traitType.eq(TOP)) {
            traitId = NONE_TOP;
        }
        if (_traitType.eq(JEWELRY)) {
            traitId = NONE_JEWELRY;
        }
        if (_traitType.eq(FACE)) {
            traitId = NONE_FACE;
        }
        if (_traitType.eq(HAIR)) {
            traitId = NONE_HAIR;
        }
        if (_traitType.eq(HAT)) {
            traitId = NONE_HAT;
        }
        if (_traitType.eq(HAND)) {
            traitId = NONE_HAND;
        }
        if (_traitType.eq(MASK)) {
            traitId = NONE_MASK;
        }
        if (_traitType.eq(SPECIAL)) {
            traitId = NONE_SPECIAL;
        }
    }

    function getDefaultTrait(INeandersmolTraitsStorage _ts, uint256 _tokenId, bytes4 _traitId)
        internal
        view
        returns (bytes4 traitId)
    {
        string memory traitType = _ts.getTrait(_traitId).traitType;
        Neander memory neander = _ts.getTokenTraitsTypes(_tokenId);

        if (traitType.eq(BACKGROUND)) {
            traitId = neander.background;
        }
        if (traitType.eq(SKY)) {
            traitId = neander.sky;
        }
        if (traitType.eq(LAND)) {
            traitId = neander.land;
        }
        if (traitType.eq(NEANDERSMOL)) {
            traitId = neander.neandersmol;
        }
        if (traitType.eq(SKIN)) {
            traitId = neander.skin;
        }
        if (traitType.eq(TOP)) {
            traitId = neander.jewelry;
        }
        if (traitType.eq(JEWELRY)) {
            traitId = neander.jewelry;
        }
        if (traitType.eq(FACE)) {
            traitId = neander.face;
        }
        if (traitType.eq(HAIR)) {
            traitId = neander.hair;
        }
        if (traitType.eq(HAT)) {
            traitId = neander.hat;
        }
        if (traitType.eq(HAND)) {
            traitId = neander.hand;
        }
        if (traitType.eq(MASK)) {
            traitId = neander.mask;
        }
        if (traitType.eq(SPECIAL)) {
            traitId = neander.special;
        }
    }
}
