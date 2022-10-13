// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PayCurve {
    function curvePoint(uint256 x) public pure returns (uint256) {
        return x**2;
    }
}
