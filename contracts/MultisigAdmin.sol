pragma solidity ^0.4.11;

contract CallApprover {
    function approved(bytes msg_data, address caller) returns (bool);
    //function approved(bytes4 callSig) returns (bool);
}

contract MultisigAdmin is CallApprover {
    address public target;
    uint constant WAIT_TIME_ONE_VOTE = 1 days;

    function MultisigAdmin(address _target) {
        target = _target;
        addr_userId[msg.sender]= ++userIdCount;
    }

    struct Voting {
        uint quorumNum;
        uint startedOn;
        mapping(uint => int8) voted; // voterId => vote?
        int votum;
    }

    mapping(address=>uint) addr_userId;
    uint userIdCount = 0;

    mapping(bytes=>Voting) voting;

    //prime the data using the fallback function.
    function() {
        if (approved(msg.data, msg.sender)) {
            target.call(msg.data);
        }
    }

    function getUnlockTime(Voting storage v) internal returns (uint){
        return (2 ** uint(int(v.quorumNum) - v.votum) - 1) * WAIT_TIME_ONE_VOTE;
    }

    function approved(bytes msg_data, address caller) returns(bool){
        Voting v=voting[msg_data];
        if (v.startedOn==0) {
            voting[msg_data] = Voting({
                quorumNum : userIdCount,
                startedOn : now,
                votum : 0
            });
            return false;
        } else {
            var userId = addr_userId[caller];
            var oldvote = v.voted[userId];
            if (oldvote<=0) v.votum += int8(1) - oldvote;
            return (now > getUnlockTime(v));
        }
    }

    event log(uint);

}


contract Target {

    event log(string);

    function helloWorld(string s){
        log(s);
    }

}

contract User {
    address target = new Target();
    address admin = new MultisigAdmin(target);

    function test() {
        Target(admin).helloWorld("Hello!");
    }
}
