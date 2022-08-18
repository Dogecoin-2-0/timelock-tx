const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function deploy() {
  console.log("Now deploying on ", network.name);
  const Factory = await ethers.getContractFactory("Factory");
  let factory = await Factory.deploy("0xb69DB7b7B3aD64d53126DCD1f4D5fBDaea4fF578");
  factory = await factory.deployed();

  const location = path.join(__dirname, "../addresses.json");
  const fileExists = fs.existsSync(location);

  if (fileExists) {
    const buf = fs.readFileSync(location);
    const val = JSON.parse(buf.toString());
    const updatedVal = { ...val, [network.name]: factory.address };

    fs.writeFileSync(location, JSON.stringify(updatedVal, undefined, 2));
  } else {
    fs.writeFileSync(location, JSON.stringify({ [network.name]: factory.address }, undefined, 2));
  }

  console.log("Contract deployed on address ", factory.address);
}

(async () => {
  await deploy();
})();
