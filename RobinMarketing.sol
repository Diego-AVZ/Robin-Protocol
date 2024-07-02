// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RobinMarketing{

    address[] public influencers;

    function addInfluencers(address[] memory addresses) public {
        for (uint256 i = 0; i < addresses.length; i++){
            if(!isInLisControl(addresses[i])){
                influencers.push(addresses[i]);
            } 
        }
    }

    function isInLisControl(address influencer) public view returns(bool){
        for(uint i = 0; i < influencers.length; i++){
            if(influencers[i] == influencer){
                return true;
            }
        }
        return false;
    }

    function deleteInfluencer(address influencer) public {
        require(searchInfluencer(influencer) != 99999999999, "Not in Array");
        uint index = searchInfluencer(influencer);
        if(influencers.length > 1){
            for(uint i = index; i < influencers.length-1; i++){
                influencers[i] = influencers[i+1];
            }
            influencers.pop();
        } else {
            influencers.pop();
        }
    }

    function searchInfluencer(address influencer) public view returns(uint){
        for(uint i = 0; i < influencers.length; i++){
            if(influencers[i] == influencer){
                return i;
            }
        }
        return 99999999999;
    }

    function distributeEth() public {
        uint amount = address(this).balance / influencers.length;
        for(uint i = 0; i < influencers.length; i++){
            payable(influencers[i]).transfer(amount);
        }
    }
}