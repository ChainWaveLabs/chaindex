pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/FixedSupplyToken.sol";

contract TestFixedSupplyToken {
    FixedSupplyToken token = FixedSupplyToken(DeployedAddresses.FixedSupplyToken());

    function testInitialSupplyUsingDeployedContract() public {
        uint expected = 1000000;
        Assert.equal(token.totalSupply, expected, "total supply should equal 1000000 tokens");
    }

    function testOwnerInitialBalancer() public {
        uint expected = 1000000;
        Assert.equal(token.balanceOf(msg.sender), expected, "Token owner should have correct initial balance");
    }

    function testApprove() public {
        Assert.isTrue(token.approve(address(1), 450), "Token owner can approve");
    }
}