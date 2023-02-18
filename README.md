Pixels Metaverse Land: Supports LayerZero cross-chain land NFT, It is the cornerstone of Pixels Metaverse, around which all action takes place.

### 0. Set up the NFT distribution chain
Go to the [config](./cross/config.ts) page and set the name of the chain to which the NFT is issued
```
module.exports = {
    //The value of is the network that mint nft
    landMintNetwork: {
        mainnet: "polygon",
        testnet: "matictest" 
    },
```

### 1. Deploy Contract
```
yarn deploy --network ftmtest
yarn deploy --network matictest
```

After execution, the [deploy-contracts.json](./deploy-contracts.json) data will be updated.

### 2. You can configure multiple chains by setting trusted addresses. If several chains are deployed, you can configure several chains
```
yarn cross --network matictest --to ftmtest --type trust
yarn cross --network ftmtest --to matictest --type trust
```

### 3. NFT cross chain to the destination address
```
yarn cross --network matictest --to ftmtest --type cross --ids 0,1,2
or
yarn cross --network matictest --to ftmtest --type cross --ids 3,4 --receiver your_other_address
```

### 4. Wait a few minutes to check whether the target chain address is successfully cross-linked. If the cross-link is successful, you can cross-link the NFT of the target chain back.
```
yarn cross --network matictest --to ftmtest --type cross --ids 0
```