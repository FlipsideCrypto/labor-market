// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketVersionsInterface } from './interfaces/LaborMarketVersionsInterface.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC1155Holder } from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

/// @dev Helpers.
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { LaborMarketInterface } from '../LaborMarket/interfaces/LaborMarketInterface.sol';

/// @dev Supported interfaces.
import { IERC1155Receiver } from '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract LaborMarketVersions is LaborMarketVersionsInterface, Ownable, ERC1155Holder {
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                            PROTOCOL STATE
    //////////////////////////////////////////////////////////////*/

    /// @dev The address interface of the Capacity Token.
    IERC20 public capacityToken;

    /// @dev The address interface of the Governor Badge.
    IERC1155 public governorBadge;

    /// @dev The address interface of the Creator Badge.
    IERC1155 public creatorBadge;

    /// @dev The token ID of the Governor Badge.
    uint256 public governorTokenId;

    /// @dev The token ID of the Creator Badge.
    uint256 public creatorTokenId;

    /// @dev All of the versions that are actively running.
    ///      This also enables the ability to self-fork ones product.
    mapping(address => Version) public versions;

    /// @dev Tracking the versions of deployment that one has funded the cost for.
    mapping(bytes32 => uint256) public versionKeyToFunded;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Announces when a Version configuration is updated through the protocol Factory.
    event VersionUpdated(address indexed implementation, Version indexed version);

    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(address indexed marketAddress, address indexed owner, address indexed implementation);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _implementation) {
        /// @dev Initialize the foundational version of the Labor Market primitive.
        _setVersion(_implementation, _msgSender(), keccak256(abi.encodePacked(address(0), uint256(0))), 0, false);
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyGovernor(address _sender) {
        require(isGovernor(_sender), 'LaborMarketVersions::isGovernor: Not a Governor.');
        _;
    }

    modifier onlyCreator(address _sender) {
        require(isCreator(_sender), 'LaborMarketVersions::isCreator: Not a Creator.');
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Build the version key for a version and a sender.
     * @dev If the license for a version is updated, then the previous fundings
     *      will be lost and no longer active unless the version is reverted back
     *      to the previous configuration.
     * @param _implementation The implementation address.
     * @return The version key.
     */
    function getVersionKey(address _implementation) public view virtual override returns (bytes32) {
        return versions[_implementation].licenseKey;
    }

    /**
     * @notice Builds the license key for a version and a sender.
     * @param _versionKey The version key.
     * @param _sender The message sender address.
     * returns The license key for the message sender.
     */
    function getLicenseKey(bytes32 _versionKey, address _sender) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(_versionKey, _sender));
    }

    /**
     * @notice Gates permissions behind the Creator Badge.
     * @dev This is an internal function to allow gating Creator permissions
     *     within the entire network and factory contract stack.
     * @param _sender The address to verify against.
     * @return Whether or not the sender is a Creator.
     */
    function isGovernor(address _sender) external view virtual returns (bool) {
        // TODO: NBADGE
        return true;
    }

    /**
     * @notice Checks if the sender is a Creator.
     * @param _sender The message sender address.
     * @return True if the sender is a Creator.
     */
    function isCreator(address _sender) external view virtual returns (bool) {
        // TODO: NBADGE
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/
    /**
     * See {LaborMarketFactory.createLaborMarket}
     */
    function _createLaborMarket(
        address _implementation,
        bytes32 _licenseKey,
        uint256 _versionCost,
        LaborMarketConfiguration calldata _configuration
    ) internal returns (address) {
        /// @dev Deduct the amount of payment that is needed to cover deployment of this version.
        /// @notice This will revert if an individual has not funded it with at least the needed amount
        ///         to cover the cost of the version.
        /// @dev If deploying a free version or using an exogenous contract, the cost will be
        ///      zero and proceed normally.
        versionKeyToFunded[_licenseKey] -= _versionCost;

        /// @dev Get the address of the target.
        address marketAddress = _implementation.clone();

        /// @dev Interface with the newly created contract to initialize it.
        LaborMarketInterface laborMarket = LaborMarketInterface(marketAddress);

        /// @dev Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(_configuration);

        /// @dev Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _configuration.owner, _implementation);

        return marketAddress;
    }

    /**
     * See {LaborMarketVersionsInterface.setVersion}
     */
    function _setVersion(
        address _implementation,
        address _owner,
        bytes32 _licenseKey,
        uint256 _amount,
        bool _locked
    ) internal {
        /// @dev Set the version configuration.
        versions[_implementation] = Version({
            owner: _owner,
            licenseKey: _licenseKey,
            amount: _amount,
            locked: _locked
        });

        /// @dev Announce that the version has been updated to index it on the front-end.
        emit VersionUpdated(_implementation, versions[_implementation]);
    }

    /**
     * @notice Signals to external callers that this is a BadgerVersions contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return (_interfaceId == type(LaborMarketVersionsInterface).interfaceId ||
            _interfaceId == type(IERC1155Receiver).interfaceId);
    }
}
