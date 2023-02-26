// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IManage.sol";

interface IPixelsMetaverseLand {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IPMTManage is IManage {
    function getUser(address user) external view returns (UserStruct memory);

    function getLandTypes(uint256 land) external view returns (uint256);

    function getLandArea(uint256 land, uint256 area)
        external
        view
        returns (IDToAreaStruct memory);

    function getArea(address area) external view returns (AreaStruct memory);
}

contract PixelsMetaverse is ERC1155 {
    address private _manage;
    uint256 private _id;
    uint256 private _copyID;

    mapping(bytes32 => uint256) private _dataOwner;
    event DataOwnerEvent(address indexed owner, bytes32 dataBytes);

    struct ItemStruct {
        uint256 id;
        uint256 afterAmount;
        uint256 beforeAmount;
    }
    struct ComposesStruct {
        uint256 srcID;
        uint256 dstID;
    }
    mapping(uint256 => ComposesStruct) private _composes;
    event ComposeEvent(uint256 dstID, ItemStruct[] list, bool composed);

    mapping(uint256 => MaterialStruct) private _materials;
    struct MaterialStruct {
        address owner;
        bytes32 dataBytes;
        bool pauseMint;
        bool allowedCompose;
    }
    event MaterialEvent(
        address indexed to,
        uint256 id,
        uint256 quantity,
        string rawData,
        bytes32 dataBytes
    );

    event ConfigEvent(
        uint256 id,
        string name,
        string time,
        string position,
        string zIndex,
        string decode,
        uint256 sort,
        bool copy
    );

    function getMaterial(uint256 id)
        public
        view
        returns (MaterialStruct memory m)
    {
        return _materials[id];
    }

    modifier Owner(uint256 id, address sender) {
        require(sender == _materials[id].owner, "Only the owner");
        _;
    }

    constructor(address manage) ERC1155("") {
        _manage = manage;
    }

    function setOwner(uint256 id, address to) public Owner(id, msg.sender) {
        _materials[id].owner = to;
    }

    function allowedCompose(uint256 id) public Owner(id, msg.sender) {
        _materials[id].allowedCompose = true;
    }

    function pauseMint(uint256 id) public Owner(id, msg.sender) {
        _materials[id].pauseMint = true;
    }

    function setConfig(
        uint256 id,
        string memory name,
        string memory time,
        string memory position,
        string memory zIndex,
        string memory decode,
        uint256 sort,
        bool copy
    ) public {
        if (copy) {
            uint256 dstID = _composes[id].dstID;
            uint256 dstDstID = _composes[dstID].srcID;
            require(dstDstID == 0, "The item must not have been synthesized");
        } else {
            require(msg.sender == _materials[id].owner, "Only the owner");
        }
        // https://blog.csdn.net/weixin_39430411/article/details/123154579 gas optimize
        emit ConfigEvent(id, name, time, position, zIndex, decode, sort, copy);
    }

    function _make(
        address to,
        uint256 id,
        uint256 quantity,
        string memory rawData,
        bytes32 dataBytes
    ) private {
        _mint(to, id, quantity, "");
        emit MaterialEvent(to, id, quantity, rawData, dataBytes);
    }

    function make(
        string memory name,
        string memory rawData,
        string memory time,
        string memory position,
        string memory zIndex,
        string memory decode,
        uint256 quantity
    ) public {
        if (quantity > 0) {
            bytes32 d = keccak256(abi.encodePacked(rawData));
            require(_dataOwner[d] == 0, "This data already has an owner");

            _make(msg.sender, _id, quantity, rawData, d);
            _dataOwner[d] = _id;
            emit ConfigEvent(
                _id,
                name,
                time,
                position,
                zIndex,
                decode,
                0,
                false
            );
            _materials[_id] = MaterialStruct(msg.sender, d, false, false);
            _id++;
        }
    }

    function reMake(
        address to,
        uint256 id,
        uint256 quantity
    ) private Owner(id, msg.sender) {
        require(quantity > 0, "The quantity must be greater than 0");
        bytes32 d = _materials[id].dataBytes;
        require(_dataOwner[d] == id, "Only the owner");
        _make(to, id, quantity, "", "");
    }

    function _compose(ItemStruct[] memory list, bool isCompose)
        private
        returns (bytes32 dataBytes)
    {
        uint256 len = list.length;
        require(len > 1);
        uint256 copyID = _copyID;

        for (uint256 i; i < len; i++) {
            ItemStruct memory itemBefore = i == 0 ? list[i] : list[i - 1];
            ItemStruct memory item = list[i];
            bytes32 d = _materials[item.id].dataBytes;
            uint256 l = item.afterAmount + copyID;
            if (i > 0) require(item.id > itemBefore.id);

            dataBytes = dataBytes ^ (d >> item.afterAmount);
            if (isCompose) {
                _safeTransferFrom(
                    msg.sender,
                    address(this),
                    item.id,
                    item.afterAmount,
                    ""
                );
            } else {
                _safeTransferFrom(
                    address(this),
                    msg.sender,
                    item.id,
                    item.afterAmount,
                    ""
                );
            }

            for (copyID; copyID < l; copyID++) {
                _composes[copyID] = ComposesStruct(_id, item.id);
            }
        }
        if (isCompose) _copyID = copyID;
    }

    function compose(
        ItemStruct[] memory list,
        string memory name,
        string memory time,
        string memory position,
        string memory zIndex,
        string memory decode
    ) public {
        bytes32 dataBytes = _compose(list, true);
        uint256 dataID = _dataOwner[dataBytes];
        require(dataID == 0);

        _dataOwner[dataBytes] = _id;
        _make(msg.sender, _id, 1, "", dataBytes);
        _materials[_id] = MaterialStruct(msg.sender, dataBytes, false, false);
        emit ConfigEvent(_id, name, time, position, zIndex, decode, 0, false);
        emit ComposeEvent(_id, list, true);
        _id++;
    }

    function decompose(uint256 dstID, ItemStruct[] memory list)
        public
        Owner(dstID, msg.sender)
    {
        bytes32 dataBytes = _compose(list, false);
        uint256 dataID = _dataOwner[dataBytes];

        require(dataID == dstID);
        _burn(msg.sender, dstID, 1);

        emit ComposeEvent(dstID, list, false);
    }

    function increaseOrDecrease(uint256 dstID, ItemStruct[] memory list)
        public
        Owner(dstID, msg.sender)
    {
        uint256 len = list.length;
        bytes32 beforeDataBytes;
        bytes32 afterDataBytes;
        uint256 copyID = _copyID;

        for (uint256 i; i < len; i++) {
            ItemStruct memory itemBefore = i == 0 ? list[i] : list[i - 1];
            ItemStruct memory item = list[i];
            bytes32 d = _materials[item.id].dataBytes;
            uint256 l = item.afterAmount + copyID;
            if (i > 0) require(item.id > itemBefore.id);

            beforeDataBytes = beforeDataBytes ^ (d >> item.beforeAmount);
            afterDataBytes = afterDataBytes ^ (d >> item.afterAmount);
            bool isAdd = item.beforeAmount < item.afterAmount;
            if (isAdd) {
                _safeTransferFrom(
                    msg.sender,
                    address(this),
                    item.id,
                    item.afterAmount - item.beforeAmount,
                    ""
                );
            }
            if (isAdd && item.beforeAmount != item.afterAmount) {
                _safeTransferFrom(
                    address(this),
                    msg.sender,
                    item.id,
                    item.beforeAmount - item.afterAmount,
                    ""
                );
            }

            for (copyID; copyID < l; copyID++) {
                _composes[copyID] = ComposesStruct(_id, item.id);
            }
        }

        uint256 dataID = _dataOwner[afterDataBytes];
        if (dataID == 0) {
            _dataOwner[afterDataBytes] = _id;
            _make(msg.sender, _id, 1, "", afterDataBytes);
            _id++;
        }

        MaterialStruct memory m = _materials[dataID];
        require(m.owner == msg.sender);
        if (beforeDataBytes == afterDataBytes) {
            _dataOwner[afterDataBytes] = 0;
            delete _composes[dstID];
        }
    }
}
