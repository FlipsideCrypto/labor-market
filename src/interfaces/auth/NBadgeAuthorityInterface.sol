// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface NBadgeAuthorityInterface {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}
