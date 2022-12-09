// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IdleAccess.sol";
import "./IdleCoin.sol";

error HasNoAccess();
error BoosterNotExist();
error NotEnoughCoins();
error NotPlayer();

enum Booster {
    Farm,
    Factory,
    Country
}

/// @title Simple idle mechanic showcase contract
/// @author Max S (https://github.com/dragoonzx)
/// @notice Idle mechanic when player earns by doing nothing and can buy boosters to earn more coins per second
contract IdleWorld {
    IdleAccess public immutable idleAccess;
    IdleCoin public immutable idleCoin;
    uint256 public constant BASE_ACCELERATION = 1;

    struct PlayerInfo {
        uint256 updatedTimestamp;
        uint256 acceleration;
        uint256 updatedBalance;
    }

    mapping(address => PlayerInfo) public players;

    constructor(IdleAccess _idleAccess, IdleCoin _idleCoin) {
        idleAccess = _idleAccess;
        idleCoin = _idleCoin;
    }

    /// @notice Check if caller has IdleAccess NFT, if true => start to earn to that address
    function start() external {
        if (idleAccess.balanceOf(msg.sender) == 0) {
            revert HasNoAccess();
        }

        players[msg.sender] = PlayerInfo(block.timestamp, BASE_ACCELERATION, 0);

        emit PlayerStarted(msg.sender);
    }

    function calculateCoins(address player) public view returns (uint256) {
        PlayerInfo memory info = players[player];
        return
            _calculateCoins(
                info.updatedTimestamp,
                info.acceleration,
                info.updatedBalance
            );
    }

    function _calculateCoins(
        uint256 updatedTimestamp,
        uint256 acceleration,
        uint256 updatedBalance
    ) private view returns (uint256) {
        return
            updatedBalance +
            ((block.timestamp - updatedTimestamp) * acceleration * 1e18);
    }

    /// @notice Player can deposit IdleCoin
    /// @param amount IdleCoin token amount
    function deposit(uint256 amount) external onlyPlayer {
        PlayerInfo memory info = players[msg.sender];

        uint256 balance = _calculateCoins(
            info.updatedTimestamp,
            info.acceleration,
            info.updatedBalance
        );

        idleCoin.transferFrom(msg.sender, address(this), amount);

        players[msg.sender] = PlayerInfo(
            block.timestamp,
            info.acceleration,
            balance + amount
        );

        emit Deposit(msg.sender, amount);
    }

    /// @notice Player can withdraw IdleCoin
    /// @param amount IdleCoin token amount
    function withdraw(uint256 amount) external onlyPlayer {
        PlayerInfo memory info = players[msg.sender];

        uint256 balance = _calculateCoins(
            info.updatedTimestamp,
            info.acceleration,
            info.updatedBalance
        );

        if (amount > balance) {
            revert NotEnoughCoins();
        }

        idleCoin.transfer(msg.sender, amount);

        players[msg.sender] = PlayerInfo(
            block.timestamp,
            info.acceleration,
            balance - amount
        );

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Player can but booster to earn more IdleCoin per second
    /// @param booster booster type from Booster enum
    function boost(Booster booster) external onlyPlayer {
        (uint256 price, uint256 bonus) = _boosterPriceBonus(booster);

        PlayerInfo memory info = players[msg.sender];

        uint256 amount = _calculateCoins(
            info.updatedTimestamp,
            info.acceleration,
            info.updatedBalance
        );

        if (price > amount) {
            revert NotEnoughCoins();
        }

        uint256 balance = amount - price;
        players[msg.sender] = PlayerInfo(
            block.timestamp,
            info.acceleration + bonus,
            balance
        );

        emit PlayerBoosted(msg.sender, booster);
    }

    function _boosterPriceBonus(Booster booster)
        private
        pure
        returns (uint256, uint256)
    {
        if (booster == Booster.Farm) {
            return (30 * 1e18, 2);
        } else if (booster == Booster.Factory) {
            return (150 * 1e18, 5);
        } else if (booster == Booster.Country) {
            return (1000 * 1e18, 20);
        } else {
            revert BoosterNotExist();
        }
    }

    modifier onlyPlayer() {
        if (players[msg.sender].updatedTimestamp == 0) {
            revert NotPlayer();
        }
        _;
    }

    // Questions:
    // - Is it better to not use uint256 everywhere? what are the pros/cons

    event PlayerStarted(address indexed player);
    event PlayerBoosted(address indexed player, Booster booster);
    event Deposit(address indexed player, uint256 amount);
    event Withdraw(address indexed player, uint256 amount);
}
