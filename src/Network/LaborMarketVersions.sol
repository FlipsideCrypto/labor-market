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

    /// @dev The token ID of the Governor Badge.
    uint256 public governorTokenId;

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
        , address _governorBadge
        , uint256 _governorTokenId
    ) {
        /// @dev Initialize the foundational version of the Labor Market primitive.
        _setVersion(
            _implementation,
            _msgSender(),
            keccak256(abi.encodePacked(address(0), uint256(0))),
            0,
            false
        );

        /// @dev Set the Governor Badge.
        governorBadge = IERC1155(_governorBadge);
        governorTokenId = _governorTokenId;
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
     * See {LaborMarketVersionsInterface.getVersionKey}
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
     * See {LaborMarketsVersionInterface.getLicenseKey}
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
     * @notice Gates permissions behind the Governor Badge.
     * @dev This is an internal function to allow gating Governor permissions
     *      within the entire network and factory contract stack.
     * @param _sender The address to verify against.
     */
    function _validateGovernor(address _sender)
        internal
        view
    {
        require(
            governorBadge.balanceOf(_sender, governorTokenId) > 0,
            "LaborMarketVersions::_validateGovernor: Not governor."
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
            owner: _owner,
            licenseKey: _licenseKey,
            amount: _amount,
            locked: _locked
        });

        /// @dev Announce that the version has been updated to index it on the front-end.
        emit VersionUpdated(_implementation, versions[_implementation]);
    }

    /**
     * @notice Creates a new Labor Market to be managed by the deploying address.
     * @param _implementation The address of the implementation to be used.
     * @param _licenseKey The license key of the individual processing the Labor Market creation.
     * @param _versionCost The cost of deploying the version.
     * @param _deployer The address that will be the deployer of the Labor Market contract.
     * @param _configuration The configuration of the Labor Market.
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
            _configuration.reputation.token,
            _configuration.reputation.tokenId
        );


        /// @dev Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _deployer, _implementation);

        return marketAddress;
    }

    /**
     * @notice Sets the governor badge of the network.
     * @param _governorBadge The address of the Governor Badge.
     * @param _governorTokenId The token ID of the Governor Badge.
     * @dev This is an internal function to allow setting the Governor Badge
     *      utilizing the LaborMarketNetwork interface.
     */
    function _setGovernorBadge(
          address _governorBadge
        , uint256 _governorTokenId
    ) 
        internal
    {
        governorBadge = IERC1155(_governorBadge);
        governorTokenId = _governorTokenId;
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
