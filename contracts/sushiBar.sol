// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
//
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBar is ERC20("SushiBar", "xSUSHI"){
    using SafeMath for uint256;
    IERC20 public sushi;
    address public withdrawAddress;
    address rewardPoolAddress;
    uint256 public vestingStartTimestamp;
    uint256 public initialTokensBalance;
    // Define the Sushi token contract
    constructor(IERC20 _sushi, address poolAddress) {
        sushi = _sushi;
        rewardPoolAddress = poolAddress;
    }


    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalSushi);
            _mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), _amount);
        vestingStartTimestamp = block.timestamp;
    }
    function unstakeable(uint _sushi) public  returns (uint256) {
        // total amount of sushi user has staked
        initialTokensBalance = _sushi;
        uint256 unStakeablevalue = 0;
        if ((block.timestamp-vestingStartTimestamp)>8 days){
            unStakeablevalue =initialTokensBalance;
        }else if ((block.timestamp-vestingStartTimestamp)>6 days){
            unStakeablevalue = (initialTokensBalance.mul(75)).div(100);
        }else if ((block.timestamp-vestingStartTimestamp)>4 days){
            unStakeablevalue = (initialTokensBalance.mul(50)).div(100);
        }else if ((block.timestamp-vestingStartTimestamp)>2 days){
            unStakeablevalue = (initialTokensBalance.mul(25)).div(100);
        }
        return unStakeablevalue;       
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 _share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Sushi which can be claimed according to timelock
        uint256 unstakingAmout = unstakeable(_share);
        //deduct the tax from staked amount according to timelock
        uint256 tax = sushi.balanceOf(address(this)) - unstakingAmout;
        // calculate the amount of sushi which can be unstaked + rewards on staked
        uint256 what = _share.mul(unstakingAmout).div(totalShares);
        _burn(msg.sender, _share);

        // add sushi from rewardpool to the contract
        if(what >= sushi.balanceOf(address(this))) {

            sushi.transferFrom(rewardPoolAddress, address(this), what);
        }

        sushi.transfer(msg.sender, what);
        // send the taxed sushi in the rewardPool
        sushi.transfer(rewardPoolAddress,tax);
    }
}