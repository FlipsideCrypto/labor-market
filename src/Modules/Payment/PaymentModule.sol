// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPayCurve} from "./Interfaces/IPayCurve.sol";

contract PaymentModule {
    function earned(address payCurve, uint256 x) public returns (uint256) {
        return IPayCurve(payCurve).curvePoint(x);
    }

    function claim(address payCurve, uint256 x) public returns (uint256) {
        uint256 amount = earned(payCurve, x);
        return amount;
    }

    function pay() public {}

    modifier onlyMarket() {
        _;
    }
}
