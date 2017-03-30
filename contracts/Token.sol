pragma solidity ^0.4.2;

import './zeppelin/Ownable.sol';
import "./zeppelin/token/StandardToken.sol";

/*
  Wings ERC20 Token.
  Added allocation for users who participiated in Wings Campagin.

  Important!
  We have to run pre-mine allocation first.
  And only then rest of users.
  Or it's not going to work due to whenAllocation logic.
*/
contract Token is StandardToken, Ownable {
  // Account allocation event
  event Allocation(address indexed account, uint amount);

  /*
    Premine events
  */
  event PreminerAdded(address indexed account, uint amount);
  event PremineAllocationAdded(address indexed account, uint time);
  event PremineRelease(address indexed account, uint timestamp, uint amount);

  /*
    Premine scturcture
  */
  struct Preminer {
    address account;
    uint monthlyPayment;
    uint latestAllocation;

    uint allocationsCount;
    mapping(uint => uint) allocations;
  }

  /*
    List of perminers
  */
  mapping(address => Preminer) preminers;

  /*
    Token Name & Token Symbol & Decimals
  */
  string public name = "TWINGS";
  string public symbol = "TWINGS";
  uint public decimals = 18;

  /*
    How many accounts allocated?
  */
  uint public accountsToAllocate;

  /*
    Modifier for checking is allocation completed.
    Maybe we should add here pre-mine accounts too.
  */
  modifier whenAllocation(bool value) {
    if ((accountsToAllocate > 0) == value) {
      _;
    } else {
      throw;
    }
  }

  /*
    Check if user already allocated
  */
  modifier checkUserAllocation(address user) {
    if (balances[user] == 0) {
      _;
    } else {
      throw;
    }
  }

  /*
    Check if preminer already added
  */
  modifier checkPreminerAllocation(address preminer) {
    if (preminers[preminer].account == address(0)) {
      _;
    } else {
      throw;
    }
  }

  function Token(uint _accountsToAllocate) {
    /*
      Maybe we should calculate it in allocation and pre-mine.
      I mean total supply
    */
    totalSupply = 100000000000000000000000000;
    owner = msg.sender;

    accountsToAllocate = _accountsToAllocate;
  }

  /*
    Allocate tokens for users.
    Only owner and only while allocation active.

    Should check if user allocated already (no double allocations)
  */
  function allocate(address user, uint balance) onlyOwner() whenAllocation(true) checkUserAllocation(user) {
    balances[user] = balance;

    accountsToAllocate--;
    Allocation(user, balance);
  }

  /*
    Standard Token functional
  */
  function transfer(address _to, uint _value) whenAllocation(false) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) whenAllocation(false) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) whenAllocation(false) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /*
    Premine functional
  */

  /*
    Add pre-mine account
  */
  function addPreminer(address preminer, uint initialBalance, uint monthlyPayment) onlyOwner() whenAllocation(true) checkPreminerAllocation(preminer) {
    var premine = Preminer(
        preminer,
        monthlyPayment,
        0,
        0
      );


    balances[preminer] = safeAdd(balances[preminer], initialBalance);
    preminers[preminer] = premine;
    accountsToAllocate--;
    PreminerAdded(preminer, initialBalance);
  }

  /*
    Add pre-mine allocation
  */
  function addPremineAllocation(address _preminer, uint _time) onlyOwner() whenAllocation(true) {
    var preminer = preminers[_preminer];

    if (preminer.account == address(0) || _time == 0) {
      throw;
    }

    if (preminer.allocationsCount > 0) {
      var previousAllocation = preminer.allocations[preminer.allocationsCount-1];

      if (previousAllocation > _time) {
        throw;
      }
    }

    preminer.allocations[preminer.allocationsCount++] = _time;
    PremineAllocationAdded(_preminer, _time);
  }

  /*
    Get preminer
  */
  function getPreminer(address _preminer) constant returns (uint, uint, uint) {
    var preminer = preminers[_preminer];

    return (preminer.monthlyPayment, preminer.latestAllocation, preminer.allocationsCount);
  }

  /*
    Get preminer allocation time by index
  */
  function getPreminerAllocation(address _preminer, uint _index) constant returns (uint) {
    return preminers[_preminer].allocations[_index];
  }

  /*
    Release premine when preminer asking
    Gas usage: 0x5786 or 22406 GAS.
    Maximum is 26 monthes of pre-mine in case of Wings. So should be enough to execute it.
  */
  function releasePremine() whenAllocation(false) {
    var preminer = preminers[msg.sender];

    if (preminer.account == address(0)) {
      throw;
    }

    for (var i = preminer.latestAllocation; i < preminer.allocationsCount; i++) {
      if (preminer.allocations[i] < block.timestamp) {
        if (preminer.allocations[i] == 0) {
          continue;
        }

        balances[preminer.account] = safeAdd(balances[preminer.account], preminer.monthlyPayment);
        preminer.latestAllocation = i;

        PremineRelease(preminer.account, preminer.monthlyPayment, preminer.allocations[i]);
        preminer.allocations[i] = 0;
      } else {
        break;
      }
    }
  }
}
