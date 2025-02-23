// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "solady/tokens/ERC20.sol";

contract MockStable is ERC20 {
    uint8 constant DECIMAL = 6;
    uint256 constant TS = 100_000_000 * 10 ** DECIMAL;

    constructor() {
        _mint(msg.sender, TS);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMAL;
    }

    function name() public view virtual override returns (string memory) {
        return "Mock Stable";
    }

    function symbol() public view virtual override returns (string memory) {
        return "MS";
    }
}
