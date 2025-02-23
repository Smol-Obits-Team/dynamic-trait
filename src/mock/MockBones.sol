// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "solady/tokens/ERC20.sol";

contract MockBones is ERC20 {
    uint256 constant TS = 100_000_000 ether;

    constructor() {
        _mint(msg.sender, TS);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }

    function name() public view virtual override returns (string memory) {
        return "Bones";
    }

    function symbol() public view virtual override returns (string memory) {
        return "Bones";
    }
}
