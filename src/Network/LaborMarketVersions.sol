// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketVersionsInterface } from "./interfaces/LaborMarketVersionsInterface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @dev Helpers.
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { LaborMarketInterface } from "../LaborMarket/interfaces/LaborMarketInterface.sol";
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";

/// @dev Supported interfaces.
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketVersions is
    LaborMarketVersionsInterface,
    Ownable,
    ERC1155Holder
{
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                            PROTOCOL STATE
    //////////////////////////////////////////////////////////////*/
    
    /// @dev The address interface of the Capacity Token.
    IERC20 public capacityToken;

    /// @dev The address interface of the Governor Badge.
    IERC1155 public governorBadge;

    /// @dev The address interface of the Creator Badge.
    IERC1155 creatorBadge;

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
    event VersionUpdated(
          address indexed implementation
        , Version indexed version
    );

    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(
          address indexed marketAddress
        , address indexed owner
        , address indexed implementation
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
          address _implementation
        , BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    ) {
        /// @dev Initialize the foundational version of the Labor Market primitive.
        _setVersion(
            _implementation,
            _msgSender(),
            keccak256(abi.encodePacked(address(0), uint256(0))),
            0,
            false
        );

        /// @dev Set the network roles.
        _setNetworkRoles(
            _governorBadge, 
            _creatorBadge
        );
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows configuration to specific versions.
     * @dev This enables the ability to have Enterprise versions as well as public versions. None of this
     *      state is immutable as a license model may change in the future and updates here do not impact
     *      Labor Markets that are already running.
     * @param _implementation The implementation address.
     * @param _owner The owner of the version.
     * @param _tokenAddress The token address.
     * @param _tokenId The token ID.
     * @param _amount The amount that this user will have to pay.
     * @param _locked Whether or not this version has been made immutable.
     * Requirements:
     * - The caller must be the owner.
     * - If the caller is not the owner, cannot set a Payment Token as they cannot withdraw.
     */
    function setVersion(
          address _implementation
        , address _owner
        , address _tokenAddress
        , uint256 _tokenId
        , uint256 _amount
        , bool _locked
    ) 
        public 
        virtual 
        override 
    {
        /// @dev Load the existing Version object.
        Version memory version = versions[_implementation];

        /// @dev Prevent editing of a version once it has been locked.
        require(
            !version.locked,
            "LaborMarketVersions::_setVersion: Cannot update a locked version."
        );

        /// @dev Only the owner can set the version.
        require(
            version.owner == address(0) || version.owner == _msgSender(),
            "LaborMarketVersions::_setVersion: You do not have permission to edit this version."
        );

        /// @dev Make sure that no exogenous version controllers can set a payment
        ///      as there is not a mechanism for them to withdraw.
        if (_msgSender() != owner()) {
            require(
                _tokenAddress == address(0) && _tokenId == 0 && _amount == 0,
                "LaborMarketVersions::_setVersion: You do not have permission to set a payment token."
            );
        }

        /// @dev Set the version configuration.
        _setVersion(
            _implementation,
            _owner,
            keccak256(abi.encodePacked(_tokenAddress, _tokenId)),
            _amount,
            _locked
        );
    }

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
    function getVersionKey(address _implementation)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return versions[_implementation].licenseKey;
    }

    /**
     * @notice Builds the license key for a version and a sender.
     * @param _versionKey The version key.
     * @param _sender The message sender address.
     * returns The license key for the message sender.
     */
    function getLicenseKey(
          bytes32 _versionKey
        , address _sender
    )
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_versionKey, _sender));
    }

    /**
     * @notice Gates permissions behind the Creator Badge.
     * @dev This is an internal function to allow gating Creator permissions
     *     within the entire network and factory contract stack.
     * @param _sender The address to verify against.
     * @return Whether or not the sender is a Creator.
     */
    function _isCreator(address _sender)
        internal
        view
        returns (bool)
    {
        return creatorBadge.balanceOf(_sender, creatorTokenId) > 0;
    }

    /**
     * @notice Gates permissions behind the Governor Badge.
     * @dev This is an internal function to allow gating Governor permissions
     *     within the entire network and factory contract stack.
     * @param _sender The address to verify against.
     * @return Whether or not the sender is a Governor.
     */
    function _isGovernor(address _sender) 
        internal
        view
        returns (bool)
    {
        return governorBadge.balanceOf(_sender, governorTokenId) > 0;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/
    /**
     * See {LaborMarketFactory.createLaborMarket}
     */
    function _createLaborMarket(
          address _implementation
        , bytes32 _licenseKey
        , uint256 _versionCost
        , address _deployer
        , LaborMarketConfiguration calldata _configuration
    )
        internal 
        returns (
            address
        ) 
    {
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

        /// @dev Register the Labor Market with the Reputation Module.
        ReputationModuleInterface(_configuration.modules.reputation).useReputationModule(
            marketAddress,
            _configuration.reputationBadge.token,
            _configuration.reputationBadge.tokenId
        );

        /// @dev Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _deployer, _implementation);

        return marketAddress;
    }

    /**
     * See {LaborMarketVersionsInterface.setVersion}
     */
    function _setVersion(
          address _implementation
        , address _owner
        , bytes32 _licenseKey
        , uint256 _amount
        , bool _locked
    ) 
        internal 
    {
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
     * See {LaborMarketsNetwork.setNetworkRoles}
     */
    function _setNetworkRoles(
          BadgePair memory _governorBadge
        , BadgePair memory _creatorBadge
    )
        internal
    {
        /// @dev Set the Governor Badge.
        governorBadge = IERC1155(_governorBadge.token);
        governorTokenId = _governorBadge.tokenId;

        /// @dev Set the Creator Badge.
        creatorBadge = IERC1155(_creatorBadge.token);
        creatorTokenId = _creatorBadge.tokenId;
    }

    /**
     * See {LaborMarketsNetwork.setReputationDecay}
     */
    function _setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        internal
    {
        ReputationModuleInterface(_reputationModule).setDecayConfig(
            _reputationToken,
            _reputationTokenId,
            _decayRate,
            _decayInterval,
            _decayStartEpoch
        );
    }

    /**
     * @notice Signals to external callers that this is a BadgerVersions contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return (_interfaceId ==
            type(LaborMarketVersionsInterface).interfaceId ||
            _interfaceId == type(IERC1155Receiver).interfaceId);
    }
}
