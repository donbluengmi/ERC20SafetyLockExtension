// SPDX-License-Identifier: MIT

abstract contract lockextension {

    mapping(address => address) lockaddress;
    mapping(address => mapping(address => bool)) transferallowed;
    mapping(address => mapping(address => bool)) safemode;
    mapping(address => mapping(address => mapping(address => bool))) immunerecipientrequest;
    mapping(address => mapping(address => bool)) immunerecipient;
    mapping(address => mapping(address => mapping(address => bool))) lockaddresschangeallowed;

    /**
     * Prevents transfers and approvals, if the lockaddress of the caller has unallowed
     * transfers. If the sender has not specified a lockaddress, or the lockddress hasnt
     * unallowed transfers, this modifier wont have any functional effect. Note, that
     * already approved addresses can still transfer tokens through transferfrom, as long
     * as safemode (following modifier) isnt activated by either the holder or the
     * lockaddress, for the holder. Recipients, that have been given immunity, by holder
     * and lockaddress in accordance, can always receive tokens. If tokens have been
     * transferred to an immune address, that address`s immunity is gone and has to be
     * renewed.
     */

    modifier lockable(address holder, address recipient) {
        if(lockaddress[holder] != address(0)) {
            if(!immunerecipient[holder][recipient]) {
                require(transferallowed[lockaddress[holder]][holder]);   
            } else {
                immunerecipient[holder][recipient] = false;
            }
        }
        _;    
    }
    
    /**
     * Can prevent anyone, even already approved addresses, to call transferFrom (if added
     * as modifier to the transferFrom functioon), if the lockaddress of the caller has
     * unallowed transfers. If the sender has not specified a lockaddress, or the lockaddress
     * hasnt unallowed transfers, this modifier wont have any functional effect.
     */
     
    modifier lockedrisk(address holder, address recipient) {
        if(lockaddress[holder] != address(0)) {
            require(!safemode[lockaddress[holder]][holder] && !safemode[holder][holder]);
        }
        _;
    }

    /**
     * Only used inside this abstract contract to ensure only the token holder and the
     * lockaddress can change attributes of the token holder, if allowed by the other.
     */

    modifier authorized(address holder) {
        require(msg.sender == holder || msg.sender == lockaddress[holder]);
        _;
    }

    /**
     * Sets the lockaddress. If a address is already specified as the lockaddress, that
     * address will have to allow this change beforehand, or this function will have
     * to be called by the lockaddress, while the holders address allowed the change
     * beforehand.
     */
     
    function setlockaddress(address holder, address newlockaddress) external authorized(holder) {
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
        }
        lockaddress[msg.sender] = newlockaddress;
    }

    /**
     * Allows any address to allow and unallow tokentransfers of any address, but will
     * only have significance and actually lock tokens, if the caller is specified as the
     * holders lockaddress.
    */
    
    function lockunlock(address holder, bool allowance) external {
        transferallowed[msg.sender][holder] = allowance;
    }

    /**
     * Allows or unallows the change of a specific address as the lockaddress. Can be called
     * by anyone, for anyone, but wont have any direct effect, if not called by the holder
     * or its lockaddress.
    */
    
    function allowunallowlockchange(address holder, address possiblelockaddress, bool allowance) external {
        lockaddresschangeallowed[msg.sender][holder][possiblelockaddress] = allowance;
    }

    /**
     * Allows or unallows already approved addresses to call transferFrom, even when the
     * holders tokens are locked. Can be called by anyone, but wont have any direct effect,
     * if not called by the holder or its lockaddress. It only takes one of them to set this
     * state to true, for approved addresses to be unable to call transferFrom
    */
    
    function setsafemode(address holder, bool state) external {
        safemode[msg.sender][holder] = state;
    }
    
    /**
     * Allows either the holder, or/and its lockaddress to allow the unconditional transfer to
     * the specified address (immunity).
     */
     
    function requestimmuneaddress(address holder, address immune) external {
        if(msg.sender == holder || msg.sender == lockaddress[holder]) {
            immunerecipientrequest[msg.sender][holder][immune] = true;
        }
    }

    /**
     * Sets an immune address, that can always receive funds from the holders account. Cant
     * be reverted and is callable by either the holder or the lockaddress, if the each other
     * has requested immunity for that particular address for the holder.
     */
     
    function setimmuneaddress(address holder, address immune) external authorized(holder) {
        if(msg.sender == holder) {
            require(immunerecipientrequest[lockaddress[holder]][holder][immune]);
            immunerecipient[holder][immune] = true;
            } else {
                require(immunerecipientrequest[holder][holder][immune]);
                immunerecipient[holder][immune] = true;
                }        
    }
    
    function getlockaddress(address holder) public view returns (address) {
        return lockaddress[holder];
    }
    
    function getlockstatus(address lock, address holder) public view returns (bool) {
        return transferallowed[lock][holder];
    }
    
    function getlockaddresschangeallowance(address setter, address holder, address lock) public view returns (bool) {
        return lockaddresschangeallowed[setter][holder][lock];
    }
    
    function getsafemode(address setter, address holder) external view returns (bool) {
        return safemode[setter][holder];
    }   

}
