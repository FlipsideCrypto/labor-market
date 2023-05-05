// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

contract ERC1155FreeMint is ERC1155 {
    string private metadata;

    constructor() ERC1155('uri/') {
        metadata = 'uri/';
    }

    function uri(uint256) public view override returns (string memory) {
        return metadata;
    }

    function freeMint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _mint(account, id, amount, '');
    }

    function freeBurn(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _burn(account, id, amount);
    }

    function distribute(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 id
    ) external {
        require(accounts.length == amounts.length, 'Invalid input');
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amounts[i], '');
        }
    }
}
