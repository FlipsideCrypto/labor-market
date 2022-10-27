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
        require(repToken() != address(0), "ReputationModule: This Labor Market does not exist.");

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
        return ReputationModuleInterface(repToken()).freezeReputation(
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
        ReputationModuleInterface(repToken()).lockReputation(
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
        ReputationModuleInterface(repToken()).unlockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationToken-setDecayConfig}.
     */
    function setDecayConfig(
          uint256 _decayRate
        , uint256 _decayInterval
    ) 
        override
        public
    {
        ReputationModuleInterface(repToken()).setDecayConfig(
              _decayRate
            , _decayInterval
        );
    }

    /**
     * @dev See {ReputationToken-getAvailableReputation}.
     */
    function getAvailableReputation(address _account)
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationModuleInterface(repToken()).getAvailableReputation(_account);
    }

    function getPendingDecay(address _account)
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationModuleInterface(repToken()).getPendingDecay(_account);
    }

    /**
     * @dev See {ReputationToken-getReputationAccountInfo}.
     */
    function getReputationAccountInfo(address _account)
        override
        public
        view
        returns (
            ReputationTokenInterface.ReputationAccountInfo memory
        )
    {
        return ReputationModuleInterface(repToken()).getReputationAccountInfo(_account);
    }

    /**
     * @dev Returns the base provider threshold of the Reputation Token for the current Labor Market.
     */
    function signalStake()
        override
        public
        view
        returns (
            uint256
        )
    {
        return laborMarketRepConfig[msg.sender].providerThreshold;
    }

    /**
     * @dev Returns the base provider threshold of the Reputation Token for the current Labor Market.
     */
    function providerThreshold()
        override
        public
        view
        returns (
            uint256
        )
    {
        return laborMarketRepConfig[msg.sender].providerThreshold;
    }

    /**
     * @dev Returns the base maintainer threshold of the Reputation Token for the current Labor Market.
     */
    function maintainerThreshold()
        override
        public
        view
        returns (
            uint256
        )
    {
        return laborMarketRepConfig[msg.sender].maintainerThreshold;
    }

    /**
     * @dev Returns the address of the Reputation Token for the current Labor Market.
     */
    function repToken() 
        override
        public
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[msg.sender].reputationToken;
    }
}