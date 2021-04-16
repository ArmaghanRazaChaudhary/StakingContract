
pragma solidity ^ 0.5.3;

import "./IBEP20.sol";
import "./SafeMath.sol";

contract Staking {
    using SafeMath for uint256;
    struct Stakes {
        uint256 stakedAmount;
        uint256 blockNumber;
    }

    mapping(address => Stakes) public stakeRecords;
    mapping(address => uint256) public stakeRewards;
    IBEP20 stakingToken;

    uint256 public totalStakes;
    address internal _owner;
    bool private isInitialized;
    bool private isPause;

    function init() public {
        require(!isInitialized, "already initialized");
        isInitialized = true;
        _owner = msg.sender;
        totalStakes = 0;
        stakingToken = IBEP20(0x5Baa03450699F86961CA7Ca355E80Ad0E7323e00);
    }

    function createStake(uint256 amount) public isPaused {
        require(amount > 0, "Create Stake");
        if (stakeRecords[msg.sender].blockNumber > 0) stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        totalStakes = SafeMath.add(totalStakes, amount);
        stakeRecords[msg.sender] = Stakes(SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount), block.number);
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    function unStake(uint256 _amount) public isPaused {
        uint256 stakeAmount = stakeRecords[msg.sender].stakedAmount;
        require(_amount > 0 && _amount <= stakeAmount, "Unstake");
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        if (stakeAmount == _amount) {
            stakingToken.mint(msg.sender, stakeRewards[msg.sender]);
            stakeRewards[msg.sender] = 0;
            delete stakeRecords[msg.sender];
        } else {
            stakeAmount = SafeMath.sub(stakeAmount, _amount);
            stakeRecords[msg.sender].stakedAmount = stakeAmount;
            stakeRecords[msg.sender].blockNumber = block.number;
        }
        totalStakes = SafeMath.sub(totalStakes, _amount);
        stakingToken.transfer(msg.sender, _amount);
    }

    function compound() public isPaused {
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        stakingToken.mint(address(this), stakeRewards[msg.sender]);
        helperCompound(stakeRewards[msg.sender]);
        stakeRewards[msg.sender] = 0;
    }

    function helperCompound(uint256 amount) private {
        require(amount > 0, "Amount is equal to 0");
        stakeRecords[msg.sender].stakedAmount = SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount);
        stakeRecords[msg.sender].blockNumber = block.number;
        totalStakes = SafeMath.add(totalStakes, amount);
    }

    function harvest() public isPaused {
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        require(stakeRewards[msg.sender] > 0, "Harvest");
        stakingToken.mint(msg.sender, stakeRewards[msg.sender]);
        stakeRewards[msg.sender] = 0;
        stakeRecords[msg.sender].blockNumber = block.number;
    }

    function calculateReward(address _stakeHolder) public view returns(uint256) {
        uint256 stakeAmount = stakeRecords[_stakeHolder].stakedAmount;
        uint256 blocks = SafeMath.sub(block.number,stakeRecords[_stakeHolder].blockNumber); 
        stakeAmount = SafeMath.div(stakeAmount,100); 
        uint256 reward = SafeMath.mul(stakeAmount,blocks);
        reward = SafeMath.div(reward,864000);
        return reward;
    }

    function emergencyWithdraw() public {
        require(msg.sender == _owner, "Not authorized to use this function");
        stakingToken.transfer(msg.sender, stakingToken.balanceOf(address(this)));
    }

     modifier isPaused() {        
        require(!isPause, "already Paused");
        _;
    }

    function pauseContract(bool _pause) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        isPause = _pause;
    }

    function changeOwnership(address newOwner) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        _owner = newOwner;
    }
}