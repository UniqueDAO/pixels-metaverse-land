const fs = require("fs");
const chalk = require("chalk");

const pmlGraphDir = "../pml-subgraph";
const pmGraphDir = "../pm-subgraph";
const deploymentsDir = "./deployments";
const pmlContractsName = ["PMLandPawnshop", "PMLand", "PMLandMint"]

function publishContract(contractName: any, networkName: any) {
  let data = fs
    .readFileSync(`${deploymentsDir}/${networkName}/${contractName}.json`)
    .toString();
  let chainId = fs
    .readFileSync(`${deploymentsDir}/${networkName}/.chainId`)
    .toString();

  let contract = JSON.parse(data);
  const graphDir = pmlContractsName.includes(contractName) ? pmlGraphDir : pmGraphDir;
  const graphConfigPath = `${graphDir}/networks.json`;
  let graphConfig;
  try {
    if (fs.existsSync(graphConfigPath)) {
      graphConfig = fs.readFileSync(graphConfigPath).toString();
    } else {
      graphConfig = "{}";
    }
  } catch (e) {
    console.log(e);
  }

  graphConfig = JSON.parse(graphConfig);
  if (!(networkName in graphConfig)) {
    graphConfig[networkName] = {};
  }
  if (!(contractName in graphConfig[networkName])) {
    graphConfig[networkName][contractName] = {};
  }
  graphConfig[networkName][contractName].address = contract.address;

  fs.writeFileSync(graphConfigPath, JSON.stringify(graphConfig, null, 2));
  if (!fs.existsSync(`${graphDir}/abis`)) fs.mkdirSync(`${graphDir}/abis`);
  fs.writeFileSync(
    `${graphDir}/abis/${networkName}_${contractName}.json`,
    JSON.stringify(contract.abi, null, 2)
  );

  return ({
    "contractName": contractName,
    "chainId": chainId,
    "address": contract.address,
    "netName": networkName
  })
}

async function main() {
  const directories = fs.readdirSync(deploymentsDir);
  const abis: any = [];
  directories.forEach(function (directory: any) {
    const files = fs.readdirSync(`${deploymentsDir}/${directory}`);
    files.forEach(function (file: any) {
      if (file.indexOf(".json") >= 0) {
        const contractName = file.replace(".json", "");
        const item = publishContract(contractName, directory);
        abis.push(item);
      }
    });
  });
  fs.writeFileSync(
    `deploy-contracts.json`,
    `${JSON.stringify(abis, null, 4)}`
  );
  console.log("✅ The file is generated successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
