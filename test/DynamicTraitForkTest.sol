// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { IBones } from "../src/interface/IBones.sol";
import { IERC20, MockERC20 } from "forge-std/mocks/MockERC20.sol";

import { DynamicTrait, INeandersmolTraitsStorage } from "../src/DynamicTrait.sol";

contract DynamicTraitForkTest is Test {
    DynamicTrait dt;
    uint256 arbitrumFork;
    string ARB_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

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

    uint256 public constant TRAITS_CONTROLLER_ROLE = uint256(keccak256("TRAITS_CONTROLLER_ROLE"));

    function setUp() public {
        arbitrumFork = vm.createFork(ARB_RPC_URL);
        vm.selectFork(arbitrumFork);

        dt = new DynamicTrait(BONES, TS);

        vm.prank(ADMIN);
        IBones(BONES).grantStaking(address(dt));

        vm.prank(SECOND_ADMIN);
        INeandersmolTraitsStorage(TS).grantRoles(address(dt), TRAITS_CONTROLLER_ROLE);

        dt.setTraitData(FIGHTER_HELMET, 50, _getAddress(), _getPrice(10 ether, 5 * 10 ** 6));
        dt.setTraitData(TOP_KNOT, 25, _getAddress(), _getPrice(15 ether, 10 * 10 ** 6));
    }

    function testPurchaseTrait() public {
        uint256 tokenId = 5521;
        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(FORK);
        uint256 bonesBalanceBefore = IERC20(BONES).balanceOf(FORK);

        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        dt.purchaseTrait(FIGHTER_HELMET, tokenId, USDC);

        vm.stopPrank();

        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(FORK);
        uint256 bonesBalanceAfter = IERC20(BONES).balanceOf(FORK);

        uint256 traitUsdcPrice = dt.price(USDC, FIGHTER_HELMET);

        assertEq(usdcBalanceAfter, usdcBalanceBefore - traitUsdcPrice);
        assertEq(bonesBalanceAfter, bonesBalanceBefore - 5000 ether);
        assertEq(IERC20(USDC).balanceOf(address(dt)), traitUsdcPrice);
        assertEq(dt.isOwned(tokenId, FIGHTER_HELMET), true);
        assertEq(dt.getTraitData(FIGHTER_HELMET).amountPurchased, 1);
    }

    event S(string);

    function testSetTrait() public {
        uint256 tokenId = 5521;
        vm.startPrank(FORK);
        IERC20(BONES).approve(address(dt), type(uint256).max);
        IERC20(USDC).approve(address(dt), type(uint256).max);

        dt.purchaseTrait(TOP_KNOT, tokenId, USDC);

        vm.roll(block.number + 1);

        dt.setTrait(tokenId, TOP_KNOT);

        vm.stopPrank();

        assertEq(INeandersmolTraitsStorage(TS).getTokenTraitsTypes(tokenId).hair, TOP_KNOT);
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

interface INeandersmol {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
