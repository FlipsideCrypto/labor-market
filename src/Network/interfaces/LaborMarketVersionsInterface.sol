// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketConfigurationInterface} from "../../LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketVersionsInterface is LaborMarketConfigurationInterface {
    /*//////////////////////////////////////////////////////////////
                                SCHEMAS
    //////////////////////////////////////////////////////////////*/

    /// @dev The schema of a version.
    struct Version {
        address owner;
        bytes32 licenseKey;
        uint256 amount;
        bool locked;
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function setVersion(
        address _implementation,
        address _owner,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _locked
    ) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getVersionKey(address _implementation)
        external
        view
        returns (bytes32);

    function getLicenseKey(
          bytes32 _versionKey
        , address _sender
    )
        external
        pure
        returns (bytes32);
}
