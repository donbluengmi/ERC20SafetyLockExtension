# ERC20SecurityLockExtension

A contract, that any ERC20 token can inherit from, to protect tokens from wallet hacks. The idea behind this extension is to bring the protection, the use of multi signature wallet brings, but also keep the flexibility (single signature) wallets have, to the holders of ERC20 tokens. Only reasonable to use with high tax tokens, since the individual change to a multi signature wallet when already holding low/no tax tokens, is generally more efficient.

I have written an app, that can be universally used by any token implementing it, to call any function of the extension.
https://github.com/donbluengmi/ERC20SafetyLockExtensionApp

![](https://github.com/donbluengmi/ERC20SafetyLockExtension/blob/main/ScreenCapture_8.gif)

## Thought behind it

Wallet hacks, due to the widespread use of browser extensions, have gotten rather common in the space and its just to be seen how more frequent these will occur in the future, keeping the massive financial values at stake, in mind. Additionally, using wallets safely, by keeping them as cold as possible, or using multi signature wallets, with cold wallets as signers, while also keeping the comfort of just transfering things quickly, is not compatible.

Tokens that have this extension implemented, and whose holders have decided to secure their tokens, are safe from any kind of wallet hacks.
This is achieved by holders being able to specify a token specific lockaddress that can lock the holders tokens. If locked , the holder (and a possible attacker, with access to the hodler wallet), aswell as approved (ERC20 approve) addresses, cant transfer tokens. To be fully safe from any theoretical scenario, holders will also have to give sufficient allowance to some address and set an immune address, so that the approved address can transfer funds from the holders wallet to the immune address, when the holders wallet is under control by some advanced bot, that drains coins (ETH/BNN/etc.), needed to do transactions. These addresses, especially the lockaddress, which by the way, can of course also be a multi signature wallet, directly correlates to the effectiveness of this extension.
This extension largely fails its cause, if users arent specifically cautious using the lockaddress´s account.

The extension is designed, so that any scenario, in which an attacker is trying to either transfer tokens, or block transactions on either wallet, is solvable with this extension.

## Implementation

Add the ERC20SafetyLockExtension contract to your code and let your ERC20 contract iherit from it (```contract ERC20Token is lockextension```), then add the modifier "lockable" to the "transfer" and "transferFrom" functions like so:

```Solidity
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

## Design Choices and detailed Explanation

The lock is designed to be token specific, meaning the code will be redeployed with every token. This is, so that every freshly bought token at first can be handled in complete flexibilty. If a specific token is, at the time of buying, or has, later on become a token of monetary significance for the holder, the effort to individually lock it, shouldnt be as much of a problem to otherwise (if the lockaddress would be centralised organized for every token), always having to unlock tokens to transfer them after getting ahold of them.
Since every new token deployment comes with the lockextension`s code, events (only useful for frontends) have been left out from the contract. in favor of lower deployment cost.

-The lockaddress can decide to lock and unlock the holders tokens at will.

-Both the lockaddress and the holder can request immunity for a specific address, which if both agreed on, will now forever be able to receive tokens from the token holders wallet, thorugh either transferFrom or transfer, no matter if the tokens are locked or not. The request on both sides is not revertable.

-Both the lockaddress and the holder can request a new lockaddress and if one party has already requested a new lockaddress, the other party can change the lockaddress directly. The request on both sides is revertable.

=> If an attacker gets ahold of the holders wallet he cant transfer tokens to his wallet, he could though, if an address has been given immunity, transfer address to that address.<br>
The attacker could approve every address he wanted to, but if the tokens are still locked by the lockaddress, couldnt transfer tokens to a recipient, that doesnt have immunity.<br>
The attacker could also request both a new lockaddress and immunity for an address, but that wouldnt have any effect, until the lockaddress had agreed on these changes. The attacker also cant block any transfers or requests for immunity addresses, since once initiated by the actual token holder those changes cant be reverted (Meaning, requests for immunity for an address cant be taken back).

=> If an attacker gets ahold of the lockaddresss wallet he can unlock the hodlers tokens, but if the holders wallet isnt under the control of an attacker, that wont, of course, have any direct effect on the holders tokens. <br>
Just like an attacker with access to the holders wallet could, an attacker with access to the lockaddress`s wallet would be able to request immunity for an address or a new lockaddress for the holder, but just like for the holders wallet, that wont have any actual effect, unless the token holder agrees on these changes. An attacker also wouldnt be able to block the two crucial functions in the scenario of an attack, changing the lockaddress and setting an immune address, since the request for an immune address cant be reverted and, if the holder has already requested an lockaddress change, calling the function to change the lockaddress for the lockaddress by the lockaddress will be final.

=> If an attacker gets access to any (by the token hodler) approved address, he can transfer the tokens to an immune address (if specified), but wont be able to send tokens to any other address, as long as the tokens are locked by the lockaddress.

=> If an attacker gets access to an immune address, he cant do anything, unless the token holder or an approved address sends tokens to it.

So, the safety of all the addresses involved directly correlates to the users funds.
