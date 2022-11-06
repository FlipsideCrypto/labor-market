// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract AnyReputationToken is ERC1155 {
    uint256 public constant DELEGATE_TOKEN_ID = 0;
    uint256 public constant PARTICIPATION_TOKEN_ID = 1;
    string private metadata;

    constructor(string memory _uri) {
        metadata = _uri;
    }

    function uri(uint256) public view override returns (string memory) {
        return metadata;
    }

    function freeMint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _mint(account, id, amount, "");
    }
}

contract PaymentToken is ERC20("Payment Token", "PAY", 18) {
    function freeMint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }
}
