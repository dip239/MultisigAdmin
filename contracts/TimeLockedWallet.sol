pragma solidity ^0.4.11;

contract Owned {

    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier only(address allowed) {
        if (msg.sender != allowed) throw;
        _;
    }
}

contract ERC20_Transferable {
    function balanceOf(address addr) public returns(uint);
    function transfer(address to, uint value) public returns (bool);
}

contract TimeLockedWallet is Owned {

    ERC20_Transferable token = ERC20_Transferable(0x0);

    uint constant SHARES_NUM = 14;

    address[] team_accounts;
    mapping (address => bool) team_approvers;
    uint team_addr_count=0;
    uint constant lockTime = 90 days;
    uint deployTime = now;
    uint approvalsPending;
    uint locked_token_amount=0;
    uint locked_since = 0;

    function all_team_accounts() constant returns(address[]) {
        return team_accounts;
    }


    function TimeLockedWallet() {
        owner = msg.sender;
        team_approvers[0x0] = true;
        team_approvers[0x0] = true;
        team_approvers[0x0] = true;
        team_approvers[0x0] = true;
        team_approvers[0x0] = true;
        team_approvers[0x0] = true;
        team_approvers[0x0] = true;
        approvalsPending = 7;
    }

    function () payable {
        msg.sender.transfer(msg.value); //pay back whole amount

        if (_state()==State.INITIALIZATION) {
            //collect addresses for payout
            require(indexOf(team_accounts,msg.sender)==-1);
            require(!team_approvers[msg.sender]);
            team_accounts.push(msg.sender);
            //last address received...
            if (team_accounts.length == SHARES_NUM) {
                locked_token_amount = token.balanceOf(this); // ...save expected token amount
            }
        } else if (_state()==State.LOCKING) {
            // collect approvals for start
            require(team_approvers[msg.sender]);
            team_approvers[msg.sender] = false;
            //last approval received
            if (--approvalsPending==0) {
                locked_since = now; // ... save lock time
            }
        } else if (_state()==State.LOCKED) {
            //emergency abort
            require(msg.sender == owner);
            require(now < locked_since + 7 days);
            var balance = token.balanceOf(this);
            token.transfer(owner, balance);
        } else if (_state()==State.WITHDRAWAL) {
            require(indexOf(team_accounts, msg.sender)>=0);
            token.transfer(owner, locked_token_amount / SHARES_NUM);
        } else if (_state()==State.ERROR) {
            //state ERROR
            token.transfer(owner, token.balanceOf(this) );
        } else {
            //should not occur...
            revert();
        }


    }


    enum State {UNDEF, INITIALIZATION, LOCKING, LOCKED, WITHDRAWAL, ERROR}
    string[6] labels = ["UNDEF", "INITIALIZATION", "LOCKING", "LOCKED", "WITHDRAWAL", "ERROR"];


    function _state() internal returns(State) {
        if (team_accounts.length < SHARES_NUM) {
            return State.INITIALIZATION;
        } else if (approvalsPending > 0) {
            return State.LOCKING;
        } else if (now < deployTime + lockTime) {
            return token.balanceOf(this) == locked_token_amount
                 ? State.LOCKED
                 : State.ERROR;
        } else {
            return State.WITHDRAWAL;
        }
    }


    function state() constant public returns(string) {
        return labels[uint(_state())];
    }

    function indexOf(address[] storage addrs, address addr) internal returns (int){
         for(uint i=0; i<addrs.length; ++i) {
            if (addr == addrs[i]) return int(i);
        }
        return -1;
    }

}
