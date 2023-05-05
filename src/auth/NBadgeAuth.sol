// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { NBadgeAuthInterface } from '../interfaces/auth/NBadgeAuthInterface.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { NBadgeAuthority } from './NBadgeAuthority.sol';

abstract contract NBadgeAuth is NBadgeAuthInterface, Initializable {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, NBadgeAuthority indexed newAuthority);

    /// @dev The address of the Labor Market deployer.
    address public deployer;

    /// @dev The N-Badge module used for access management.
    NBadgeAuthority public nBadgeAuthority;

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), 'NBadgeAuth::requiresAuth: Not authorized');

        _;
    }

    /// @dev Set the deployer.
    function __NBadgeAuth_init(address _deployer, NBadgeAuthority _nBadgeAuthority) internal initializer {
        __NBadgeAuth_init_unchained(_deployer, _nBadgeAuthority);
    }

    function __NBadgeAuth_init_unchained(address _deployer, NBadgeAuthority _nBadgeAuthority) internal initializer {
        deployer = _deployer;

        nBadgeAuthority = _nBadgeAuthority;

        emit OwnershipTransferred(address(0), _deployer);
        emit AuthorityUpdated(address(0), _nBadgeAuthority);
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        /// @dev Memoize the authority to warm the slot.
        NBadgeAuthority auth = nBadgeAuthority;

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == deployer;
    }
}
