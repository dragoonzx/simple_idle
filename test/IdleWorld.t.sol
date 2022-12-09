// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/IdleAccess.sol";
import "../src/IdleWorld.sol";

contract IdleWorldTest is Test {
    using stdStorage for StdStorage;

    IdleAccess private nft;
    IdleWorld private world;
    IdleCoin private coin;

    function setUp() public {
        nft = new IdleAccess("IdleAccess", "IPASS");
        coin = new IdleCoin("IdleCoin", "ICOIN");
        world = new IdleWorld(nft, coin);

        coin.fillWorld(address(world));
    }

    function testFailStart() public {
        world.start();
    }

    function _startWithAdressOne() private {
        nft.mintTo{value: nft.MINT_PRICE()}(address(1));
        vm.startPrank(address(1));
        world.start();

        vm.stopPrank();
    }

    function testStart() public {
        _startWithAdressOne();
    }

    function testCalculateCoins() public {
        uint256 initialTimestamp = 1641070800;
        vm.warp(initialTimestamp);
        _startWithAdressOne();

        uint256 secondsAfter = 200;
        vm.warp(initialTimestamp + secondsAfter);
        uint256 calculatedCoins = world.calculateCoins(address(1));
        assertEq(calculatedCoins, 200 * 1e18);
    }

    function testWithdraw() public {
        uint256 initialTimestamp = 1641070800;
        vm.warp(initialTimestamp);
        _startWithAdressOne();

        uint256 secondsAfter = 200;
        vm.warp(initialTimestamp + secondsAfter);

        assertEq(coin.balanceOf(address(1)), 0);

        vm.startPrank(address(1));
        world.withdraw(50 * 1e18);
        assertEq(coin.balanceOf(address(1)), 50 * 1e18);
        assertEq(world.calculateCoins(address(1)), 150 * 1e18);
        vm.stopPrank();
    }

    function testDepositNoPlayerRevert() public {
        // imitate address with some coins
        uint256 slot = stdstore
            .target(address(coin))
            .sig(coin.balanceOf.selector)
            .with_key(1)
            .find();
        bytes32 loc = bytes32(slot);

        bytes32 mockedSomeoneCoinBalance = bytes32(abi.encode(10 * 1e18));
        vm.store(address(coin), loc, mockedSomeoneCoinBalance);
        assertEq(coin.balanceOf(address(1)), 10 * 1e18);
        // try to deposit into the game to become player
        vm.startPrank(address(1));
        coin.approve(address(world), 10 * 1e18);
        vm.expectRevert(NotPlayer.selector);
        world.deposit(10 * 1e18);
        vm.stopPrank();
    }

    // function testBooster() public {
    //     uint256 slot = stdstore
    //         .target(address(world))
    //         .sig(world.players.selector)
    //         .with_key(1)
    //         .find();
    //     bytes32 loc = bytes32(slot);

    //     bytes32 mockedPlayerWithBalance = bytes32(
    //         abi.encode(block.timestamp, world.BASE_ACCELERATION, 150 * 1e18)
    //     );
    //     vm.store(address(world), loc, mockedPlayerWithBalance);

    //     (, , uint256 currentBalance) = world.players(address(1));
    //     // assertEq(currentBalance, 150 * 1e18);
    //     assertEq(world.calculateCoins(address(1)), 150 * 1e18);

    //     vm.startPrank(address(1));
    //     // world.boost(Booster.Factory);

    //     // uint256 secondsAfter = 200;
    //     // vm.warp(block.timestamp + secondsAfter);
    //     // assertEq(world.calculateCoins(address(1)), 200 * 5 * 1e18);

    //     vm.stopPrank();
    // }
}
