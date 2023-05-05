// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helper interfaces.
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface NBadgeAuthInterface {
    /// @dev The schema of node in the authority graph.
    struct Badge {
        IERC1155 badge;
        uint256 id;
        uint256 min;
        uint256 max;
        uint256 points;
    }

    /// @notice Access definition for a signature.
    struct Node {
        bool deployerAllowed;
        uint256 required;
        Badge[] badges;
    }

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /**
     * @notice Determine if a user has the required credentials to call a function.
     * @param user The user to check.
     * @param sig The signature of the function to check.
     * @return authorized as `true` if the user has the required credentials, `false` otherwise.
     */
    function isAuthorized(address user, bytes4 sig) external view returns (bool authorized);
}
