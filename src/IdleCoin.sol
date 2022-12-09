// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IdleCoin is ERC20, Ownable {
    uint8 public constant DECIMALS = 18;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol, DECIMALS)
    {}

    function fillWorld(address idleWorld) external onlyOwner {
        _mint(idleWorld, 2**256 - 1);
    }
}
