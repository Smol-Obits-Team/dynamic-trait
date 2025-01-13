// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IBones {
    function burn(address _from, uint256 _amount) external;
    function grantStaking(address _contract) external;
}
