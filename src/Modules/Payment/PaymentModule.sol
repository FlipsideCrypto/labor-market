// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import { PayCurveInterface } from "./interfaces/PayCurveInterface.sol";

contract PaymentModule {
    modifier onlyMarket() {
        _;
    }

    function earned(
          address payCurve
        , uint256 x
    ) 
        public 
        returns (
            uint256
        ) 
    {
        return PayCurveInterface(payCurve).curvePoint(x);
    }

    function claim(
          address payCurve
        , uint256 x
    ) 
        public 
        returns (
            uint256
        ) 
    {
        uint256 amount = earned(
              payCurve
            , x
        );
        
        return amount;
    }

    function pay() public {}
}