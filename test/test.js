const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

const sushiToken ="0x6B3595068778DD592e39A122f4f5a5cF09C90fE2";

  describe("Test", function () {
    it("Deployment",async function(){
      const SushiBar = await hre.ethers.getContractFactory("SushiBar");
      const sushibar = await SushiBar.deploy(sushiToken);
      expect(await sushibar.sushi()).to.equal(sushiToken);
    });
  });


