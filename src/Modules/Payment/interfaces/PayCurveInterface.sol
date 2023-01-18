// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface PayCurveInterface {
    function curvePoint(uint256 x) 
        external 
        returns (
            uint256
        );
}
