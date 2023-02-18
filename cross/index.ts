const deployContractsData = require("../deploy-contracts.json");
const config = require("./config.ts");
import { task } from "hardhat/config";

task("cross", "NFT Cross Chain Task")
    .addOptionalParam("to", "To Network")
    .addOptionalParam("ids", "Cross Chain ID example 1 or 1,2,3")
    .addOptionalParam("type", "action type")
    .addOptionalParam("nonce", "cross-chain nonce")
    .addOptionalParam("receiver", "user address")
    .addOptionalParam("users", "helpCrossChain users")
    .setAction(async (taskArgs, { network, ethers }: any) => {
        const { BigNumber } = ethers;
        const signers = await ethers.getSigners();
        const deployer = signers[0];
        const deployContracts = {};
        const deployContractData = deployContractsData.filter(item => item.netName === network.name);

        const networks = config.network;
        const landMintNetwork = config.landMintNetwork[network.name?.includes("test") ? "testnet" : "mainnet"];
        const contractName = (net) => net === landMintNetwork ? "PMLandMint" : "PMLand";
        const toData = deployContractsData.filter(item => item.netName === taskArgs.to && item?.contractName === contractName(taskArgs.to));
        const URLS = {
            testnet: 'https://api-testnet.layerzero-scan.com',
            mainnet: 'https://api-mainnet.layerzero-scan.com',
            sandbox: 'https://api-sandbox.layerzero-scan.com',
        };

        for (let i = 0; i < deployContractData.length; i++) {
            const item = deployContractData[i];
            const factory = await ethers.getContractFactory(item.contractName);
            const c = await factory.attach(item.address);
            deployContracts[item.contractName] = {
                contract: c,
                ...item
            };
        };

        const dstCrossChainData = networks[taskArgs.to];
        const srcCrossChainData = networks[network.name];

        if (!dstCrossChainData) {
            console.log("Cross Chain Error");
            return
        }

        let EndpointABI = [
            "function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external",
            "function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) view returns(bool)"
        ];

        const EndpointContractFactory = new ethers.Contract(srcCrossChainData.endpoint, EndpointABI, deployer);
        const EndpointContract = await EndpointContractFactory.attach(srcCrossChainData.endpoint);

        const contract = deployContracts[contractName(network?.name)];
        const LandContract = contract?.contract;
        let dstChainId = BigNumber.from(dstCrossChainData.chainId);
        const trustedRemote = await LandContract.trustedRemoteLookup(dstChainId);
        const dstTrustedRemote = ethers.utils.solidityPack(
            ['address', 'address'],
            [toData[0].address, contract.address]
        )

        const srcTrustedRemote = ethers.utils.solidityPack(
            ['address', 'address'],
            [contract.address, toData[0].address]
        )

        const isSetTrustedRemote = dstTrustedRemote?.toLowerCase() === trustedRemote?.toLowerCase();
        const output = {
            account: `${srcCrossChainData.blockscan}/address/${deployer.address}`,
            fromChain: {
                chainId: srcCrossChainData.chainId,
                endpoint: `${srcCrossChainData.blockscan}/address/${srcCrossChainData.endpoint}`,
                land: `${srcCrossChainData.blockscan}/address/${LandContract.address}`,
                network: network.name
            },
            toChain: {
                chainId: dstCrossChainData.chainId,
                endpoint: `${dstCrossChainData.blockscan}/address/${dstCrossChainData.endpoint}`,
                land: `${dstCrossChainData.blockscan}/address/${toData[0].address}`,
                network: toData[0].netName,
                trustedRemote,
            },
            ids: taskArgs.ids,
        }
        console.log(output);

        let ids = taskArgs?.ids?.split(",") || [], res, asstes, payload;
        const receiver = taskArgs.receiver || deployer.address;

        switch (taskArgs.type) {
            case "mint":
                res = await LandContract.mint(receiver, ids, {
                    value: ethers.utils.parseEther("0.1024").mul(ids.length)
                });
                break;
            case "trust":
                if (!isSetTrustedRemote) {
                    await LandContract.setTrustedRemote(dstChainId, dstTrustedRemote);
                } else {
                    console.log("seted")
                    return
                }
                break;
            case "approve":
                if (taskArgs?.ids) {
                    await LandContract.approve(LandContract.address, taskArgs?.ids);
                } else {
                    await LandContract.setApprovalForAll(LandContract.address, true);
                }
                break;
            case "allow":
                await LandContract.allowCrossChain(dstChainId, ids, {
                    value: ethers.utils.parseEther("0.1").mul(ids.length)
                });
                break;
            case "help":
                // const owner = "0x5835450b4ba9ff89ca27b0040f971e1c3dd3192b";
                // const owner2 = "0xccbd6503c856a086e7202a2646fcf4dee79e181d"

                const users = taskArgs?.users?.split(",") || [];
                asstes = [];
                let length = 0;
                for (let i = 0; i < users.length; i++) {
                    const asset = await LandContract._queue(dstChainId, users[i]);
                    const len = Number((BigInt(asset.toString()) >> 250n).toString());
                    length += len;
                    asstes.push({
                        owner: users[i],
                        ids: new Array(len).fill(len)
                    })
                }

                let _adapterParams = ethers.utils.solidityPack(
                    ['uint16', 'uint256'],
                    [1, 200000 + users.length * 20000 + length * 30000]
                )
                const _fees = await LandContract.estimateFees(
                    dstChainId,
                    toData[0].address,
                    asstes,
                    _adapterParams);
                const _fee = ethers.utils.formatEther(_fees.toString());

                if (Number(_fee) > 0.01) {
                    console.log("pause cross chain", _fee)
                    return
                }

                res = await LandContract.helpCrossChain(dstChainId, users, _adapterParams, {
                    value: ethers.utils.parseEther(_fee)
                });
            case "cross":
                asstes = {
                    owner: receiver,
                    ids
                }
                let adapterParams = ethers.utils.solidityPack(
                    ['uint16', 'uint256'],
                    [1, ids.length * 30000 + 200000]
                )
                const fees = await LandContract.estimateFees(
                    dstChainId,
                    toData[0].address,
                    [asstes],
                    adapterParams);
                const fee = ethers.utils.formatEther(fees.toString());

                if (Number(ethers.utils.formatEther(fees.toString())) > 0.01) {
                    console.log("pause cross chain", fee)
                    return
                }

                res = await LandContract.selfCrossChain(receiver, dstChainId, ids, adapterParams, {
                    value: fees
                });
                break;
            case "retryPayload":
                asstes = {
                    owner: deployer.address,
                    ids
                }
                payload = await LandContract.getPayload(asstes);
                // console.log(payload)
                // return
                await EndpointContract.retryPayload(dstChainId, dstTrustedRemote, payload);
                break;
            case "payload":
                const isHasPayload = await EndpointContract.hasStoredPayload(dstChainId, dstTrustedRemote);
                console.log(isHasPayload);
                break;
            case "force":
                await LandContract.forceResumeReceive(dstChainId, dstTrustedRemote);
                break;
            case "fail":
                const failedMessages = await LandContract.failedMessages(dstChainId, dstTrustedRemote, taskArgs.nonce || 0);
                console.log(failedMessages);
                break;
            case "retryMessage":
                asstes = {
                    owner: deployer.address,
                    ids
                }
                payload = await LandContract.getPayload(asstes);
                // console.log(payload)
                // return
                await LandContract.retryMessage(dstChainId, dstTrustedRemote, taskArgs.nonce || 0, payload);
                break;
            default:
                console.log(`❌ type: ${taskArgs.type}, type error`);
                return
        }
        if (res && ["cross", "help"].includes(taskArgs.type)) {
            console.log(`${dstCrossChainData.chainId > 1000 ? URLS["testnet"] : URLS["mainnet"]}/tx/${res.hash}`)
            console.log(`${srcCrossChainData.blockscan}/tx/${res.hash}`)
        } else {
            res && console.log(`${srcCrossChainData.blockscan}/tx/${res.hash}`)
        }
        console.log(`✅ ${taskArgs.type} success`);
    });