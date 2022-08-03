const { expect, use } = require("chai");
const { ethers, waffle } = require("hardhat");

use(waffle.solidity);

describe("Timelock", () => {
  /**
   * @type import('ethers').Contract
   */
  let timelock;

  before(async () => {
    const TimelockFactory = await ethers.getContractFactory("Factory");
    const [, signer2] = await ethers.getSigners();

    timelock = await TimelockFactory.deploy(signer2.address);
    timelock = await timelock.deployed();
  });

  it("should lock ethers for later", async () => {
    const [signer1, signer2] = await ethers.getSigners();
    await expect(
      timelock._lockEtherForLater(Math.floor(Date.now() / 1000) + 60 * 5, signer2.address, {
        from: signer1.address,
        value: ethers.utils.parseEther("4000")
      })
    ).to.emit(timelock, "TimelockObjectCreated");
  });

  it("should revert if lock time is less than 5 minutes", async () => {
    const [signer1, signer2] = await ethers.getSigners();
    await expect(
      timelock._lockEtherForLater(Math.floor(Date.now() / 1000) + 60, signer2.address, {
        from: signer1.address,
        value: ethers.utils.parseEther("0.002")
      })
    ).to.be.revertedWith("difference between lock time and current block time should be at least 5 minutes");
  });

  it("should proceed with transaction", async () => {
    const [signer1] = await ethers.getSigners();
    const timelockID = await timelock._allTimelocks(0);
    await expect(timelock._proceedWithTx(timelockID, { from: signer1.address }))
      .to.emit(timelock, "TimelockProcessed")
      .withArgs(timelockID);
  });
});
