# ERC20SecurityLockExtension

A code snippet, that can be implemented to any ERC20 token, to protect tokens from wallet hacks. The idea behind this extension is to bring the protection, the use of multi signature wallet brings, but also keep the flexibility single signature wallets have, to the holders of ERC20 tokens. Only reasonable to use with high tax tokens, since the change to a multi signature wallet when already holding low/no tax tokens, is generally more efficient.

## Thought behind it

Wallet hacks, due to the widespread use of browser extensions, have gotten rather common in the space and its just to be seen how more frequent these will occur in the future, keeping the massive financial values at stake, in mind. Additionally, using wallets safely, by keeping them as cold as possible, or using multi signature wallets, with cold wallets as signers, while also keeping the comfort of just transfering things quickly, is not compatible.

Tokens that have this extension implemented, and whose holders have decided to secure their tokens, are safe from any kind of wallet hacks.
This is achieved by holders being able to specify a token specific lockaddress that can lock the holders tokens. If locked , the holder (and a possible attacker, with access to the hodler wallet) cant transfer tokens and cant approve new addresses. Additionaly a safer mode can be activated that will also prevent already approved addresses to be able to transfer tokens through transferFrom. More on the  The security of the lockaddress, which by the way, can of course also be a multi signature wallet, directly correlates to the effectiveness of this extension.

Any scenario, in which an attacker is trying to either transfer tokens, or block transactions on either wallet, is solvable with this extension.

This extension largely fails its cause, if users arent specifically cautious using the lockaddress´s account.

## Implementation

Add the mappings to your contract...

```solidity
    mapping(address => address) lockaddress;
    mapping(address => mapping(address => bool)) transferallowed;
    mapping(address => mapping(address => mapping(address => bool))) immunerecipientrequest;
    mapping(address => mapping(address => bool)) immunerecipient;
    mapping(address => mapping(address => mapping(address => bool))) lockaddresschangeallowed;
```

...the modifiers...
```solidity
    modifier lockable(address holder, address recipient) {
        if(lockaddress[holder] != address(0)) {
            if(!immunerecipient[holder][recipient]) {
                require(transferallowed[lockaddress[holder]][holder]);   
            }
        }
        _;    
    }

    modifier authorized(address holder) {
        require(msg.sender == holder || msg.sender == lockaddress[holder]);
        _;
    }
```

...the state changing functions...
```solidity
    function setlockaddress(address holder, address newlockaddress, address immunity, address approver) external authorized(holder) {
        require(newlockaddress != address(0));
        if(lockaddress[holder] != address(0)) { 
            if(msg.sender != holder) {
                require(msg.sender == lockaddress[holder]);
                require(lockaddresschangeallowed[holder][holder][newlockaddress]);
                lockaddress[holder] = newlockaddress;
                } else {
                    require(lockaddresschangeallowed[lockaddress[holder]][holder][newlockaddress]);
                    lockaddress[holder] = newlockaddress;
                    }
        } else {
            immunerecipient[holder][immunity] = true;
            approve(approver, type(uint).max);
        }
        lockaddress[msg.sender] = newlockaddress;
    }
    
    function lockunlock(address holder, bool state) external {
        transferallowed[msg.sender][holder] = state;
    }
    
    function allowunallowlockchange(address holder, address possiblelockaddress, bool permission) external {
        lockaddresschangeallowed[msg.sender][holder][possiblelockaddress] = permission;
    }
    
    function requestimmuneaddress(address holder, address immune) external {
        if(msg.sender == holder || msg.sender == lockaddress[holder]) {
            immunerecipientrequest[msg.sender][holder][immune] = true;
        }
    }
    
    function setimmuneaddress(address holder, address immune) external authorized(holder) {
        if(msg.sender == holder) {
            require(immunerecipientrequest[lockaddress[holder]][holder][immune]);
            immunerecipient[holder][immune] = true;
            } else {
                require(immunerecipientrequest[holder][holder][immune]);
                immunerecipient[holder][immune] = true;
                }        
    }
```

...the read functions...
```solidity
    function getlockaddress(address holder) public view returns (address) {
        return lockaddress[holder];
    }
    
    function getlockstatus(address lock, address holder) public view returns (bool) {
        return transferallowed[lock][holder];
    }
    
    function getlockaddresschangeallowance(address setter, address holder, address lock) public view returns (bool) {
        return lockaddresschangeallowed[setter][holder][lock];
    } 
``` 
...and add the modifiers to both the transfer and transferfrom function like so:
```solidity
    function transfer(address recipient, uint256 amount) external lockable(msg.sender, recipient) override returns (bool) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external lockable(sender, recipient) override returns (bool) {
        require(allowances[sender][msg.sender] >= amount);

        allowances[sender][msg.sender] - amount;

        balances[msg.sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
                
        emit Transfer(sender, recipient, amount);
        return true;
    }
```
Sadly even simpler implementation is not possible, since the setlockadrress function relies on calling the ERC20 approve function, so that inheritance from a parent contract would not be possible.
Explanation on all the functions can be found in the solidity file.

## Design Choices and detailed Explanation

This extension is designed to be token specific, meaning the code will be redeployed with every token. This is, so that every freshly bought token at first can be handled in complete flexibilty. If a specific token is, at the time of buying, or has, later on become a token for monetary significance for the holder, the effort to individually lock it, shouldnt be as much of a problem to otherwise (if the lockaddress would be centralised organized for every token), always having to unlock tokens to transfer them after getting ahold of them.
Since every new token deployment comes with a deployment of the lockextension`s code, events (only useful for frontends) have been left out from the contract.

-The lockaddress can decide to lock and unlock the holders tokens at will.

-Both the lockaddress and the holder can request immunity for a specific address, which if both agreed on, will now forever be able to receive tokens from the token holder wallet, thorugh either transferFrom or transfer, no matter if the tokens are locked or not. The request on both sides is not revertable.

-Both the lockaddress and the holder can request a new lockaddress and if one party has already requested a new lockaddress, the other party can change the lockaddress directly. The request on both sides is revertable.

=> If an attacker gets ahold of the holders wallet he cant transfer tokens to his wallet, he could though, if both the lockaddress and the holder had earlier agreed to give an address immunity, transfer address to that address.<br>
The attacker could approve every address he wanted to, but if the tokens are still locked by the lockaddress, couldnt transfer tokens to a recipient, that doesnt have immunity.<br>
The attacker could also request both a new lockaddress and immunity for an address, but that wouldnt have any effect, until the lockaddress had agreed on these changes. The attacker also cant block any transfers or requests for immunity addresses, since once initiated by the actual token holder those changes cant be reverted (Meaning, requests for immunity for an address cant be taken back).

=> If an attacker gets ahold of the lockaddresss wallet he can unlock the hodlers tokens, but if the holders wallet isnt under the control of an attacker, that wont, of course, have any direct effect on the holders tokens. <br>
Just like an attacker with access to the holders wallet could, an attacker with access to the lockaddress`s wallet would be able to request immunity for an address or a new lockaddress for the holder, but just like for the holders wallet, that wont have any actual effect, unless the token holder agrees on these changes. An attacker also wouldnt be able to block the two crucial functions in the scenario of an attack, changing the lockaddress and setting an immune address, since the request for an immune address cant be reverted and, if the holder has already requested an lockaddress change, calling the function to change the lockaddress for the lockaddress by the lockaddress will be final.
