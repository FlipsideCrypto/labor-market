// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketVersionsInterface } from "./interfaces/LaborMarketVersionsInterface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// TODO: Implement use of.
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @dev Helpers.
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";

/// @dev Supported interfaces.
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract LaborMarketVersions is
      LaborMarketVersionsInterface 
    , Ownable
    , ERC1155Holder 
{    
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                           PROTOCOL STATE
    //////////////////////////////////////////////////////////////*/

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
        address indexed organization,
        address indexed owner,
        address indexed implementation
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _implementation
    ) {
        /// @dev Initialize the foundational version of the Labor Market primitive.
        _setVersion(
              _implementation
            , _msgSender()
            , keccak256(
                  abi.encodePacked(
                      address(0)
                      , uint256(0)
                  )
              )
            , 0
            , false
        );
    }
    
    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * See {LaborMarketVersions._setVersion}
     * 
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
        override
        public
        virtual
    {
        /// @dev Load the existing Version object.
        Version memory version = versions[_implementation];

        /// @dev Prevent editing of a version once it has been locked.
        require(
              !version.locked
            , "LaborMarketVersions::_setVersion: Cannot update a locked version."
        );

        /// @dev Only the owner can set the version.
        require(
                 version.owner == address(0)
              || version.owner == _msgSender()
            , "LaborMarketVersions::_setVersion: You do not have permission to edit this version."
        );

        /// @dev Make sure that no exogenous version controllers can set a payment
        ///      as there is not a mechanism for them to withdraw.
        if(_msgSender() != owner()) {
            require(
                     _tokenAddress == address(0)
                  && _tokenId == 0
                  && _amount == 0
                , "LaborMarketVersions::_setVersion: You do not have permission to set a payment token."
            );
        }

        /// @dev Set the version configuration.
        _setVersion(
              _implementation
            , _owner
            , keccak256(
                  abi.encodePacked(
                        _tokenAddress
                      , _tokenId
                  )
              )
            , _amount
            , _locked
        );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * See {LaborMarketVersionsInterface.getVersionKey}
     */    
    function getVersionKey(
        address _implementation 
    ) 
        override
        public 
        view 
        virtual
        returns (
            bytes32
        ) 
    {
        return versions[_implementation].licenseKey;
    }

    /**
     * See {LaborMarketsVersionInterface.getLicenseKey}
     */
    function getLicenseKey(
          bytes32 _versionKey
        , address _sender
    )
        override
        public
        pure
        returns (
            bytes32
        )
    {
        return keccak256(
            abi.encodePacked(
                  _versionKey
                , _sender
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/

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
              owner: _owner
            , licenseKey: _licenseKey
            , amount: _amount
            , locked: _locked
        });

        /// @dev Announce that the version has been updated to index it on the front-end.
        emit VersionUpdated(
              _implementation
            , versions[_implementation]
        );
    }

    /**
     * @notice Creates a new Labor Market to be managed by the deploying address.
     * @param _implementation The address of the implementation to be used.
     * @param _licenseKey The license key of the individual processing the Labor Market creation.
     * @param _versionCost The cost of deploying the version.
     * @param _deployer The address that will be the deployer of the Labor Market contract.
     * @param _enforcementModule The address of the Enforcement Module contract.
     * @param _paymentModule The address of the Payment Module contract.
     * @param _delegateBadge The address of the Delegation badge.
     * @param _delegateTokenId The ID of the token to be used for delegation.
     * @param _participationBadge The address of the Participation Badge contract.
     * @param _participationTokenId The ID of the token to be used for participation.
     * @param _repParticipantMultiplier The multiplier applied to the reputation of a participant.
     * @param _repMaintainerMultiplier The multiplier applied to the active protocol recommendation.
     * @param _marketUri The URI of the Labor Market.
     */
    function _createLaborMarket(
          address _implementation
        , bytes32 _licenseKey
        , uint256 _versionCost
        , address _deployer
        , address _enforcementModule
        , address _paymentModule
        , address _delegateBadge
        , uint256 _delegateTokenId
        , address _participationBadge
        , uint256 _participationTokenId
        , uint256 _repParticipantMultiplier
        , uint256 _repMaintainerMultiplier
        , string memory _marketUri
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
        versionKeyToFunded[_licenseKey] -=  _versionCost;

        /// @dev Get the address of the target.
        address marketAddress = _implementation.clone();

        /// @dev Interface with the newly created contract to initialize it. 
        LaborMarketInterface laborMarket = LaborMarketInterface(
            marketAddress
        );

        /// @dev Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(
              address(this)
            , _enforcementModule
            , _paymentModule
            , _delegateBadge
            , _delegateTokenId
            , _participationBadge
            , _participationTokenId
            , _repParticipantMultiplier
            , _repMaintainerMultiplier
            , _marketUri
        );
        
        /// @dev Announce the creation of the Labor Market.
        emit LaborMarketCreated(
              marketAddress
            , _deployer
            , _implementation
        );

        return marketAddress;
    }

    /**
     * @notice Signals to external callers that this is a BadgerVersions contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) 
        override
        public 
        view 
        virtual
        returns (
            bool
        ) 
    {
        return (
               _interfaceId == type(LaborMarketVersionsInterface).interfaceId
            || _interfaceId == type(IERC1155Receiver).interfaceId
        );
    }
}