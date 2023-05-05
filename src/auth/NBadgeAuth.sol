// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { NBadgeAuthInterface } from '../interfaces/auth/NBadgeAuthInterface.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { NBadgeAuthority } from './NBadgeAuthority.sol';

abstract contract NBadgeAuth is NBadgeAuthInterface, Initializable {
    /// @dev The address of the Labor Market deployer.
    address public deployer;

    /// @dev The N-Badge module used for access management.
    NBadgeAuthority public nBadgeAuthority;

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
     * @param _nBadgeAuthority The address of the N-Badge module.
     */
    function __NBadgeAuth_init(
        address _deployer,
        NBadgeAuthority _nBadgeAuthority,
        bytes4[] calldata _sigs,
        Node[] calldata _nodes
    ) internal initializer {
        /// @notice Set the local deployer of the Labor Market.
        deployer = _deployer;

        /// @notice Set the N-Badge module.
        nBadgeAuthority = _nBadgeAuthority;

        /// @notice Announce the change in access configuration.
        emit OwnershipTransferred(address(0), _deployer);
        emit AuthorityUpdated(address(0), _nBadgeAuthority);

        /// @dev Initialize the contract.
        __NBadgeAuth_init_unchained(_sigs, _nodes);
    }

    /**
     * @notice Initialize the contract with the deployer and the N-Badge module.
     * @param _nodes The list of nodes that are allowed to call this contract.
     */
    function __NBadgeAuth_init_unchained(bytes4[] calldata _sigs, Node[] calldata _nodes) internal initializer {
        /// @notice Ensure that the arrays provided are of equal lengths.
        require(_sigs.length == _nodes.length, 'NBadgeAuth::__NBadgeAuth_init_unchained: Invalid input');

        /// @dev Load the loop stack.
        uint256 i;

        /// @notice Loop through all of the signatures provided and load in the access management.
        for (i; i < _sigs.length; i++) {
            /// @dev Initialize all the nodes related to each signature.
            sigToNode[_sigs[i]] = _nodes[i];
        }
    }

    /**
     * @dev Determines if a user has the required credentials to call a function.
     * @param _user The user to check.
     * @param _sig The signature of the function to check.
     * @return True if the user has the required credentials, false otherwise.
     */
    function _canCall(
        address _user,
        address,
        bytes4 _sig
    ) internal view returns (bool) {
        /// @dev Load in the established for this function.
        Node memory node = sigToNode[_sig];

        /// @dev Load in the first badge to warm the slot.
        Badge memory badge = node.badges[0];

        /// @dev Load in the stack.
        uint256 points;
        uint256 i;

        /// @dev Determine if the user has met the proper conditions of access.
        for (i; i < node.badges.length; i++) {
            /// @dev Step through the nodes until we have enough points or we run out.
            badge = node.badges[i];

            /// @notice Determine the balance of the Badge the user.
            uint256 balance = badge.badge.balanceOf(_user, badge.id);

            /// @dev If the user has sufficient balance, account for the balance in points.
            if (badge.min <= balance && badge.max >= balance) points += badge.points;

            /// @dev If enough points have been accumulated, return true.
            if (points >= node.required) i = node.badges.length;

            /// @dev Keep on swimming.
        }

        /// @dev Final check if no mandatory badges had an insufficient balance.
        return points >= node.required;
    }

    function isAuthorized(address user, bytes4 functionSig) public view virtual returns (bool) {
        /// @dev Memoize the authority to warm the slot.
        NBadgeAuthority auth = nBadgeAuthority;

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && _canCall(user, address(this), functionSig)) || user == deployer;
    }
}
