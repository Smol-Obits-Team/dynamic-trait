// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IBones } from "./interface/IBones.sol";
import { IDynamicTrait } from "./interface/IDynamicTrait.sol";
import { TraitSelectorLib } from "./Library/TraitSelectorLib.sol";
import { INeandersmolTraitsStorage, Trait } from "./interface/INeandersmolTraitsStorage.sol";

import { Ownable } from "solady/auth/Ownable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

contract DynamicTrait is IDynamicTrait, Ownable {
    using SafeTransferLib for address;
    using TraitSelectorLib for string;

    IBones public bones;
    INeandersmolTraitsStorage public ts;

    uint256 public bonesRequired;

    mapping(bytes4 => Traits) private traitData;
    mapping(uint256 => mapping(bytes4 => bool)) public isOwned;
    mapping(address => mapping(bytes4 => uint256)) public price;

    constructor(address _bones, address _ts) {
        bones = IBones(_bones);
        ts = INeandersmolTraitsStorage(_ts);
        _initializeOwner(msg.sender);
        setAmountOfBonesRequired(5000 ether);
    }

    function purchaseTrait(bytes4 _traitId, uint256 _tokenId, address _paymentToken) external {
        Traits memory tData = traitData[_traitId];
        uint256 traitPrice = price[_paymentToken][_traitId];
        if (isOwned[_tokenId][_traitId]) revert AlreadyOwned(_traitId);
        if (!ts.traitExists(_traitId)) revert TraitDoesNotExist();
        if (traitPrice == 0) revert InvalidTrait();
        if (tData.amountPurchased == tData.maxSupply) revert MaximumSupplyReached(_traitId);

        isOwned[_tokenId][_traitId] = true;
        traitData[_traitId].amountPurchased++;

        bones.burn(msg.sender, bonesRequired);

        _paymentToken.safeTransferFrom(msg.sender, address(this), traitPrice);

        emit TraitPurchased(_tokenId, _traitId);
    }

    function setTraits(uint256 _tokenId, bytes4[] calldata _traitId) external {
        for (uint256 i; i < _traitId.length; i++) {
            setTrait(_tokenId, _traitId[i]);
        }
    }

    function setTrait(uint256 _tokenId, bytes4 _traitId) public {
        if (!isOwned[_tokenId][_traitId]) revert NotOwned(_traitId);

        string memory traitType = ts.getTrait(_traitId).traitType;
        bytes4 selector = traitType.getSelector();

        bytes memory data = abi.encodeWithSelector(selector, _tokenId, _traitId);
        (bool success,) = address(ts).call(data);

        if (!success) {
            revert CallActionFailed();
        }

        emit TraitSet(_tokenId, _traitId);
    }

    function setTraitData(
        bytes4 _traitId,
        uint128 _maxSupply,
        address[] calldata _paymentTokens,
        uint256[] calldata _prices
    ) public onlyOwner {
        traitData[_traitId].maxSupply = _maxSupply;
        for (uint256 i; i < _paymentTokens.length; i++) {
            price[_paymentTokens[i]][_traitId] = _prices[i];
        }
    }

    function setPrice(address _paymentToken, bytes4[] calldata _traitIds, uint256[] calldata _prices)
        public
        onlyOwner
    {
        for (uint256 i; i < _traitIds.length; i++) {
            setPrice(_paymentToken, _traitIds[i], _prices[i]);
        }
    }

    function setPrice(address _paymentToken, bytes4 _traitId, uint256 _price) public onlyOwner {
        if (!ts.traitExists(_traitId)) revert TraitDoesNotExist();
        price[_paymentToken][_traitId] = _price;
    }

    function setAmountOfBonesRequired(uint256 _bonesRequired) public onlyOwner {
        bonesRequired = _bonesRequired;
    }

    function withdrawToken(address[] calldata _tokens) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            _tokens[i].safeTransferAll(msg.sender);
        }
    }

    function getTraitData(bytes4 _selector) external view returns (Traits memory) {
        return traitData[_selector];
    }

    function getTraitPrice(address _paymentToken, bytes4 _traitId) external view returns (uint256) {
        return price[_paymentToken][_traitId];
    }
}
