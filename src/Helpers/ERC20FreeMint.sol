// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract ERC20FreeMint is ERC20("Payment Token", "PAY", 18) {
    constructor() {}

    function freeMint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }

    function freeBurn(address receiver, uint256 amount) external {
        _burn(receiver, amount);
    }

    function distribute(address[] calldata accounts, uint256[] calldata amounts)
        external
    {
        require(accounts.length == amounts.length, "Invalid input");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }
}