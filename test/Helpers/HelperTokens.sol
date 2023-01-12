// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract AnyReputationToken is ERC1155, Ownable {
    string private metadata;

    constructor(string memory _uri, address newOwner) {
        metadata = _uri;
        _transferOwnership(newOwner);
    }

    function uri(uint256) public view override returns (string memory) {
        return metadata;
    }

    function freeMint(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(account, id, amount, "");
    }

    function freeBurn(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _burn(account, id, amount);
    }

    function distribute(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 id
    ) external onlyOwner {
        require(accounts.length == amounts.length, "Invalid input");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amounts[i], "");
        }
    }
}

contract PaymentToken is ERC20("Payment Token", "PAY", 18), Ownable {
    constructor(address newOwner) {
        _transferOwnership(newOwner);
    }

    function freeMint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    function freeBurn(address receiver, uint256 amount) external onlyOwner {
        _burn(receiver, amount);
    }

    function distribute(address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(accounts.length == amounts.length, "Invalid input");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }
}
