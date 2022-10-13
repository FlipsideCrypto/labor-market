// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Core dependencies.
import { LaborMarketFactoryInterface } from "./interfaces/LaborMarketFactoryInterface.sol";
import { LaborMarketVersions } from "./LaborMarketVersions.sol";

contract LaborMarketFactory is
      LaborMarketFactoryInterface
    , LaborMarketVersions
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
        override
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

    /*//////////////////////////////////////////////////////////////
                            RECEIVABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Funds a new Labor Market when the license model is enabled and 
     *         the user has transfered their license to this contract. The license, is a 
     *         lifetime license.
     * @param _from The address of the account who owns the created Labor Market.
     * @return Selector response of the license token successful transfer.
     */
    function onERC1155Received(
          address 
        , address _from
        , uint256 _id
        , uint256 _amount
        , bytes memory _data
    ) 
        override 
        public 
        returns (
            bytes4
        ) 
    {
        /// @dev Return the typical ERC-1155 response if transfer is not intended to be a payment.
        if(bytes(_data).length == 0) {
            return this.onERC1155Received.selector;
        }
        
        /// @dev Recover the implementation address from `_data`.
        address implementation = abi.decode(
              _data
            , (address)
        );

        /// @dev Confirm that the token being transferred is the one expected.
        require(
              keccak256(
                  abi.encodePacked(
                        _msgSender()
                      , _id 
                  )
              ) == versions[implementation].licenseKey
            , "LaborMarketFactory::onERC1155Received: Invalid license key."
        );

        /// @dev Get the version license key to track the funding of the msg sender.
        bytes32 licenseKey = getLicenseKey(
              versions[implementation].licenseKey
            , _from
        );

        /// @dev Fund the deployment of the Labor Market contract to 
        ///      the account covering the cost of the payment (not the transaction sender).
        versionKeyToFunded[licenseKey] += _amount;

        /// @dev Return the ERC1155 success response.
        return this.onERC1155Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL PROTOCOL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows protocol Governors to execute protocol level transaction.
     * @dev This enables the ability to execute pre-built transfers without having to 
     *      explicitly define what tokens this contract can receive.
     * @param _to The address to execute the transaction on.
     * @param _data The data to pass to the receiver.
     * @param _value The amount of ETH to send with the transaction.
     */
    function execTransaction(
          address _to
        , bytes calldata _data
        , uint256 _value
    )
        external
        virtual
        payable
        onlyOwner
    {
        /// @dev Make the call.
        (
              bool success
            , bytes memory returnData
        ) = _to.call{value: _value}(_data);

        /// @dev Force that the transfer/transaction emits a successful response. 
        require(
              success
            , string(returnData)
        );
    }

    /**
     * @notice Signals to external callers that this is a Badger contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) 
        override
        public
        view
        returns (
            bool
        ) 
    {
        return (
               _interfaceId == type(LaborMarketFactoryInterface).interfaceId
            || super.supportsInterface(_interfaceId)
        );
    }
}
