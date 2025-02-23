// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IBones } from "./interface/IBones.sol";
import { IERC20 } from "./interface/IERC20.sol";
import { INeandersmol } from "./interface/INeandersmol.sol";
import { IDynamicTrait } from "./interface/IDynamicTrait.sol";
import { TraitManagerLib } from "./Library/TraitManagerLib.sol";
import { INeandersmolTraitsStorage, Trait } from "./interface/INeandersmolTraitsStorage.sol";

import { Ownable } from "solady/auth/Ownable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { Initializable } from "solady/utils/Initializable.sol";

contract DynamicTrait is IDynamicTrait, Ownable, Initializable {
    using SafeTransferLib for address;

    /// @notice Interface for the Bones contract (ERC-20 token for transactions)s
    IBones public bones;

    /// @notice Interface for the Neandersmol contract (NFT ownership management)
    INeandersmol public neandersmol;

    /// @notice Interface for the Neandersmol Traits Storage contract (trait management)
    INeandersmolTraitsStorage public ts;

    /// @notice Amount of Bones required for trait-related actions
    uint256 public bonesRequired;

    /// @dev Default trait identifier, used as a fallback when setting back to the initial trait
    bytes4 constant DEFAULT_TRAIT = 0xffffffff;

    /// @dev Default "None" trait identifier, representing an empty trait slot
    bytes4 constant DEFAULT_NONE_VALUE = 0x8ac171a4;

    /// @notice Mapping of trait IDs to their corresponding `Traits` data structure
    mapping(bytes4 => Traits) private traitData;

    /// @notice Mapping of payment token addresses to trait prices
    mapping(address => mapping(bytes4 => uint256)) private price;

    /// @notice Mapping to track whether a specific trait is set for a token
    mapping(uint256 => mapping(bytes4 => bool)) private isSet;

    /// @notice Mapping of user balances for specific trait IDs
    mapping(address => mapping(bytes4 => uint256)) private balance;

    /// @notice Mapping to store default trait assignments for specific traits
    mapping(bytes4 => bytes4) private defaultTrait;

    function initialize(address _bones, address _ts, address _neandersmol) public initializer {
        bones = IBones(_bones);
        ts = INeandersmolTraitsStorage(_ts);
        neandersmol = INeandersmol(_neandersmol);
        _initializeOwner(msg.sender);
        setAmountOfBonesRequired(5000 ether);
    }

    /// inheritdoc IDynamicTrait
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

    /// inheritdoc IDynamicTrait
    function manageTraits(uint256 _tokenId, bytes4[] calldata _traitIds, bytes4[] calldata _oldTraitIds) external {
        if (_traitIds.length != _oldTraitIds.length) revert LengthsAreNotEqual();
        if (neandersmol.ownerOf(_tokenId) != msg.sender) revert Unauthorized();
        for (uint256 i; i < _traitIds.length; i++) {
            _manageTrait(_tokenId, _traitIds[i], _oldTraitIds[i]);
        }
    }

    /// inheritdoc IDynamicTrait
    function manageTrait(uint256 _tokenId, bytes4 _newTraitId, bytes4 _oldTraitId) external {
        if (neandersmol.ownerOf(_tokenId) != msg.sender) revert Unauthorized();
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
    function _manageTrait(uint256 _tokenId, bytes4 _newTraitId, bytes4 _oldTraitId) internal {
        bytes4 oldSelector;
        bytes4 newSelector;
        bytes memory data;

        if (_newTraitId == _oldTraitId) revert SameTraitId();
        if (_newTraitId == DEFAULT_TRAIT) {
            if (!isSet[_tokenId][_oldTraitId]) revert TraitNotSet();
            bytes4 defaultTraitValue = defaultTrait[_oldTraitId];
            _newTraitId = defaultTraitValue;
            newSelector = TraitManagerLib.getSelector(ts, defaultTraitValue);
            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        }
        // 1. When Old is bytes4(0) and new has value - ADD
        else if (_oldTraitId == bytes4(0) && _newTraitId != bytes4(0)) {
            if (isSet[_tokenId][_newTraitId]) revert TraitAlreadySet();
            if (balance[msg.sender][_newTraitId] == 0) revert InsufficientBalance();
            balance[msg.sender][_newTraitId]--;
            newSelector = TraitManagerLib.getSelector(ts, _newTraitId);
            isSet[_tokenId][_newTraitId] = true;
            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        }
        // 2. When Old has value and new is bytes4(0) - REMOVE
        else if (_newTraitId == bytes4(0) && _oldTraitId != bytes4(0)) {
            balance[msg.sender][_oldTraitId]++;

            string memory oldTraitType = ts.getTrait(_oldTraitId).traitType;
            _newTraitId = TraitManagerLib.getNoneTraitId(oldTraitType);

            if (isSet[_tokenId][_newTraitId]) revert NoneTraitAlreadySet();

            oldSelector = TraitManagerLib.getSelector(ts, _oldTraitId);

            newSelector = TraitManagerLib.getSelector(ts, _newTraitId);

            _validateTraitTypeMatch(oldSelector, newSelector);

            isSet[_tokenId][_oldTraitId] = false;
            isSet[_tokenId][_newTraitId] = true;

            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        }
        // 3. When they both have values - SWAP
        else if (_oldTraitId != 0 && _newTraitId != bytes4(0)) {
            if (isSet[_tokenId][_newTraitId] || !isSet[_tokenId][_oldTraitId]) revert InvalidTraitState();
            if (balance[msg.sender][_newTraitId] == 0) revert InsufficientBalance();
            balance[msg.sender][_oldTraitId]++;
            balance[msg.sender][_newTraitId]--;

            oldSelector = TraitManagerLib.getSelector(ts, _oldTraitId);

            newSelector = TraitManagerLib.getSelector(ts, _newTraitId);

            _validateTraitTypeMatch(oldSelector, newSelector);
            isSet[_tokenId][_oldTraitId] = false;
            isSet[_tokenId][_newTraitId] = true;
            data = abi.encodeWithSelector(newSelector, _tokenId, _newTraitId);
        } else {
            revert InvalidTraitState();
        }

        _updateDefaultTrait(_tokenId, _newTraitId, _oldTraitId);

        (bool s,) = address(ts).call(data);
        if (!s) {
            revert CallActionFailed();
        }

        // Emit the TraitSet event
        emit TraitChanged(msg.sender, _oldTraitId, _newTraitId);
    }

    /**
     * @notice Updates the default trait mapping for a given token.
     * @dev Ensures that when a trait is changed, its default value is set correctly.
     * @param _tokenId The ID of the token whose trait is being updated.
     * @param _newTraitId The ID of the new trait being applied.
     * @param _oldTraitId The ID of the previous trait before the update.
     */
    function _updateDefaultTrait(uint256 _tokenId, bytes4 _newTraitId, bytes4 _oldTraitId) internal {
        if (defaultTrait[_oldTraitId] == bytes4(0)) {
            bytes4 defaultValue = TraitManagerLib.getDefaultTrait(ts, _tokenId, _newTraitId);

            string memory oldTraitType = ts.getTrait(_newTraitId).traitType;
            bytes4 noneValue = TraitManagerLib.getNoneTraitId(oldTraitType);

            defaultTrait[_newTraitId] = defaultValue == DEFAULT_NONE_VALUE ? noneValue : defaultValue;
        } else {
            defaultTrait[_newTraitId] = defaultTrait[_oldTraitId];
            defaultTrait[_oldTraitId] = bytes4(0);
        }
    }

    /**
     * @notice Internal function to handle the purchase of a trait.
     * @dev Checks for trait existence, supply availability, and payment validity before increasing the user's balance.
     * @param _traitId The ID of the trait being purchased.
     * @param _paymentToken The address of the ERC-20 token used for payment (or zero address for ETH).
     * @return traitPrice The price of the purchased trait.
     */
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
            _setPrice(_paymentTokens[i], _traitId, _prices[i]);
        }

        emit NativeTokenPriceUpdated(_traitId, _nativeTokenPrice);
    }

    function setPrice(address _paymentToken, bytes4[] calldata _traitIds, uint256[] calldata _prices)
        public
        onlyOwner
    {
        for (uint256 i; i < _traitIds.length; i++) {
            _setPrice(_paymentToken, _traitIds[i], _prices[i]);
        }
    }

    function TraitsStorageAddress(address _ts) external onlyOwner {
        ts = INeandersmolTraitsStorage(_ts);
    }

    function _setPrice(address _paymentToken, bytes4 _traitId, uint256 _price) internal {
        if (!ts.traitExists(_traitId)) revert TraitDoesNotExist(_traitId);
        if (_price < 1 * IERC20(_paymentToken).decimals()) revert PriceTooLow();
        price[_paymentToken][_traitId] = _price;
        emit PriceSet(_traitId, _paymentToken, _price);
    }

    function setBonesAddress(address _bones) public onlyOwner {
        bones = IBones(_bones);
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

    function getDefaultTrait(bytes4 _traitId) external view returns (bytes4) {
        return defaultTrait[_traitId];
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
