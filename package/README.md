

## Usage

Emphasis on there being pending changes, but we will do our best to communicate them as they happen and deployments are updated.
To use the ABIs:

``npm i labor-markets-abi / yarn add labor-markets-abi``

Then imports are
```
import {
    PaymentToken
    
    LaborMarket
    LaborMarketNetwork
    ReputationModule
    ScalableLikertEnforcement
} from "labor-markets-abi
```

```
Each will return an obj with
{
   address: string,
   abi: SolidityJSONABI
}
```