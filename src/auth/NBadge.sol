// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

contract NBadge {
    /// @dev The schema of node in the authority graph.
    struct Node {
        IERC1155 badge;
        uint256 id;
        uint256 balance;
        uint256 points;
    }

    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The number of required badges to access a function.
    uint256 public required;

    /// @dev The nodes that make up the authority.
    Node[] public nodes;

    ////////////////////////////////////////////////////////
    ///                INTERNAL SETTERS                  ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Allows the authorized owner to update the required badges.
     * @param _required The new required badges.
     */
    function _setRequired(uint256 _required) internal {
        required = _required;
    }

    /**
     * @dev Allows the authorized owner to update the nodes.
     * @param _nodes The new nodes.
     */
    function _setNodes(Node[] memory _nodes) internal {
        nodes = _nodes;
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL GETTERS                 ///
    ////////////////////////////////////////////////////////


}
