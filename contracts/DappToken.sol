// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DappToken is ERC20 {
    address public owner;

    constructor() ERC20("Dapp Token", "DAPP") {
        owner = msg.sender;
        _mint(owner, 1_000_000 * 10 ** decimals()); // Suministro inicial
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Solo el owner puede mintear tokens");
        _mint(to, amount);
    }
}