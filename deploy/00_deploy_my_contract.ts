const config = require("../cross/config.ts");

module.exports = async ({ getNamedAccounts, deployments }: { getNamedAccounts: any, deployments: any }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const network = config.network;

  let net = "hardhat";
  for (let i = 0; i < process?.argv?.length; i++) {
    const arg = process.argv[i]
    if (arg === "--network") {
      net = process?.argv[i + 1];
    }
  }
  const blockscan = config.network[net].blockscan + "/address/";

  console.log("Deployer:", blockscan + deployer);

  if (net === config.landMintNetwork[net?.includes("test") ? "testnet" : "mainnet"]) {
    const LandPawnshop = await deploy("PMLandPawnshop", {
      from: deployer,
      args: [],
      log: true
    });
    console.log("LandPawnshop:", blockscan + LandPawnshop.address);

    const LandMint = await deploy("PMLandMint", {
      from: deployer,
      args: [network[net].endpoint, LandPawnshop.address, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]],
      log: true,
    });
    console.log("LandMint:", blockscan + LandMint.address);
  } else {
    const Land = await deploy("PMLand", {
      from: deployer,
      args: [network[net].endpoint],
      log: true,
    });
    console.log("Land:", blockscan + Land.address);
  }
};

module.exports.tags = ["PMLand"];