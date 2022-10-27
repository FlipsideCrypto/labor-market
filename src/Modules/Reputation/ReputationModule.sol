// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationTokenInterface } from "./interfaces/ReputationTokenInterface.sol";
import { ReputationModuleInterface } from "./interfaces/ReputationModuleInterface.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract ReputationModule is ReputationModuleInterface {
    using Clones for address;

    address public network;

    mapping(address => ReputationMarketConfig) public laborMarketRepConfig;

    constructor(
        address _network
    ) {
        network = _network;
    }

    /**
     * @notice Create a new Reputation Token.
     * @param _implementation The address of ReputationToken implementation.
     * @param _baseToken The address of the base ERC1155.
     * @param _baseTokenId The tokenId of the base ERC1155.
     * @param _decayRate The amount of reputation decay per epoch.
     * @param _decayInterval The block length of an epoch.
     * Requirements:
     * - Only the network can call this function in the factory.
     */
    function createReputationToken(
          address _implementation
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        override
        external
        returns (
            address
        )
    {
        address reputationTokenAddress = _implementation.clone();

        ReputationTokenInterface reputationToken = ReputationTokenInterface(
            reputationTokenAddress
        );

        reputationToken.initialize(
              address(this)
            , _baseToken
            , _baseTokenId
            , _decayRate
            , _decayInterval
        );

        emit ReputationTokenCreated(
              reputationTokenAddress
            , _baseToken
            , _baseTokenId
            , msg.sender
            , _decayRate
            , _decayInterval
        );

        return reputationTokenAddress;
    }

    /**
     * @notice Initialize a new Labor Market as using Reputation.
     * @param _laborMarket The address of the new Labor Market.
     * @param _repConfig The Labor Market level config of Reputation.
     * Requirements:
     * - Only the network can call this function in the factory.
     */
    function useReputationModule(
          address _laborMarket
        , ReputationMarketConfig calldata _repConfig
    )
        override
        public
    {
        require(msg.sender == network, "ReputationModule: Only network can call this.");

        laborMarketRepConfig[_laborMarket] = _repConfig;

        emit MarketReputationConfigured(_laborMarket, _repConfig);
    }

    /**
     * @notice Change the parameters of the Labor Market Reputation config.
     * @param _repConfig The Labor Market level config of Reputation.
     * @dev This function is only callable by Labor Markets that have already been
     *      initialized with the Reputation module by the Network.
     * Requirements:
     * - The Labor Market must already have a configuration.
     */
    function setMarketRepConfig(
        ReputationMarketConfig calldata _repConfig
    )
        override
        public 
    {
        require(_callerReputationToken() != address(0), "ReputationModule: This Labor Market does not exist.");

        laborMarketRepConfig[msg.sender] = _repConfig;

        emit MarketReputationConfigured(msg.sender, _repConfig);
    }

    /**
     * @dev See {ReputationToken-freezeReputation}.
     */
    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    ) 
        override
        public
    {
        _freezeReputation(_callerReputationToken(), _account, _frozenUntilEpoch);
    }

    function _freezeReputation(
          address _reputationToken
        , address _account
        , uint256 _frozenUntilEpoch
    )
        internal
    {
        ReputationTokenInterface(_reputationToken).freezeReputation(
              _account
            , _frozenUntilEpoch
        );
    }

    /**
     * @dev See {ReputationToken-lockReputation}.
     */
    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        public
    {
        _lockReputation(_callerReputationToken(), _account, _amount);
    }

    function _lockReputation(
          address _reputationToken
        , address _account
        , uint256 _amount
    ) 
        internal
    {
        ReputationTokenInterface(_reputationToken).lockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationToken-unlockReputation}.
     */
    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        public
    {
        _unlockReputation(_callerReputationToken(), _account, _amount);
    }
    
    function _unlockReputation(
          address _reputationToken
        , address _account
        , uint256 _amount
    ) 
        internal
    {
        ReputationTokenInterface(_reputationToken).unlockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationToken-getAvailableReputation}.
     */
    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationTokenInterface(
            getReputationToken(_laborMarket)
        ).getAvailableReputation(_account);
    }

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationTokenInterface(
            getReputationToken(_laborMarket)
        ).getPendingDecay(_account);
    }

    /**
     * @dev See {ReputationToken-getReputationAccountInfo}.
     */
    function getReputationAccountInfo(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            ReputationTokenInterface.ReputationAccountInfo memory
        )
    {
        return ReputationTokenInterface(
            getReputationToken(_laborMarket)
        ).getReputationAccountInfo(_account);
    }

    /**
     * @dev Returns the base provider threshold of the Reputation Token for the Labor Market.
     */
    function getSignalStake(address _laborMarket)
        override
        public
        view
        returns (
            uint256
        )
    {
        return laborMarketRepConfig[_laborMarket].signalStake;
    }

    /**
     * @dev Returns the base provider threshold of the Reputation Token for the Labor Market.
     */
    function getProviderThreshold(address _laborMarket)
        override
        public
        view
        returns (
            uint256
        )
    {
        return laborMarketRepConfig[_laborMarket].providerThreshold;
    }

    /**
     * @dev Returns the base maintainer threshold of the Reputation Token for the Labor Market.
     */
    function getMaintainerThreshold(address _laborMarket)
        override
        public
        view
        returns (
            uint256
        )
    {
        return laborMarketRepConfig[_laborMarket].maintainerThreshold;
    }

    /**
     * @dev Returns the address of the Reputation Token for the Labor Market.
     */
    function getReputationToken(address _laborMarket)
        override
        public
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[_laborMarket].reputationToken;
    }

    function _callerReputationToken()
        internal
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[msg.sender].reputationToken;
    }
}