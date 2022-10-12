// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPayCurve {
    function curvePoint(uint256 x) external returns (uint256);
}
