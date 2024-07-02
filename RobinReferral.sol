// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RobinReferralProgram {

    mapping(address => bytes16) internal userToCode;
    mapping(bytes16 => address) internal codeToUser;
    mapping(address => address) internal userReferrer;

    function createReferralCode() public {
        bytes16 code = bytes16(keccak256(abi.encode(msg.sender)));
        userToCode[msg.sender] = code;
        codeToUser[code] = msg.sender;
    }

    function signUpWithCode(bytes16 code, address user, address hackedAccount, address recipent) public {
        address referrer = codeToUser[code];
        userReferrer[user] = referrer;
        userReferrer[hackedAccount] = referrer;
        userReferrer[recipent] = referrer;
    }

    function getReferrer(address user) public view returns(address) {
        address referrer = userReferrer[user];
        return referrer;
    }

    function getMyCode(address user) public view returns(bytes16){
        return userToCode[user];
    }
}