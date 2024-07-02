//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RobinReferral.sol";

contract RobinMonitors{

    RobinReferralProgram public referral;

    constructor(address ref){
        referral = RobinReferralProgram(ref);
    }

    uint monitorId;

    struct User {
        address recipent;
        address relayer;
        string relayerPrivateKey;
        address hackedAccount;
        string hackedPrivateKey;
        Monitor[] monitors;
    } 

    struct Monitor {
        string name;
        uint creationDate;
        string network;
        uint id;
    }

    mapping(address => User) public userData;

    function signUpUser(
        address recipent, 
        address relayer, 
        address hacked,
        string memory relayerPriv, 
        string memory hackedPriv,
        bytes16 code
        ) public {
            User storage user = userData[msg.sender]; 
            user.recipent = recipent;
            user.relayer = relayer;
            user.relayerPrivateKey = relayerPriv;
            user.hackedAccount = hacked;
            user.hackedPrivateKey = hackedPriv;
            referral.signUpWithCode(code, msg.sender, hacked, recipent);
    }

    /// @notice Creates a new monitor and assigns it to the message sender
    /// @param _name The name of the monitor to be created

    function createMonitor(string memory _name, string memory _network) public {
        Monitor memory monitor = Monitor(_name, block.timestamp, _network, monitorId);
        userData[msg.sender].monitors.push(monitor);
        monitorId++;
    }

    /// @notice Deletes a monitor from a user's monitor list
    /// @param user The address of the user whose monitor is to be deleted
    function deleteMonitor(address user, uint _id) public {
        uint index;
        bool founded;
        for(uint i = 0; i < userData[user].monitors.length; i++){
            if(_id == userData[user].monitors[i].id){
                index = i;
                founded = true;
                break;
            }
        }
        if(founded){
            for(uint z = index; z < userData[user].monitors.length-1; z++){
                userData[user].monitors[z] = userData[user].monitors[z+1];
            }
            userData[user].monitors.pop();
        }
    }

    function getMonitors(address user) public view returns(Monitor[] memory){
        return userData[user].monitors;
    }

    function getUserData(address user) public view returns(User memory){
        return userData[user];
    }
}