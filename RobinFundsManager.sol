//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RobinReferral.sol";
import "./RobinMonitors.sol";

/// @title RobinFundManager Contract
/// @author Diego AVZ && Web3Software
/// @notice Smart Contract to transfer and distribute tokens from hacked accounts.

contract RobinFundManager{

    // ⬇ CONSTRUCOR & MODIFIERS ⬇

    address internal owner;
    address internal robin;
    RobinReferralProgram public referral;
    RobinMonitors public monitor;

    /// @notice constructor initializes owner and robin addresses
    /// @param _owner contract owner address, the only address that can sign onlyOwner functions
    // @param _robin ,  Robin contract address, the only address that can sign onlyRobin functions
    ///
    constructor(address _owner, address _referral){
        owner = _owner;
        referral = RobinReferralProgram(_referral);
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

    uint internal robinFee;
    mapping(address => bool) internal isNotFirstService;

    // ⬆ VARIABLES ⬆
    // ----------------------
    // ⬇ WRITTING FUNCTIONS ⬇

    /// transferTokens /////////////////////////////////////////////////////////////////////////////////////////|
    /// @notice This funciton trasnfer tokens from the hacked account and then disributes them ·················|
    /// @notice Robin charges a 25% fee ········································································|
    /// @dev Set hackedAccount with getHackedAccount() function with @param recipent ···························|
    /// @dev Set recipientAmount subtracting 25% RobinFee using @param amount ··································|
    /// @dev @param amount of @param token is transfered from the hackedAccount to this contract················|
    /// @dev 75% * @param amount of @param token is transfered to @param recipent ······························|
    /// @dev 25% * @param amount of @param token is transfered to Devs address ·································|
    /// @param token ERC20 token address to recover and distribute ·············································|
    /// @param recipent 75% of recovered tokens will be sent tu this account ···································|
    /// @param amount Amount of tokens recovered to distribute ·················································|
    /// @dev msg.sender must be robin Address ··································································|
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////|
    function transferTokens(address token, address recipent, address hackedAccount, uint amount) public onlyRobin{
        uint recipentAmount = amount - (amount*robinFee/100);
        isNotFirstService[hackedAccount] = true;
        isNotFirstService[recipent] = true;
        IERC20(token).transferFrom(hackedAccount, address(this), amount);
        IERC20(token).transfer(recipent, recipentAmount);
        IERC20(token).transfer(0x9C0305DF20F44408515f08EF24fCE19Cd36487cD, amount - recipentAmount);
        IERC20(token).transfer(0x95EC54556c58e2B99Ca2b1085dd9D429E69827c1, amount - recipentAmount);
    }

    function setFee(uint fee) public onlyOwner{
        robinFee = fee;
    }

    function pay() public payable {
        uint price = 5000000000000000;
        address referrer;
        address account1 = monitor.getUserData(msg.sender).recipent;
        address account2 = monitor.getUserData(msg.sender).hackedAccount;
        if(!isNotFirstService[msg.sender] && !isNotFirstService[account1] && !isNotFirstService[account2]){
            referrer = referral.getReferrer(msg.sender);
            require(msg.value == price - (price / 5), "Incorrect value for first service");
        } else {
            require(msg.value == price, "Incorrect value for service");
        }
        if(referrer != address(0)){
            uint ethToReferrer = msg.value / 1000;
            (bool success,) = payable(referrer).call{value: ethToReferrer}("");
            require(success, "Failed Txs");
        }
    }

    function setRobin(address _robin) public onlyOwner{
        robin = _robin;
    }

    // ⬆ WRITTING FUNCTIONS ⬆
    // ----------------------
    //   ⬇ VIEW FUNCTIONS ⬇


} 