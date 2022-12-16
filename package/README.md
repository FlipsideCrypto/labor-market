## Installation
``npm i labor-markets-abi``

## Updates
As we get further into integration, changes, and implementation notes will be added to this readme.

## Usage

Emphasis on there being pending changes, but we will do our best to communicate them as they happen and deployments are updated.
To use the ABIs:

``npm i labor-markets-abi / yarn add labor-markets-abi``

Then imports are
```
import {
    PaymentToken
    AnyReputationToken
    LaborMarket
    ReputationEngine
    LaborMarketFactory
    LaborMarketNetwork
    ReputationModule
    LikertEnforcement
    PaymentModule
    PayCurve
} from "labor-markets-abi
```

```
Each will return an obj with
{
   address: string,
   abi: SolidityJSONABI
}
```

Types can be found in "labor-markets-abi/types/*". If these are needed we can clean up the paths a bit.