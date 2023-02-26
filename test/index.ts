import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

interface IAssets {
  owner: string,
  ids: number[]
}

describe("Test My Dapp", function () {
  let LandMintContract: Contract, LandPawnshopContract: Contract, LandContract: Contract, lzEndpointMock: Contract;
  let owner: SignerWithAddress, owner1: SignerWithAddress, ids: number[], chainId = 123;
  let PMT721Contract;
  let PMT7212Contract;

  let PMEContract;
  let LandETHContract;
  let ManageContract;
  let PixelsMetaverseContract: Contract;

  let AvaterContract;
  let PMT1, PMT2;
  let otherAccount = "0xf0A3FdF9dC875041DFCF90ae81D7E01Ed9Bc2033"

  it("Deploy Contract", async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    owner1 = signers[1];

    const PixelsMetaverse = await ethers.getContractFactory("PixelsMetaverse");
    //const Avater = await ethers.getContractFactory("Avater");
    //AvaterContract = await Avater.deploy();

    // const PME = await ethers.getContractFactory("PixelsMetaverseEnergy");
    // PMEContract = await PME.deploy();
    // await PMEContract.deployed();

    // const Manage = await ethers.getContractFactory("PixelsMetaverseDivision");
    // ManageContract = await Manage.deploy(LandETHContract.address, PMEContract.address);
    // await ManageContract.deployed();

    PixelsMetaverseContract = await PixelsMetaverse.deploy(owner.address);
    await PixelsMetaverseContract.deployed();
  });

  describe("PixelsMetaverseContract Call", async function () {
    it("PMT1制作2个虚拟物品0、1", async function () {
      await PixelsMetaverseContract.make("name", "rawData", "time", "position", "zIndex", "decode", 1024);
      // const material = await PixelsMetaverseContract.getMaterial(0);
      // const balances = await PixelsMetaverseContract.balanceOf(owner.address, 0);
      // console.log(balances.toString());
      // expect(material.owner).to.equal(owner.address);

      await PixelsMetaverseContract.make("name1", "rawData1", "time", "position", "zIndex", "decode", 2);
    });
  });
});