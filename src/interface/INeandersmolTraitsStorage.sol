// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

struct Neander {
    bytes4 background;
    bytes4 sky;
    bytes4 land;
    bytes4 neandersmol;
    bytes4 skin;
    bytes4 top;
    bytes4 jewelry;
    bytes4 face;
    bytes4 hair;
    bytes4 hat;
    bytes4 hand;
    bytes4 mask;
    bytes4 special;
    string gender;
}

struct Trait {
    string traitType;
    string traitName;
    string pngImage;
}

interface INeandersmolTraitsStorage {
    function grantRoles(address user, uint256 roles) external;
    function traitExists(bytes4 _traitId) external view returns (bool);

    function getTokenTraitsTypes(uint256 _tokenId) external view returns (Neander memory);

    function getTrait(bytes4 _traitId) external view returns (Trait memory);

    function setNeandersmolBackgroundTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolSkyTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolLandTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolSkinTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolTopTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolJewelryTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolFaceTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolHairTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolHatTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolHandTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolMaskTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function setNeandersmolSpecialTrait(uint256 _tokenId, bytes4 _traitIds) external;

    function addTrait(bytes4 _traitId, Trait calldata _trait) external;

    function hasAnyRole(address user, uint256 roles) external view returns (bool);
}
