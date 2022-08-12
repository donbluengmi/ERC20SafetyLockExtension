# ERC20SecurityLockExtension

An abstract contract, that can be implemented to any ERC20 token, to protect tokens from wallet hacks. The idea behind this extension is to bring the protection, the use of multi signature wallet brings, but also keep the felxibility single signature wallets have, to all ERC20 tokens.

## Thought behind it

Wallet hacks, due to the widespread use of browser extensions, have gotten rather common in the space and its just to be seen how more frequent these will occur in the future, keeping the massive financial values at stake, in mind. Additionally, using wallets safely, by keeping them as cold as possible, or using multi signature wallets, with cold wallets as signers, while also keeping the comfort of just transfering things quickly, is not compatible.

Tokens that have this extension implemented, and whose holders have decided to secure their tokens, are not prone to any kind of wallet hacks.
This is achieved by holders being able to specify a token specific lockaddress that can decide, just as the token holder can, to lock the holders tokens. If locked by one party, the other party wont be able to transfer the holders tokens (for the lockaddress only through the transferfrom function, according to ERC20 anyway). The security of the lockaddress, which by the way, can of course also be a multi signature wallet, directly correlates to the effectiveness of this extension.

Any scenario, in which an attacker is trying to either transfer tokens, or block transactions on either wallet, is solvable with this extension.

This extension largely fails its cause, if users arent specifically cautious using the lockaddress´s account.

### Implementation

Add the abstract contract "ERC20SecurityExtension" to your contract and add the modifier lockedtransfer in the functions transfer and transferfrom like so:

