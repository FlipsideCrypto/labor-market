// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Core dependencies.
import { LaborMarketVersions } from "./LaborMarketVersions.sol";

contract LaborMarketFactory is
    LaborMarketVersions
{
    constructor(address _implementation)
        LaborMarketVersions(_implementation)
    {}

    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
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
    function createLaborMarket( 
          address _implementation
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
        public
        virtual
        returns (
            address laborMarketAddress
        )
    { 
        /// @dev Load the version.
        Version memory version = versions[_implementation];

        /// @dev Get the users license key to determine how much funding has been provided.
        /// @notice Can deploy for someone but must have the cost covered themselves.
        bytes32 licenseKey = getLicenseKey(
              version.licenseKey
            , _msgSender()
        );

        /// @dev Deploy the Labor Market contract for the deployer chosen.
        laborMarketAddress = _createLaborMarket(
              _implementation
            , licenseKey
            , version.amount
            , _deployer
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
    }

    // onERC1155Received
    // process the license receiving
}
