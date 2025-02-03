// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../Types/TraitTypes.sol";
import { INeandersmolTraitsStorage } from "../interface/INeandersmolTraitsStorage.sol";
import { LibString } from "solady/utils/LibString.sol";

import { INeandersmolTraitsStorage } from "../interface/INeandersmolTraitsStorage.sol";

library TraitSelectorLib {
    using LibString for string;

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

    function getNoneTraitId(string memory _traitType) internal pure returns (bytes4 traitId) {
        if (_traitType.eq(BACKGROUND)) {
            traitId = 0x00000001;
        }
        if (_traitType.eq(SKY)) {
            traitId = 0x00000002;
        }
        if (_traitType.eq(LAND)) {
            traitId = 0x00000003;
        }
        if (_traitType.eq(SKIN)) {
            traitId = 0x00000004;
        }
        if (_traitType.eq(TOP)) {
            traitId = 0x00000005;
        }
        if (_traitType.eq(JEWELRY)) {
            traitId = 0x00000006;
        }
        if (_traitType.eq(FACE)) {
            traitId = 0x00000007;
        }
        if (_traitType.eq(HAIR)) {
            traitId = 0x00000008;
        }
        if (_traitType.eq(HAT)) {
            traitId = 0x00000009;
        }
        if (_traitType.eq(HAND)) {
            traitId = 0x0000000a;
        }
        if (_traitType.eq(MASK)) {
            traitId = 0x0000000b;
        }
        if (_traitType.eq(SPECIAL)) {
            traitId = 0x0000000c;
        }
    }
}
