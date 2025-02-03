// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IBones } from "./interface/IBones.sol";
import { IERC20 } from "./interface/IERC20.sol";
import { INeandersmol } from "./interface/INeandersmol.sol";
import { IDynamicTrait } from "./interface/IDynamicTrait.sol";
import { TraitSelectorLib } from "./Library/TraitSelectorLib.sol";
import { INeandersmolTraitsStorage, Trait } from "./interface/INeandersmolTraitsStorage.sol";

import { Ownable } from "solady/auth/Ownable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

contract DynamicTrait is IDynamicTrait, Ownable {
    using SafeTransferLib for address;
    using TraitSelectorLib for *;

    IBones public bones;
    INeandersmol public neandersmol;
    INeandersmolTraitsStorage public ts;

    uint256 public bonesRequired;

    mapping(bytes4 => Traits) private traitData;
    mapping(address => mapping(bytes4 => uint256)) private price;
    mapping(uint256 => mapping(bytes4 => bool)) private isSet;
    mapping(address => mapping(bytes4 => uint256)) private balance;

    constructor(address _bones, address _ts, address _neandersmol) {
        bones = IBones(_bones);
        ts = INeandersmolTraitsStorage(_ts);
        neandersmol = INeandersmol(_neandersmol);
        _initializeOwner(msg.sender);
        setAmountOfBonesRequired(5000 ether);
    }

    function purchaseTraits(bytes4[] calldata _traitId, address _paymentToken) external payable {
        uint256 totalCost;
        uint256 length = _traitId.length;

        for (uint256 i; i < length; i++) {
            totalCost += _purchaseTrait(_traitId[i], _paymentToken);
        }

        bones.burn(msg.sender, bonesRequired * length);
        if (msg.value > 0) {
            if (msg.value != totalCost) revert InvalidPaymentAmount();
        } else {
            _paymentToken.safeTransferFrom(msg.sender, address(this), totalCost);
        }
    }

    function _purchaseTrait(bytes4 _traitId, address _paymentToken) internal returns (uint256) {
        Traits memory tData = traitData[_traitId];
        if (!ts.traitExists(_traitId)) revert TraitDoesNotExist(_traitId);
        if (tData.amountPurchased != 0 && tData.amountPurchased == tData.maxSupply) {
            revert MaximumSupplyReached(_traitId);
        }

        uint256 traitPrice = msg.value > 0 ? tData.nativeTokenPrice : price[_paymentToken][_traitId];
        if (traitPrice == 0) revert InvalidTrait();
        balance[msg.sender][_traitId]++;
        traitData[_traitId].amountPurchased++;
        emit TraitPurchased(msg.sender, _traitId);

        return traitPrice;
    }

    function manageTraits(uint256 _tokenId, bytes4[] calldata _traitIds, bytes4[] calldata _oldTraitIds) external {
        if (_traitIds.length != _oldTraitIds.length) revert LengthsAreNotEqual();
        if (neandersmol.ownerOf(_tokenId) != msg.sender) revert Unauthorized();
        for (uint256 i; i < _traitIds.length; i++) {
            _manageTrait(_tokenId, _traitIds[i], _oldTraitIds[i]);
        }
    }

    function manageTrait(uint256 _tokenId, bytes4 _newTraitId, bytes4 _oldTraitId) external {
        if (neandersmol.ownerOf(_tokenId) != msg.sender) revert Unauthorized();
        if (_newTraitId == _oldTraitId) revert SameTraitId();
        _manageTrait(_tokenId, _newTraitId, _oldTraitId);
    }

    /**
     * @notice Manages traits for a token by adding, removing, or swapping traits.
     * @dev Handles three cases:
     *      1. Add a new trait when no trait is currently set.
     *      2. Remove an existing trait without adding a new one.
     *      3. Swap an existing trait with a new one.
     * @param _tokenId The ID of the token to update.
     * @param _newTraitId The ID of the new trait to add or swap to.
     * @param _oldTraitId The ID of the old trait to remove or swap from.
     */
    function _manageTrait(uint256 _tokenId, bytes4 _newTraitId, bytes4 _oldTraitId) public {
        // CASE
        // 1. When Old is 0 and new has value - ADD
        // 2. When Old has value and new is 0 - REMOVE
        // 3. When they both have values - SWAP

        // CASE 1
        // i. Decrease the amount of the new and set directly
        // ii. Fetch the selector

        bytes4 oldSelector;
        bytes4 newSelector;
        bytes memory data;
        if (_oldTraitId == bytes4(0) && _newTraitId != bytes4(0)) {
            if (isSet[_tokenId][_newTraitId]) revert TraitAlreadySet();
            if (balance[msg.sender][_newTraitId] == 0) revert InsufficientBalance();
            balance[msg.sender][_newTraitId]--;
            newSelector = ts.getSelector(_newTraitId);
            isSet[_tokenId][_newTraitId] = true;
            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        }
        // CASE 2
        // i. Increase the value of the old
        // ii. Fetch the none value
        // iii. get the selector of the traitType and set the traitId to it
        // iii. set with new none value
        else if (_newTraitId == bytes4(0) && _oldTraitId != bytes4(0)) {
            balance[msg.sender][_oldTraitId]++;

            string memory oldTraitType = ts.getTrait(_oldTraitId).traitType;
            _newTraitId = oldTraitType.getNoneTraitId();

            if (isSet[_tokenId][_newTraitId]) revert NoneTraitAlreadySet();

            oldSelector = ts.getSelector(_oldTraitId);

            newSelector = ts.getSelector(_newTraitId);

            _validateTraitTypeMatch(oldSelector, newSelector);

            isSet[_tokenId][_oldTraitId] = false;
            isSet[_tokenId][_newTraitId] = true;

            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        }
        // CASE 3
        // i. Increase the value of the old and Decrease the new
        // ii. Set the traitId to th new One
        else if (_oldTraitId != bytes4(0) && _newTraitId != bytes4(0)) {
            if (isSet[_tokenId][_newTraitId] || !isSet[_tokenId][_oldTraitId]) revert InvalidTraitState();
            if (balance[msg.sender][_newTraitId] == 0) revert InsufficientBalance();
            balance[msg.sender][_oldTraitId]++;
            balance[msg.sender][_newTraitId]--;

            oldSelector = ts.getSelector(_oldTraitId);

            newSelector = ts.getSelector(_newTraitId);

            _validateTraitTypeMatch(oldSelector, newSelector);
            isSet[_tokenId][_oldTraitId] = false;
            isSet[_tokenId][_newTraitId] = true;
            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        } else {
            revert InvalidTraitState();
        }

        (bool s,) = address(ts).call(data);
        if (!s) {
            revert CallActionFailed();
        }

        // Emit the TraitSet event
        emit TraitSet(_tokenId, _newTraitId);
    }

    function setTraitData(
        bytes4 _traitId,
        uint128 _maxSupply,
        uint256 _nativeTokenPrice,
        address[] calldata _paymentTokens,
        uint256[] calldata _prices
    ) public onlyOwner {
        if (!ts.traitExists(_traitId)) revert TraitDoesNotExist(_traitId);
        traitData[_traitId].maxSupply = _maxSupply;
        traitData[_traitId].nativeTokenPrice = _nativeTokenPrice;
        for (uint256 i; i < _paymentTokens.length; i++) {
            setPrice(_paymentTokens[i], _traitId, _prices[i]);
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
        if (!ts.traitExists(_traitId)) revert TraitDoesNotExist(_traitId);
        price[_paymentToken][_traitId] = _price;
        emit PriceSet(_paymentToken, _traitId, _price);
    }

    function setAmountOfBonesRequired(uint256 _bonesRequired) public onlyOwner {
        bonesRequired = _bonesRequired;
    }

    function withdrawToken(address[] calldata _tokens) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token.balanceOf(address(this)) > 0) {
                _tokens[i].safeTransferAll(msg.sender);
            }
        }
    }

    function _validateTraitTypeMatch(bytes4 _oldSelector, bytes4 _newSelector) internal pure {
        if (_oldSelector != _newSelector) revert TraitTypeMismatch(_oldSelector, _newSelector);
    }

    function getBalance(address _owner, bytes4 _traitId) external view returns (uint256) {
        return balance[_owner][_traitId];
    }

    function getTraitData(bytes4 _selector) external view returns (Traits memory) {
        return traitData[_selector];
    }

    function getTraitPrice(address _paymentToken, bytes4 _traitId) external view returns (uint256) {
        return price[_paymentToken][_traitId];
    }

    function isTraitSet(uint256 _tokenId, bytes4 _traitId) external view returns (bool) {
        return isSet[_tokenId][_traitId];
    }
}
