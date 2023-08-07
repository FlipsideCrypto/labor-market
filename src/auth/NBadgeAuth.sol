// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { NBadgeAuthInterface } from '../interfaces/auth/NBadgeAuthInterface.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract NBadgeAuth is NBadgeAuthInterface, Initializable {
    /// @dev The address of the Labor Market deployer.
    address public deployer;

    /// @dev The list of nodes that are allowed to call this contract.
    mapping(bytes4 => Node) internal sigToNode;

    /// @notice Ensure that the caller has permission to use this function.
    modifier requiresAuth() virtual {
        /// @dev Confirm the user has permission to run this function.
        require(isAuthorized(msg.sender, msg.sig), 'NBadgeAuth::requiresAuth: Not authorized');

        _;
    }

    /**
     * @notice Initialize the contract with the deployer and the N-Badge module.
     * @param _deployer The address of the deployer.
     * @param _sigs The list of function signatures N-Badge is applied to.
     * @param _nodes The list of nodes that are allowed to call this contract.
     */
    function __NBadgeAuth_init(
        address _deployer,
        bytes4[] calldata _sigs,
        Node[] calldata _nodes
    ) internal onlyInitializing {
        /// @notice Set the local deployer of the Labor Market.
        deployer = _deployer;

        /// @notice Announce the change in access configuration.
        emit OwnershipTransferred(address(0), _deployer);

        /// @dev Initialize the contract.
        __NBadgeAuth_init_unchained(_sigs, _nodes);
    }

    /**
     * @notice Initialize the contract with the deployer and the N-Badge module.
     * @param _nodes The list of nodes that are allowed to call this contract.
     */
    function __NBadgeAuth_init_unchained(bytes4[] calldata _sigs, Node[] calldata _nodes) internal onlyInitializing {
        /// @notice Ensure that the arrays provided are of equal lengths.
        require(_sigs.length == _nodes.length, 'NBadgeAuth::__NBadgeAuth_init_unchained: Invalid input');

        /// @dev Load the loop stack.
        uint256 i;

        /// @notice Loop through all of the signatures provided and load in the access management.
        for (i; i < _sigs.length; i++) {
            /// @dev Initialize all the nodes related to each signature.
            sigToNode[_sigs[i]] = _nodes[i];
        }

        /// @dev Announce the change in access configuration.
        emit NodesUpdated(_sigs, _nodes);
    }

    /**
     * @dev Determines if a user has the required credentials to call a function.
     * @param _node The node to check.
     * @param _user The user to check.
     * @return True if the user has the required credentials, false otherwise.
     */
    function _canCall(
        Node memory _node,
        address _user,
        address
    ) internal view returns (bool) {
        /// @dev Load in the first badge to warm the slot.
        Badge memory badge = _node.badges[0];

        /// @dev Load in the stack.
        uint256 points;
        uint256 i;

        /// @dev Determine if the user has met the proper conditions of access.
        for (i; i < _node.badges.length; i++) {
            /// @dev Step through the nodes until we have enough points or we run out.
            badge = _node.badges[i];

            /// @notice Determine the balance of the Badge the user.
            uint256 balance = badge.badge.balanceOf(_user, badge.id);

            /// @notice If the user has sufficient balance, account for the balance in points.
            if (badge.min <= balance && badge.max >= balance) points += badge.points;

            /// @notice If enough points have been accumulated, terminate the loop.
            if (points >= _node.required) i = _node.badges.length;

            /// @notice Keep on swimming.
        }

        /// @notice Return if the user has met the required points.
        return points >= _node.required;
    }

    /**
     * See {NBadgeAuthInterface-isAuthorized}.
     */
    function isAuthorized(address user, bytes4 _sig) public view virtual returns (bool) {
        /// @notice Load in the established for this function.
        Node memory node = sigToNode[_sig];

        /// @notice If no configuration was set, the access of the function is open to the public.
        bool global = node.badges.length == 0;

        /// @notice Determine and return if a user has permission to call the function.
        return (global || _canCall(node, user, address(this))) || (user == deployer && node.deployerAllowed);
    }
}
