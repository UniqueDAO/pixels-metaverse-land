module.exports = async ({ getNamedAccounts, deployments }: { getNamedAccounts: any, deployments: any }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("Deployer:", deployer);

  const PixelsMetaverse = await deploy("PixelsMetaverse", {
    from: deployer,
    args: [deployer],
    log: true,
  });

  console.log("PixelsMetaverse:", PixelsMetaverse.address);
};

module.exports.tags = ["PixelsMetaverse"];