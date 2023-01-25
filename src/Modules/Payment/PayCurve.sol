// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { PayCurveInterface } from "./interfaces/PayCurveInterface.sol";

contract PayCurve is 
    PayCurveInterface 
{
    constructor () {}

    function curvePoint(uint256 x) 
        public 
        pure 
        returns (
            uint256
        ) 
    {
        return x**2;
    }
}
