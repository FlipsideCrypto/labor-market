// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ERC20FreeMint is ERC20 {
    uint8 public DECIMALS = 18;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        DECIMALS = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    function freeMint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }

    function freeBurn(address receiver, uint256 amount) external {
        _burn(receiver, amount);
    }

    function distribute(address[] calldata accounts, uint256[] calldata amounts) external {
        require(accounts.length == amounts.length, 'Invalid input');
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }
}
