// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDynamicTrait {
    error InvalidTrait();
    error CallActionFailed();
    error TraitDoesNotExist();
    error NotOwned(bytes4 traitId);
    error AlreadyOwned(bytes4 traitId);
    error MaximumSupplyReached(bytes4 traitId);

    struct Traits {
        uint128 maxSupply;
        uint128 amountPurchased;
    }

    function purchaseTrait(bytes4 _traitId, uint256 _tokenId, address _paymentToken) external;

    function setTraits(uint256 _tokenId, bytes4[] calldata _traitId) external;

    function setTrait(uint256 _tokenId, bytes4 _traitId) external;

    event TraitSet(uint256 indexed tokenId, bytes4 indexed traitId);
    event TraitPurchased(uint256 indexed tokenId, bytes4 indexed traitId);
}
