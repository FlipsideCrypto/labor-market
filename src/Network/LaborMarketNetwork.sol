// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";
import { LaborMarketFactory } from "./LaborMarketFactory.sol";

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketNetwork is 
      LaborMarketNetworkInterface
    , LaborMarketFactory
{
    IERC20 public capacityToken;

    uint256 public reputationTokenId;
    uint256 public reputationDecayRate;
    uint256 public reputationDecayInterval;

    uint256 public baseSignalStake;
    uint256 public baseProviderThreshold;
    uint256 public baseMaintainerThreshold;

    mapping(address => mapping(uint256 => ReputationToken)) public reputationTokens;

    constructor(
          address _factoryImplementation
        , address _capacityImplementation
        , address _baseReputationImplementation
        , uint256 _baseReputationTokenId
        , ReputationTokenConfig memory _baseReputationConfig
    ) 
        LaborMarketFactory(_factoryImplementation) 
    {
        capacityToken = IERC20(_capacityImplementation);

        ReputationToken storage baseReputation = reputationTokens[_baseReputationImplementation][_baseReputationTokenId];
        baseReputation.config = _baseReputationConfig;
    }

    /**
     * @notice Limit reputation existing token management to the designated manager or network owner.
     * @param _implementation The address of the reputation token.
     * @param _tokenId The id of the reputation token.
     */
    modifier onlyReputationManagers (
          address _implementation
        , uint256 _tokenId
    ) {
        require(
              reputationTokens[_implementation][_tokenId].config.manager == _msgSender() ||
              reputationTokens[_implementation][_tokenId].config.manager == address(0) || 
              _msgSender() == owner()
            , "LaborMarketNetwork: Only the reputation manager can call this function."
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Configure the reputation token configuration for a given implementation.
     * @param _implementation The address of the reputation token.
     * @param _tokenId The id of the reputation token.
     * @param _config The struct containing the configuration of the reputation token.
     * @dev Setting the manager to address(0) will allow anyone to manage the reputation token.
     * Requirements:
     * - Only the network owner or reputation token manager can call this function on existing configs.
     */
    function setReputationConfig (
              address _implementation
            , uint256 _tokenId
            , ReputationTokenConfig calldata _config
        ) 
            external 
            onlyReputationManagers(
                  _implementation
                , _tokenId
            )
    {
        ReputationToken storage reputationToken = reputationTokens[_implementation][_tokenId];

        reputationToken.config = _config;
    }

    /**
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the reputation token.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setCapacityImplementation(
        address _implementation
    )
        override
        external
        virtual
        onlyOwner
    {
        capacityToken = IERC20(_implementation);
    }

    // TODO: Does delete also remove the nested mapping in the struct?
    //       My thinking is if we allow people to create reputation configs at will,
    //       We need to reserve the ability to delete them in the case of a popular token config
    //       being set up by a bad actor and balance info being manipulated by them.
    //       I'm not 100% sure if they could cause any harm with just the rep manager role though.
    // function newReputationConfig (
    //           address _implementation
    //         , uint256 _tokenId
    //         , ReputationTokenConfig calldata _config
    //     ) 
    //         external 
    //         onlyReputationManagers(_implementation, _tokenId)
    // {
    //     delete reputationTokens[_implementation][_tokenId];

    //     ReputationToken storage reputationToken = reputationTokens[_implementation][_tokenId];
    //     reputationToken.config = _config;
    // }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the available reputation token balance after accounting for the
     *         amounts locked and pending decay.
     * @param _account The address to query the balance of.
     * Requirements:
     * - If a user's balance is frozen, no reputation is available.
     */
    function getAvailableReputation(
          address _account
        , address _reputationImplementation
        , uint256 _reputationTokenId
    )
        override
        public
        view
        virtual
        returns (
            uint256
        )
    {
        BalanceInfo memory info = (
            reputationTokens[_reputationImplementation][_reputationTokenId].balanceInfo[_account]
        );

        if (info.frozenUntilEpoch > block.timestamp) return 0;

        uint256 decayed = getPendingDecay(
            info.lastDecayEpoch,
            info.frozenUntilEpoch
        );

        return (
            IERC1155(_reputationImplementation).balanceOf(_account, reputationTokenId) -
            info.locked -
            decayed
        );
    }

    /**
     * @notice Freeze a user's reputation for a given number of epochs.
     * @param _frozenUntilEpoch The epoch that reputation will no longer be frozen.
     * @dev Calculates decay and applies it before freezing.
     *
     * Requirements:
     * - `_frozenUntilEpoch` must be greater than the current epoch.
     */
    function freezeReputation(
          address _reputationImplementation
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    ) 
        override
        external
        virtual 
    {
        require(
            block.timestamp > _frozenUntilEpoch,
            "Network: Cannot freeze reputation in the past"
        );
        BalanceInfo storage info = (
            reputationTokens[_reputationImplementation][_reputationTokenId].balanceInfo[_msgSender()]
        );

        uint256 decayed = getPendingDecay(
            info.lastDecayEpoch,
            info.frozenUntilEpoch
        );

        info.locked += decayed;
        info.frozenUntilEpoch = _frozenUntilEpoch;
        info.lastDecayEpoch = block.timestamp;
    }

    /**
     * @notice Get the amount of reputation that has decayed since the last decay epoch.
     * @param _lastDecayEpoch The epoch that reputation was last decayed.
     * @param _frozenUntilEpoch The epoch that reputation will no longer be frozen.
     * @dev This function assumes that anywhere decay is written to storage, the
     *      user's frozenUntilEpoch is set to 0.
     */
    function getPendingDecay(
          uint256 _lastDecayEpoch
        , uint256 _frozenUntilEpoch
    ) 
        override
        public 
        view 
        returns (
            uint256
        ) 
    {
        if (_frozenUntilEpoch > block.timestamp) {
            return 0;
        }

        return (((block.timestamp - _lastDecayEpoch - _frozenUntilEpoch) /
            reputationDecayInterval) * reputationDecayRate);
    }

    // Todo: Access controls
    function lockReputation(
          address _account
        , address _reputationImplementation
        , uint256 _reputationTokenId
        , uint256 _amount
    ) 
        override
        external
        virtual
    {
        BalanceInfo storage info = (
            reputationTokens[_reputationImplementation][_reputationTokenId].balanceInfo[_account]
        );

        info.locked += _amount;
    }
}
