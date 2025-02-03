// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDynamicTrait {
    /**
     * @dev Thrown when two arrays that are expected to have the same length do not match in size.
     */
    error LengthsAreNotEqual();

    /**
     * @dev Thrown when an external contract call fails.
     */
    error CallFailed();

    /**
     * @dev Thrown when trying to set a trait to the same ID as the existing one.
     */
    error SameTraitId();

    /**
     * @dev Thrown when an invalid trait is used.
     */
    error InvalidTrait();

    /**
     * @dev Thrown when attempting to set a trait that is already assigned.
     */
    error TraitAlreadySet();

    /**
     * @dev Thrown when an external contract call to update a trait fails.
     */
    error CallActionFailed();

    /**
     * @dev Thrown when an invalid trait state transition is attempted.
     */
    error InvalidTraitState();

    /**
     * @dev Thrown when a user does not have enough balance to acquire a trait.
     */
    error InsufficientBalance();

    /**
     * @dev Thrown when attempting to set a "None" trait when it is already set.
     */
    error NoneTraitAlreadySet();

    /**
     * @dev Thrown when the payment amount does not match the expected cost.
     */
    error InvalidPaymentAmount();

    /**
     * @dev Thrown when a user tries to modify a trait they do not own.
     * @param traitId The trait ID that the user does not own.
     */
    error NotOwned(bytes4 traitId);

    /**
     * @dev Thrown when a user tries to purchase a trait they already own.
     * @param traitId The trait ID that is already owned by the user.
     */
    error AlreadyOwned(bytes4 traitId);

    /**
     * @dev Thrown when attempting to access a trait that does not exist.
     * @param traitId The trait ID that does not exist.
     */
    error TraitDoesNotExist(bytes4 traitId);

    /**
     * @dev Thrown when the maximum supply for a specific trait is reached.
     * @param traitId The trait ID that has reached its maximum supply.
     */
    error MaximumSupplyReached(bytes4 traitId);

    /**
     * @dev Thrown when attempting to replace a trait with another trait of a different type.
     * @param oldTrait The old trait ID that was being replaced.
     * @param newTrait The new trait ID that does not match the expected type.
     */
    error TraitTypeMismatch(bytes4 oldTrait, bytes4 newTrait);

    /**
     * @dev Struct representing a trait and its supply information.
     * @param maxSupply The maximum supply of this trait.
     * @param amountPurchased The number of times this trait has been purchased.
     * @param nativeTokenPrice The price of this trait in the native token (ETH or ERC-20).
     */
    struct Traits {
        uint128 maxSupply;
        uint128 amountPurchased;
        uint256 nativeTokenPrice;
    }

    /**
     * @notice Manages multiple traits for a given token ID.
     * @param _tokenId The ID of the NFT whose traits are being managed.
     * @param _traitId The array of trait IDs being added.
     * @param _removingTrait The array of trait IDs being removed.
     */
    function manageTraits(uint256 _tokenId, bytes4[] calldata _traitId, bytes4[] calldata _removingTrait) external;

    /**
     * @notice Allows a user to purchase new traits using ETH or an ERC-20 token.
     * @param _traitId The array of trait IDs being purchased.
     * @param _paymentToken The address of the ERC-20 token used for payment (or zero address for ETH).
     */
    function purchaseTraits(bytes4[] calldata _traitId, address _paymentToken) external payable;

    /**
     * @notice Manages an individual trait for a specific token.
     * @param _tokenId The ID of the NFT whose trait is being updated.
     * @param _newTraitId The trait ID being added or swapped in.
     * @param _oldTraitId The existing trait ID being replaced or removed.
     */
    function manageTrait(uint256 _tokenId, bytes4 _newTraitId, bytes4 _oldTraitId) external;
    /**
     * @dev Emitted when a trait is set for a token.
     * @param tokenId The ID of the NFT that received the trait.
     * @param traitId The ID of the trait that was set.
     */

    event TraitSet(uint256 indexed tokenId, bytes4 indexed traitId);

    /**
     * @dev Emitted when a trait is purchased.
     * @param owner The address of the user who purchased the trait.
     * @param traitId The ID of the purchased trait.
     */
    event TraitPurchased(address indexed owner, bytes4 indexed traitId);

    /**
     * @dev Emitted when a price is set for a trait.
     * @param paymentToken The address of the ERC-20 token used for payment (or zero address for ETH).
     * @param traitId The ID of the trait whose price is being updated.
     * @param price The new price of the trait.
     */
    event PriceSet(address indexed paymentToken, bytes4 indexed traitId, uint256 indexed price);
}
