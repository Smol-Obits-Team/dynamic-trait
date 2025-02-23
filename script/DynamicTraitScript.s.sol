// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";

import { DynamicTrait } from "../src/DynamicTrait.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

import { MockStable } from "../src/mock/MockStable.sol";
import { MockBones } from "../src/mock/MockBones.sol";
import { MockMagic } from "../src/mock/MockMagic.sol";

contract DynamicTraitScript is Script {
    string constant DYNAMIC_TRAIT = "DynamicTrait.sol";

    address constant BONES = 0x74912f00BdA1C2030Cf33e7194803259426e64A4;
    address constant T_S = 0xfA23a230c5e69500821106B0F8cB4b4834c4696E;
    address constant NEANDERSMOL = 0xC4d94093Ee935c4c01aBeb78860b603752eEf3D5;

    function run() external returns (address) {
        vm.startBroadcast();

        address dtProxyAddress = Upgrades.deployTransparentProxy(
            DYNAMIC_TRAIT, msg.sender, abi.encodeCall(DynamicTrait.initialize, (BONES, T_S, NEANDERSMOL))
        );

        vm.stopBroadcast();

        return dtProxyAddress;
    }
}
