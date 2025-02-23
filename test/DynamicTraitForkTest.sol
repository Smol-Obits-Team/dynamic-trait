// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { IERC20, MockERC20 } from "forge-std/mocks/MockERC20.sol";

import { IDynamicTrait, DynamicTrait, INeandersmolTraitsStorage } from "../src/DynamicTrait.sol";

error Unauthorized();
error ETHTransferFailed();

contract DynamicTraitForkTest is Test {
    DynamicTrait dt;
    uint256 arbitrumFork;
    string ARB_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    bytes4 constant DEFAULT_TRAIT = 0xffffffff;
    bytes4 constant DEFAULT_NONE_VALUE = 0x8ac171a4;

    address constant TS = 0xfA23a230c5e69500821106B0F8cB4b4834c4696E;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant BONES = 0x74912f00BdA1C2030Cf33e7194803259426e64A4;
    address constant MAGIC = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;
    address constant NEANDERSMOL = 0xC4d94093Ee935c4c01aBeb78860b603752eEf3D5;

    address constant FORK = 0x14ccBE5aee7cd939ff5E66CBd15cE4303134A2BF;

    address constant ADMIN = 0xd411c5C70339F15bCE20dD033B5FfAa3F8d2806f;
    address constant SECOND_ADMIN = 0xc8dd8da93c79F00FbFcdDb5bBbb1233A02cF0296;

    bytes4 constant TOP_KNOT = 0xef4952b5;
    bytes4 constant FIGHTER_HELMET = 0x4cc41ad5;
    bytes4 constant LAND_RULER_CROWN = 0x4d310d8b;

    bytes4 constant BLEACH_CUT = 0xf9b5520c;
    bytes4 constant NONE_BACKGROUND = 0x00000001;
    bytes4 constant NONE_HAIR = 0x00000008;

    uint256 public constant TRAITS_CONTROLLER_ROLE = uint256(keccak256("TRAITS_CONTROLLER_ROLE"));

    uint256 public constant PRICE = 0.001 ether;

    address constant OWNER = address(0x01);

    function setUp() public {
        arbitrumFork = vm.createFork(ARB_RPC_URL);
        vm.selectFork(arbitrumFork);

        dt = new DynamicTrait();

        dt.initialize(BONES, TS, NEANDERSMOL);

        vm.prank(ADMIN);
        IBones(BONES).grantStaking(address(dt));

        vm.prank(SECOND_ADMIN);
        INeandersmolTraitsStorage(TS).grantRoles(address(dt), TRAITS_CONTROLLER_ROLE);

        dt.setTraitData(FIGHTER_HELMET, 50, PRICE, _getAddress(), _getPrice(10 ether, 5 * 10 ** 6));
        dt.setTraitData(TOP_KNOT, 25, PRICE, _getAddress(), _getPrice(15 ether, 10 * 10 ** 6));
        dt.setTraitData(BLEACH_CUT, 25, PRICE, _getAddress(), _getPrice(15 ether, 10 * 10 ** 6));
        dt.setTraitData(LAND_RULER_CROWN, 25, PRICE, _getAddress(), _getPrice(15 ether, 10 * 10 ** 6));
    }

    function testPurchaseTraitWithUSDC() public {
        deal(BONES, FORK, IERC20(BONES).totalSupply() - 5, true);
        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(FORK);
        uint256 bonesBalanceBefore = IERC20(BONES).balanceOf(FORK);

        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        bytes4[] memory id = new bytes4[](1);
        id[0] = 0x1aef0ec5;

        vm.expectRevert(abi.encodeWithSelector(IDynamicTrait.TraitDoesNotExist.selector, id[0]));

        dt.purchaseTraits(id, USDC);

        id[0] = FIGHTER_HELMET;
        dt.purchaseTraits(id, USDC);

        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(FORK);
        uint256 bonesBalanceAfter = IERC20(BONES).balanceOf(FORK);

        uint256 traitUsdcPrice = dt.getTraitPrice(USDC, FIGHTER_HELMET);
        uint256 amountOfTraitLeft =
            dt.getTraitData(FIGHTER_HELMET).maxSupply - dt.getTraitData(FIGHTER_HELMET).amountPurchased;

        assertEq(usdcBalanceAfter, usdcBalanceBefore - traitUsdcPrice);
        assertEq(bonesBalanceAfter, bonesBalanceBefore - 5000 ether);
        assertEq(IERC20(USDC).balanceOf(address(dt)), traitUsdcPrice);
        assertEq(dt.getTraitData(FIGHTER_HELMET).amountPurchased, 1);
        assertEq(amountOfTraitLeft, 49);

        while (dt.getTraitData(FIGHTER_HELMET).maxSupply > (dt.getTraitData(FIGHTER_HELMET).amountPurchased)) {
            dt.purchaseTraits(id, USDC);
        }

        assertEq(dt.getTraitData(FIGHTER_HELMET).amountPurchased, 50);

        vm.expectRevert(abi.encodeWithSelector(IDynamicTrait.MaximumSupplyReached.selector, FIGHTER_HELMET));
        dt.purchaseTraits(id, USDC);

        bytes4[] memory noneId = new bytes4[](1);
        noneId[0] = NONE_BACKGROUND;

        vm.expectRevert(IDynamicTrait.InvalidTrait.selector);
        dt.purchaseTraits(noneId, USDC);

        vm.stopPrank();
    }

    function testPurchaseTraitWithNativeToken() public {
        uint256 ethBalanceBefore = FORK.balance;
        uint256 bonesBalanceBefore = IERC20(BONES).balanceOf(FORK);

        vm.startPrank(FORK);

        IERC20(BONES).approve(address(dt), type(uint256).max);

        bytes4[] memory id = new bytes4[](2);
        id[0] = FIGHTER_HELMET;
        id[1] = BLEACH_CUT;

        uint256 price = dt.getTraitData(FIGHTER_HELMET).nativeTokenPrice + dt.getTraitData(BLEACH_CUT).nativeTokenPrice;

        dt.purchaseTraits{ value: price }(id, address(0));

        vm.stopPrank();

        uint256 ethBalanceAfter = FORK.balance;
        uint256 bonesBalanceAfter = IERC20(BONES).balanceOf(FORK);

        assertEq(ethBalanceAfter, ethBalanceBefore - price);
        assertEq(bonesBalanceAfter, bonesBalanceBefore - dt.bonesRequired() * id.length);
        assertEq(address(dt).balance, price);
        assertEq(dt.getTraitData(FIGHTER_HELMET).amountPurchased, 1);
    }

    function testAddTrait() public {
        uint256 tokenId = 5521;
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        bytes4[] memory id = new bytes4[](1);
        id[0] = TOP_KNOT;

        dt.purchaseTraits(id, USDC);

        vm.roll(block.number + 1);

        vm.expectRevert(Unauthorized.selector);
        dt.manageTrait(2, TOP_KNOT, 0);

        vm.expectRevert(IDynamicTrait.InsufficientBalance.selector);
        dt.manageTrait(tokenId, BLEACH_CUT, bytes4(0));

        dt.manageTrait(tokenId, TOP_KNOT, bytes4(0));

        vm.expectRevert(IDynamicTrait.TraitAlreadySet.selector);
        dt.manageTrait(tokenId, TOP_KNOT, bytes4(0));
        assertEq(dt.getBalance(FORK, TOP_KNOT), 0);

        vm.stopPrank();

        assertEq(INeandersmolTraitsStorage(TS).getTokenTraitsTypes(tokenId).hair, TOP_KNOT);
        assertTrue(dt.isTraitSet(tokenId, TOP_KNOT));
    }

    function testRemoveTrait() public {
        uint256 tokenId = 3700;
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        bytes4[] memory id = new bytes4[](1);
        id[0] = BLEACH_CUT;

        dt.purchaseTraits(id, USDC);

        vm.roll(block.number + 1);

        dt.manageTrait(tokenId, BLEACH_CUT, bytes4(0)); // 0

        vm.roll(block.number + 2);

        dt.manageTrait(tokenId, bytes4(0), BLEACH_CUT); // 1

        vm.expectRevert(IDynamicTrait.NoneTraitAlreadySet.selector);
        dt.manageTrait(tokenId, bytes4(0), BLEACH_CUT);

        vm.stopPrank();

        assertEq(dt.getBalance(FORK, BLEACH_CUT), 1); // 1

        assertEq(INeandersmolTraitsStorage(TS).getTokenTraitsTypes(tokenId).hair, NONE_HAIR);
        assertFalse(dt.isTraitSet(tokenId, BLEACH_CUT));
    }

    function testSwapTrait() public {
        uint256 tokenId = 3700;
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        bytes4[] memory id = new bytes4[](2);
        id[0] = TOP_KNOT;
        id[1] = BLEACH_CUT;

        dt.purchaseTraits(id, USDC);

        vm.roll(block.number + 1);

        dt.manageTrait(tokenId, TOP_KNOT, bytes4(0)); // -1

        vm.roll(block.number + 2);

        dt.manageTrait(tokenId, BLEACH_CUT, TOP_KNOT); // + 1

        vm.stopPrank();

        assertEq(dt.getBalance(FORK, TOP_KNOT), 1);
        assertEq(dt.getBalance(FORK, BLEACH_CUT), 0);
        assertEq(INeandersmolTraitsStorage(TS).getTokenTraitsTypes(tokenId).hair, BLEACH_CUT);
        assertTrue(dt.isTraitSet(tokenId, BLEACH_CUT));
        assertFalse(dt.isTraitSet(tokenId, TOP_KNOT));
    }

    function testWithdrawTokens() public {
        dt.setAmountOfBonesRequired(6000 ether);
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        bytes4[] memory ids = new bytes4[](2);
        ids[0] = TOP_KNOT;
        ids[1] = BLEACH_CUT;
        dt.purchaseTraits(ids, USDC);

        vm.stopPrank();
        address[] memory tokens = new address[](1);
        tokens[0] = USDC;

        dt.withdrawToken(tokens);

        assertEq(
            IERC20(USDC).balanceOf(address(this)), dt.getTraitPrice(USDC, TOP_KNOT) + dt.getTraitPrice(USDC, BLEACH_CUT)
        );

        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        bytes4[] memory id = new bytes4[](1);
        id[0] = TOP_KNOT;

        vm.prank(FORK);
        dt.purchaseTraits{ value: PRICE }(id, USDC);

        vm.expectRevert(ETHTransferFailed.selector);
        dt.withdrawToken(tokens);

        dt.transferOwnership(OWNER);

        vm.prank(OWNER);
        dt.withdrawToken(tokens);
    }

    function testDefaultValue() public {
        uint256 tokenId = 5521;
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);
        bytes4[] memory newTraitIds = new bytes4[](2);
        newTraitIds[0] = TOP_KNOT;
        newTraitIds[1] = BLEACH_CUT;

        dt.purchaseTraits(newTraitIds, USDC);

        dt.manageTrait(tokenId, TOP_KNOT, 0);

        // bytes4 caveSmol = 0xdb5cf4f8;

        assertEq(dt.getDefaultTrait(TOP_KNOT), NONE_HAIR);
        dt.manageTrait(tokenId, BLEACH_CUT, TOP_KNOT);

        assertEq(dt.getDefaultTrait(BLEACH_CUT), NONE_HAIR);

        dt.manageTrait(tokenId, DEFAULT_TRAIT, BLEACH_CUT);

        assertEq(INeandersmolTraitsStorage(TS).getTokenTraitsTypes(tokenId).hair, NONE_HAIR);

        assertEq(dt.getDefaultTrait(NONE_HAIR), NONE_HAIR);

        vm.stopPrank();
    }

    function testManageBulkTraits() public {
        uint256 tokenId = 5521;
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);
        bytes4[] memory newTraitIds = new bytes4[](4);
        newTraitIds[0] = TOP_KNOT;
        newTraitIds[1] = BLEACH_CUT;
        newTraitIds[2] = LAND_RULER_CROWN;
        newTraitIds[3] = FIGHTER_HELMET;

        bytes4[] memory oldTraitIds = new bytes4[](newTraitIds.length);
        oldTraitIds[0] = 0x000000;
        oldTraitIds[1] = 0x000000;
        oldTraitIds[2] = 0x000000;
        oldTraitIds[3] = 0x000000;

        dt.purchaseTraits(newTraitIds, USDC);

        vm.expectRevert(IDynamicTrait.LengthsAreNotEqual.selector);
        dt.manageTraits(tokenId, newTraitIds, new bytes4[](0));

        vm.expectRevert(Unauthorized.selector);
        dt.manageTraits(504, newTraitIds, oldTraitIds);

        dt.manageTraits(tokenId, newTraitIds, oldTraitIds);

        vm.stopPrank();

        assertEq(INeandersmolTraitsStorage(TS).getTokenTraitsTypes(tokenId).hair, BLEACH_CUT);
    }

    function testSimulation() public {
        vm.startPrank(0xC77eD1b54694f52deF2AEB0c5038632202dc50E6);

        vm.stopPrank();
    }

    function testState() public view {
        assertEq(dt.ts().traitExists(FIGHTER_HELMET), true);
        assertEq(INeandersmolTraitsStorage(TS).hasAnyRole(address(dt), TRAITS_CONTROLLER_ROLE), true);
    }

    function _getAddress() internal pure returns (address[] memory) {
        address[] memory token = new address[](2);
        token[0] = MAGIC;
        token[1] = USDC;
        return token;
    }

    function _getPrice(uint256 _a, uint256 _b) internal pure returns (uint256[] memory) {
        uint256[] memory price = new uint256[](2);
        price[0] = _a;
        price[1] = _b;
        return price;
    }
}

interface IBones {
    function grantStaking(address _contract) external;
}
