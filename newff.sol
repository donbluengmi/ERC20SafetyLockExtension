// SPDX-License-Identifier: MIT


// CAUTION
// This extension should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

abstract contract multisig {
    event lockaddressset(address holder, address newlockaddress);
    event transferallowed(address allower, address holder, bool allowance);
    event changelockaddressallowed(address allower, address holder, address allowed, bool allowance);

    mapping(address => bool) lockexistent;
    mapping(address => address) lockaddress;
    mapping(address => mapping(address => bool)) transferunallowed;
    mapping(address => mapping(address => mapping(address => bool))) lockaddresschangeallowed;

    /**
     * Prevents a transfer (if added as modifier to any function allowing transfer
     * (transfer and transferFrom in ERC20)), if the permissioned address of the caller
     * has unallowed transfer. If the sender has not specified a permissioned address,
     * or the permissioned addres hasnt unallowed transfers, this modifier wont have any
     * functional effect.
     */

    modifier lockedtransfer(address holder, uint256 amount, address _msgsender) {
        if(getlockexistence(holder)) { 
                if(_msgsender != holder) {
                    require(_msgsender == lockaddress[holder]);
                    require(!transferunallowed[holder][holder]);
                    } else {
                        require(!transferunallowed[lockaddress[holder]][holder]);
                    }
            }
        _;    
    }

  /**
   * Only used inside this abstract contract to ensure only the token holder and the
   * lockaddress can change attributes of the token holder, if allowed by the other.
   */

  modifier innerabstract(address holder) {
    require(msg.sender == holder || msg.sender == lockaddress[holder]);
    _;
  }

  /**
   * Sets the permissioned address. If a address is already specified as the
   * permissioned address, that address will have to allow this change beforehand, or
   * this function will have to be called by the permissioned address, while the
   * holders address allowed the change beforehand.
   */

  function setlockaddress(address holder, address newlockaddress) external innerabstract(holder) {
      if(lockexistent[msg.sender]) { 
            if(msg.sender != holder) {
                require(msg.sender == lockaddress[holder]);
                require(lockaddresschangeallowed[holder][holder][newlockaddress]);
                lockaddress[holder] = newlockaddress;
                } else {
                require(lockaddresschangeallowed[lockaddress[holder]][holder][newlockaddress]);
                lockaddress[holder] = newlockaddress;
                }
        }
      lockaddress[msg.sender] = newlockaddress;
      lockexistent[msg.sender] = true;
      emit lockaddressset(holder, newlockaddress);  
  }

    /**
     * Allows any address to lock tokens of any address, but will only actually
     * prevent transfers if it is specified as the senders permissioned address.
    */

  function allowunallowtransfer(address holder, bool allowance) external {
      transferunallowed[msg.sender][holder] = allowance;
      emit transferallowed(msg.sender, holder, allowance);
  }

    /**
     * Allows or unallows the change of a specific address as the permissioned address.
     * Can be called by anyone, for anyone, but wont have any direct effect, if not called
     * by the holder or its permissioned address.
    */

  function allowunallowmultichange(address holder, address possiblelockaddress, bool allowance) external {
      lockaddresschangeallowed[msg.sender][holder][possiblelockaddress] = allowance;
      emit changelockaddressallowed(msg.sender, holder, possiblelockaddress, allowance);

  }

  function getlockexistence(address holder) public view returns (bool) {
    return lockexistent[holder];
  }

  function getlockaddress(address holder) public view returns (address) {
      return lockaddress[holder];
  }

  function getlockstatus(address holder) public view returns (bool) {
      if(transferunallowed[lockaddress[holder]][holder] || transferunallowed[holder][holder]){
          return true;
      } else{
              return false;
          }
  }

  function getpersonallock(address holder) external view returns (bool){
      return transferunallowed[msg.sender][holder];
  }

  

pragma solidity ^0.8.0;


interface IERC20 {

function name() external view returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint256);
function totalSupply() external view returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract IERC20MintableExampleToken is IERC20, multisig {

    
    string _name = "ERC20MintableToken";
    string _symbol = "IMT";
    uint256 _decimals = 18;
    uint256 _totalSupply = 123;

    address zeroaddress = 0x0000000000000000000000000000000000000000;


    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowances;

    constructor (){

    }

    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function decimals() external view override returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return allowances[holder][spender]; }


    function transfer(address recipient, uint256 amount) external lockedtransfer(msg.sender, amount, msg.sender) override returns (bool) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external lockedtransfer(msg.sender, amount, sender) override returns (bool) {
        require(allowances[sender][msg.sender] >= amount);

        allowances[sender][msg.sender] - amount;

        balances[msg.sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
                
        emit Transfer(sender, recipient, amount);
        return true;

    }

    function approve(address spender, uint256 value) external override returns (bool) {
        allowances[msg.sender][spender] = allowances[msg.sender][spender] + value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function mint() external returns (bool) {
        require(balances[msg.sender] <= 100**18);

        uint256 mintvalue = 10**18;
        balances[msg.sender] =  balances[msg.sender] + mintvalue;

        emit Transfer(zeroaddress, msg.sender, mintvalue);
        return true;
    }





}