// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { NBadgeAuthorityInterface } from '../interfaces/auth/NBadgeAuthorityInterface.sol';

contract NBadgeAuthority is NBadgeAuthorityInterface {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view override returns (bool) {
        return true;
    }
}
