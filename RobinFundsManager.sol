//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RobinReferral.sol";
import "./RobinMonitors.sol";
import "./RobinTokens.sol";
import "./RobinData.sol";

/// @title RobinFundManager Contract
/// @author Diego AVZ && Web3Software
/// @notice Smart Contract to transfer and distribute tokens from hacked accounts.
                               
contract RobinFundManager{

    using RobinLib for RobinLib.RecoveredTokens;

    // ⬇ CONSTRUCOR & MODIFIERS ⬇

    address internal owner;
    address internal robin;
    RobinReferralProgram public referral;
    RobinMonitors public monitor;
    RobinTokens public rToken;
    RobinData public data;

    /// @notice constructor initializes owner and robin addresses
    /// @param _owner contract owner address, the only address that can sign onlyOwner functions
    // @param _robin ,  Robin contract address, the only address that can sign onlyRobin functions
    ///
    constructor(address _owner, address _referral, address _monitor, address _tokens, address _data){
        owner = _owner;
        monitor = RobinMonitors(_monitor);
        referral = RobinReferralProgram(_referral);
        rToken = RobinTokens(_tokens);
        data = RobinData(_data);
        robinFee = 25;
    }

    /// @notice onlyRobin modify funcitons to control only owner or robin contract can call this functions
    modifier onlyRobin(){
        require(msg.sender == robin || msg.sender == owner, "OnlyRobin Alert - Error: You can not call this function");
        _;
    }

    /// @notice onlyRobin modify funcitons to control only owner can call this functions
    modifier onlyOwner(){
        require(msg.sender == owner, "OnlyOwner Alert - Error: You can not call this function");
        _;
    }

    // ⬆ CONSTRUCTOR & MODIFIERS ⬆
    // ----------------------
    // ⬇ VARIABLES ⬇

    uint internal robinFee = 20;
    uint internal referrerProfit = 100;
    uint internal price = 5000000000000000;

    mapping(address => bool) internal isNotFirstService;
    mapping(address => uint256) internal earnedEth;

    address e = 0x9C0305DF20F44408515f08EF24fCE19Cd36487cD;
    address d = 0x95EC54556c58e2B99Ca2b1085dd9D429E69827c1;
    address relayer = 0xcdee9691658dD50B9D0e203A8d51861435574e49;

    // ⬆ VARIABLES ⬆
    // ----------------------
    // ⬇ WRITTING FUNCTIONS ⬇

    /// transferTokens /////////////////////////////////////////////////////////////////////////////////////////|
    /// @notice This funciton trasnfer tokens from the hacked account and then disributes them ·················|
    /// @notice Robin charges a 25% fee ········································································|
    /// @dev Set hackedAccount with getHackedAccount() function with @param recipient ···························|
    /// @dev Set recipientAmount subtracting 25% RobinFee using @param amount ··································|
    /// @dev @param amount of @param token is transfered from the hackedAccount to this contract················|
    /// @dev 75% * @param amount of @param token is transfered to @param recipient ······························|
    /// @dev 25% * @param amount of @param token is transfered to Devs address ·································|
    /// @param token ERC20 token address to recover and distribute ·············································|
    /// @param recipient 75% of recovered tokens will be sent tu this account ···································|
    /// @param amount Amount of tokens recovered to distribute ·················································|
    /// @dev msg.sender must be robin Address ··································································|
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////|
    function transferTokens(address token, address recipient, address hackedAccount, uint amount) public onlyRobin{
        uint recipientAmount = amount - (amount*robinFee/100);
        isNotFirstService[hackedAccount] = true;
        isNotFirstService[recipient] = true;
        IERC20(token).transferFrom(hackedAccount, address(this), amount);
        IERC20(token).transfer(recipient, recipientAmount);
        IERC20(token).transfer(e, (amount - recipientAmount)/2);
        IERC20(token).transfer(d, (amount - recipientAmount)/2);
        registerTokens(hackedAccount, token, amount);
    }    

    function pay(address connectedAddress) public payable { // Reentrancy
        address referrer = referral.getReferrer(connectedAddress);
        uint ethToReferrer;
        if(!isNotFirstService[connectedAddress] && referrer != address(0)){
            require(msg.value == price - (price / 5), "Incorrect value for first service");
        } else {
            require(msg.value == price, "Incorrect value for service");
        }
        if(referrer != address(0)){
            ethToReferrer = msg.value / referrerProfit;
            monitor.addEarnedEther(ethToReferrer, referrer);
            earnedEth[referrer] += ethToReferrer;
        }
        (bool success2,) = payable(relayer).call{value: 1000000000000000}("");
        require(success2, "Failed Txs");
        monitor.setPayed(connectedAddress);
        uint256 amount = msg.value - (1000000000000000 + ethToReferrer);
        payable(e).transfer(amount/2);
        payable(d).transfer(amount/2);
    }

    function registerTokens(address hacked, address token, uint256 amount) public {
        (string memory symbol,,) = data.tokens(rToken.searchToken(token));
        RobinLib.RecoveredTokens memory recovery2 = RobinLib.RecoveredTokens(token,symbol,amount);
        uint256 len = monitor.getConnectedFromHacked(hacked).length;
        for(uint i = 0; i < len; i++){
            address connectedAddress = monitor.getConnectedFromHacked(hacked)[i];
            data.registerTokens(connectedAddress, recovery2);
        }
        data.countTokensRecovered(amount,token);
    }

    function claimReferrerProfit(address connectedAddress) public {
        require(earnedEth[connectedAddress] > 0, "No Eth earned");
        uint256 amount = earnedEth[connectedAddress];
        earnedEth[connectedAddress] = 0;
        payable(connectedAddress).transfer(amount);
    }

    function setRobin(address _robin) public onlyOwner{
        robin = _robin;
    }

     function setRobinFee(uint fee) public onlyOwner{
        robinFee = fee;
    }

    function setPrice(uint _price) public onlyOwner{
        price = _price;
    }

    function setReferrerFee(uint fee) public onlyOwner{
        referrerProfit = fee;
    }

    // ⬆ WRITTING FUNCTIONS ⬆
    // ----------------------
    //   ⬇ VIEW FUNCTIONS ⬇

    function getPrice(address connectedAddress) public view returns(uint){
        uint _price;
        address referrer = referral.getReferrer(connectedAddress);
        if(!isNotFirstService[connectedAddress] && referrer != address(0)){
            _price = price - (price / 5);
        } else {
            _price = price;
        }
        return _price;
    }

    function getReferrerProfit(address connectedAddress) public view returns(uint256){
        return earnedEth[connectedAddress];
    }

    function getUserHistory(address connectedAddress) public view returns(RobinLib.RecoveredTokens[] memory){
        return data.getUserHistory(connectedAddress);
    }

    function getTotalRecoveries() public view returns(uint256){
        return data.totalRecoveries();
    }
}
