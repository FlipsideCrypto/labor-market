// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helper interfaces.
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { NBadgeAuthority } from '../../auth/NBadgeAuthority.sol';

interface NBadgeAuthInterface {
    /// @dev The schema of node in the authority graph.
    struct Badge {
        IERC1155 badge;
        uint256 id;
        uint256 min;
        uint256 max;
        uint256 points;
    }

    struct Node {
        uint256 required;
        Badge[] badges;
    }

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, NBadgeAuthority indexed newAuthority);
}
