// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/IdleAccess.sol";
import "../src/IdleWorld.sol";

contract IdleCoinTest is Test {
    IdleAccess private nft;
    IdleWorld private world;
    IdleCoin private coin;

    function setUp() public {
        nft = new IdleAccess("IdleAccess", "IPASS");
        coin = new IdleCoin("IdleCoin", "ICOIN");
        world = new IdleWorld(nft, coin);
    }

    function testWorldFill() public {
        coin.fillWorld(address(world));
        assertEq(coin.balanceOf(address(world)), 2**256 - 1);
    }
}
