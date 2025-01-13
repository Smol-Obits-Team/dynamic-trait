// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Neander, Trait } from "../interface/INeandersmolTraitsStorage.sol";

contract NeandersmolTraitsStorage {
    mapping(bytes4 => Trait) public trait;
    mapping(uint256 => Neander) public neander;

    constructor() { }

    function setTraitsImage(bytes4[] calldata _traitId, string[] calldata _pngImage) public {
        for (uint256 i; i < _traitId.length; i++) {
            trait[_traitId[i]].pngImage = _pngImage[i];
        }
    }

    function traitExists(bytes4 _traitId) public view returns (bool) {
        return bytes(trait[_traitId].traitType).length != 0;
    }

    function setNeandermol(uint256 _tokenId, Neander calldata _neander) external {
        neander[_tokenId] = _neander;
    }

    function setInitialTraits(bytes4[] calldata _traitIds, Trait[] calldata _traits) external {
        for (uint256 i = 0; i < _traitIds.length; i++) {
            trait[_traitIds[i]] = _traits[i];
        }
    }

    function addTrait(bytes4 _traitId, Trait calldata _trait) external {
        trait[_traitId] = _trait;
    }

    function setNeandersmolBackgroundTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].background = _traitIds;
    }

    function setNeandersmolSkyTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].sky = _traitIds;
    }

    function setNeandersmolLandTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].land = _traitIds;
    }

    function setNeandersmolTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].neandersmol = _traitIds;
    }

    function setNeandersmolSkinTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].skin = _traitIds;
    }

    function setNeandersmolTopTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].top = _traitIds;
    }

    function setNeandersmolJewelryTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].jewelry = _traitIds;
    }

    function setNeandersmolFaceTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].face = _traitIds;
    }

    function setNeandersmolHairTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].hair = _traitIds;
    }

    function setNeandersmolHatTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].hat = _traitIds;
    }

    function setNeandersmolHandTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].hand = _traitIds;
    }

    function setNeandersmolMaskTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].mask = _traitIds;
    }

    function setNeandersmolSpecialTrait(uint256 _tokenId, bytes4 _traitIds) external {
        neander[_tokenId].special = _traitIds;
    }

    function getTokenTraitsTypes(uint256 _tokenId) external view returns (Neander memory) {
        return neander[_tokenId];
    }

    function getTrait(bytes4 _traitId) external view returns (Trait memory) {
        return trait[_traitId];
    }
}
