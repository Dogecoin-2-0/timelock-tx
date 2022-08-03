const { ethers, network } = require("hardhat");

async function deploy() {
  console.log("Now deploying on ", network.name);
  const Factory = await ethers.getContractFactory("Factory");
  let factory = await Factory.deploy("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578");
  factory = await factory.deployed();

  console.log("Contract deployed on address ", factory.address);
}

(async () => {
  await deploy();
})();
