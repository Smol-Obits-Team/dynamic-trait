// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../Types/TraitTypes.sol";
import { INeandersmolTraitsStorage } from "../interface/INeandersmolTraitsStorage.sol";
import { LibString } from "solady/utils/LibString.sol";

library TraitSelectorLib {
    using LibString for string;

    function getSelector(string memory _traitType) internal pure returns (bytes4 selector) {
        if (_traitType.eq(BACKGROUND)) {
            selector = INeandersmolTraitsStorage.setNeandersmolBackgroundTrait.selector;
        }
        if (_traitType.eq(SKY)) {
            selector = INeandersmolTraitsStorage.setNeandersmolSkyTrait.selector;
        }
        if (_traitType.eq(LAND)) {
            selector = INeandersmolTraitsStorage.setNeandersmolLandTrait.selector;
        }
        if (_traitType.eq(NEANDERSMOL)) {
            selector = INeandersmolTraitsStorage.setNeandersmolTrait.selector;
        }
        if (_traitType.eq(SKIN)) {
            selector = INeandersmolTraitsStorage.setNeandersmolSkinTrait.selector;
        }
        if (_traitType.eq(TOP)) {
            selector = INeandersmolTraitsStorage.setNeandersmolTopTrait.selector;
        }
        if (_traitType.eq(JEWELRY)) {
            selector = INeandersmolTraitsStorage.setNeandersmolJewelryTrait.selector;
        }
        if (_traitType.eq(FACE)) {
            selector = INeandersmolTraitsStorage.setNeandersmolFaceTrait.selector;
        }
        if (_traitType.eq(HAIR)) {
            selector = INeandersmolTraitsStorage.setNeandersmolHairTrait.selector;
        }
        if (_traitType.eq(HAT)) {
            selector = INeandersmolTraitsStorage.setNeandersmolHatTrait.selector;
        }
        if (_traitType.eq(HAND)) {
            selector = INeandersmolTraitsStorage.setNeandersmolHandTrait.selector;
        }
        if (_traitType.eq(MASK)) {
            selector = INeandersmolTraitsStorage.setNeandersmolMaskTrait.selector;
        }
        if (_traitType.eq(SPECIAL)) {
            selector = INeandersmolTraitsStorage.setNeandersmolSpecialTrait.selector;
        }
    }
}
