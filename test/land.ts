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

  it("Deploy Contract", async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    owner1 = signers[1];

    const LayerZeroEndpointMock = await ethers.getContractFactory("LocalLZEndpoint")
    lzEndpointMock = await LayerZeroEndpointMock.deploy(chainId)

    const LandPawnshop = await ethers.getContractFactory("PMLandPawnshop");
    LandPawnshopContract = await LandPawnshop.deploy();
    await LandPawnshopContract.deployed();

    const LandMint = await ethers.getContractFactory("PMLandMint");
    LandMintContract = await LandMint.deploy(lzEndpointMock.address, LandPawnshopContract.address, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]);
    await LandMintContract.deployed();

    const Land = await ethers.getContractFactory("PMLand");
    LandContract = await Land.deploy(lzEndpointMock.address);
    await LandContract.deployed();

    await lzEndpointMock.setDestLzEndpoint(LandContract.address, lzEndpointMock.address)
    await lzEndpointMock.setDestLzEndpoint(LandMintContract.address, lzEndpointMock.address)

    await LandContract.setTrustedRemote(
      chainId,
      ethers.utils.solidityPack(["address", "address"], [LandMintContract.address, LandContract.address])
    )
    await LandMintContract.setTrustedRemote(
      chainId,
      ethers.utils.solidityPack(["address", "address"], [LandContract.address, LandMintContract.address])
    )

    await LandPawnshopContract.setPML(LandMintContract.address);
  });

  describe("LandPawnshopContract Call", async function () {
    ids = [24];
    it("Mint", async function () {
      let ids2 = [24, 25, 26, 27, 28, 29, 30, 31, 32];
      await LandMintContract.connect(owner1).mint(owner1.address, ids2, {
        value: ethers.utils.parseEther("0.1024").mul(ids2.length)
      });
      expect(await LandMintContract.ownerOf(24)).to.equal(owner1.address);
    });

    it("Refund", async function () {
      await LandMintContract.connect(owner1).setApprovalForAll(LandPawnshopContract.address, true);
      await LandPawnshopContract.connect(owner1).refund(owner1.address, ids);
      expect(await LandMintContract.connect(owner1).ownerOf(24)).to.equal(LandPawnshopContract.address);
    });

    it("Claim", async function () {
      await LandPawnshopContract.claim(owner.address, ids, {
        value: ethers.utils.parseEther(`${ids.length * 0.1024}`)
      });
      expect(await LandMintContract.ownerOf(24)).to.equal(owner.address);
    });

    // it("Withdraw", async function () {
    //   await LandPawnshopContract.withdraw();
    // });
  });

  let idsOwner1 = [27, 29, 28], idsOwner = [21, 22, 23, 20, 19, 18];
  describe("LandMintContract Call", async function () {
    it("setApprovalForAll", async function () {
      await LandMintContract.connect(owner1).setApprovalForAll(LandMintContract.address, true);
      await LandMintContract.setApprovalForAll(LandMintContract.address, true);
    });

    it("allowCrossChain", async function () {
      await LandMintContract.connect(owner1).allowCrossChain(chainId, idsOwner1, {
        value: ethers.utils.parseEther("0.0234").mul(idsOwner1.length)
      });

      await LandMintContract.allowCrossChain(chainId, idsOwner, {
        value: ethers.utils.parseEther("0.001").mul(idsOwner.length)
      });
    });

    it("helpCrossChain", async function () {
      const assets = [
        {
          owner: owner.address,
          ids: idsOwner,
        }, {
          owner: owner1.address,
          ids: idsOwner1,
        }
      ];
      const [adapterParams, fees] = await crossChainData(LandContract, LandMintContract, chainId, true, assets);
      await LandMintContract.helpCrossChain(chainId, assets.map(item => item.owner), adapterParams, {
        value: fees
      });
    });

    it("selfCrossChain", async function () {
      idsOwner = [4]; idsOwner1 = [25, 26]
      const assets = [
        {
          owner: owner.address,
          ids: idsOwner,
        }, {
          owner: owner1.address,
          ids: idsOwner1,
        }
      ];
      const [adapterParams, fees] = await crossChainData(LandContract, LandMintContract, chainId, true, [assets[0]]);
      await LandMintContract.selfCrossChain(owner.address, chainId, idsOwner, adapterParams, {
        value: fees
      });

      const [adapterParams1, fees1] = await crossChainData(LandContract, LandMintContract, chainId, true, [assets[1]]);
      await LandMintContract.connect(owner1).selfCrossChain(owner1.address, chainId, idsOwner1, adapterParams1, {
        value: fees1
      });
    });
  });
});

async function crossChainData(LandContract: Contract, LandMintContract: Contract, chainId: number, isMintContract: boolean, assets: IAssets[]) {
  let adapterParams = ethers.utils.solidityPack(
    ['uint16', 'uint256'],
    [1, 200000 + assets?.length * 30000 + (assets?.reduce((previousValue: number, currentValue: IAssets) => previousValue + currentValue.ids.length, 0)) * 50000]
  )
  let contract = isMintContract ? LandMintContract : LandContract;
  const fees = await contract.estimateFees(
    chainId,
    contract.address,
    assets,
    adapterParams);

  return [adapterParams, fees] as const
}