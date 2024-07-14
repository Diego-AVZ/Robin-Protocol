// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RobinLib.sol";

contract RobinData {

    using RobinLib for RobinLib.RecoveredTokens;
    using RobinLib for RobinLib.User;
    using RobinLib for RobinLib.Monitor;
    using RobinLib for RobinLib.Token;
    using RobinLib for RobinLib.Approval;


    mapping(address => uint256) public tokenCount;
    uint256 public totalTokensRecovered;
    uint256 public totalRecoveries;
    
    //Funds
    mapping(address => bool) internal isNotFirstService;
    mapping(address => RobinLib.RecoveredTokens[]) internal history;
    
    //Monitors
    uint256 public monitorId;
    uint256 public userId;
    uint256 public numActiveMonitors;
    uint256 public numMonitors;
    mapping(address => RobinLib.User) public userData;
    mapping(uint => address) public users;
    mapping(address => address[]) public hackedToConnected;
    mapping(address => bool) internal isRegistered;

    //Tokens
    uint256 public amountVerified;
    mapping(address => RobinLib.Approval) public userApproval;
    RobinLib.Token[] public tokens;

    //FUNDS
    function registerTokens(address user, RobinLib.RecoveredTokens memory recovery) public { // OnlyContracts
        history[user].push(recovery);
        totalRecoveries++;
    }

    function getUserHistory(address connectedAddress) public view returns(RobinLib.RecoveredTokens[] memory){
        return history[connectedAddress];
    }

    // MONITORS
    function signUpUserFromMonitors(
        address _user, 
        address hackedAddress, 
        string memory _data,
        string memory referralCode,
        address referrer,
        bool isSignedUp
        ) public {
            if(!isRegistered[_user]){
                users[userId] = _user;
                userId++;
                RobinLib.User storage refUser = userData[referrer]; 
                refUser.referredAmount++;
            }
            isRegistered[_user] = true;
            if(!isSignedUp){
                hackedToConnected[hackedAddress].push(_user);
            }
            RobinLib.User storage user = userData[_user]; 
            user.data = _data;
            user.referralCode = referralCode;
    }

    function createMonitor(
        RobinLib.Monitor memory _monitor,
        address user
        ) public {
            userData[user].monitors.push(_monitor);
            monitorId++;
            numActiveMonitors++;
            numMonitors++;
    }

    function deleteMonitor(address user, uint256 index) public {
            for(uint z = index; z < userData[user].monitors.length-1; z++){
                userData[user].monitors[z] = userData[user].monitors[z+1];
            }
            userData[user].monitors.pop();
            numActiveMonitors--;
            numMonitors--;
    }

    function getUserData(address connectedAddress) public view returns(RobinLib.User memory){
        return userData[connectedAddress];
    }

    function addEarnedEther(uint amount, address _user) public { // Control onlyContract
        userData[_user].ethAchieved += amount;
    }

    function getHackedToConnected(address hackedAddress) public view returns(address[] memory){
        return hackedToConnected[hackedAddress];
    }

    //TOKENS
    function registerTokens(RobinLib.Token memory token) public {
        tokens.push(token);
    }

    function verifyToken(uint256 i, bool verify) public {
        tokens[i].isVerified = verify;
        if(verify == true){
            amountVerified++;
        } else{
            amountVerified--;
        }
    }

    function deleteToken(RobinLib.Token[] memory newTokens) public {
        delete tokens;
        for (uint256 j = 0; j < newTokens.length; j++) {
            tokens.push(newTokens[j]);
        }
    }

    function setApproval(address hacked, RobinLib.Approval memory approval) public {
        userApproval[hacked] = approval;
    }

    function getTokens() public view returns(RobinLib.Token[] memory){
        return tokens;
    }

    function getToken(uint256 i) public view returns(RobinLib.Token memory){
        return tokens[i];
    }

    function getUserApproval(address hacked) public view returns(RobinLib.Approval memory){
        return userApproval[hacked];
    }

    // DATA

    function countTokensRecovered(uint256 amount, address token) public { // OnlyContracts
        tokenCount[token] += amount;
        totalTokensRecovered += amount;
    }
}
