// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
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
    address private _minter;
    using Counters for Counters.Counter;
    Counters.Counter public _currentID;
    mapping(uint256 => address) private ownerOf;

    modifier Minter() {
        require(msg.sender == _minter, "You don't have permission to make it");
        _;
    }

    address private _manage;
    uint256 private _materialId;

    mapping(address => address) private _PMT721Minter;
    event PMT721Event(
        address indexed pmt721,
        address indexed minter,
        string name,
        string desc
    );
    mapping(bytes32 => address) private _dataOwner;
    event DataOwnerEvent(address indexed owner, bytes32 dataBytes);

    struct PMTStruct {
        address pmt721;
        uint256 pmt721_id;
    }
    mapping(uint256 => PMTStruct) private _materialIdToPmt721;
    mapping(address => mapping(uint256 => uint256)) private _composes;

    mapping(address => mapping(uint256 => bytes32)) private _materials;
    mapping(address => mapping(uint256 => PMTStruct)) private _acrosss;

    event MaterialEvent(
        address indexed from,
        address indexed to,
        address indexed pmt721,
        uint256 pmt721_id,
        uint256 dataID,
        uint256 configID,
        string rawData,
        bool remake,
        uint256 quantity
    );

    event ConfigEvent(
        uint256 id,
        string name,
        string time,
        string position,
        string zIndex,
        string decode,
        uint256 sort
    );

    event ComposeEvent(PMTStruct toItem, PMTStruct[] list, bool isAdd);

    function getMaterial(address pmt721, uint256 pmt721_id)
        public
        view
        returns (bytes32 d)
    {
        /* uint256 curr = pmt721_id;
        uint256 _currentIndex = IPMT721(pmt721).currentID();
        if (curr < _currentIndex) {
            d = _materials[pmt721][curr];
            while (d == 0) {
                d = _materials[pmt721][--curr];
            }
        } */
    }

    modifier Owner(uint256 id, address sender) {
        require(sender == ownerOf[id], "Only the owner");
        _;
    }

    modifier isMint(address pmt721, uint256 quantity) {
        /* UserStruct memory u = _users[msg.sender];
        address area = address(uint160(_lands[u.land][u.area]));
        require(area == pmt721, "You don't have permission to set it");
        AreaStruct memory a = _areas[area];
        require(
            a.timeMeal <= block.timestamp,
            "You don't have permission to set it"
        );
        require(
            u.todayOutput + quantity <= u.output,
            "You don't have permission to set it"
        ); */
        _;
    }

    constructor(address manage) ERC1155("") {
        _manage = manage;
    }

    function setDataOwner(bytes32 dataBytes, address to) public {
        require(
            _dataOwner[dataBytes] == msg.sender,
            "You don't have permission to set it"
        );
        _dataOwner[dataBytes] = to;
        emit DataOwnerEvent(msg.sender, dataBytes);
    }

    /* function setConfig(
        uint256 id,
        string memory name,
        string memory time,
        string memory position,
        string memory zIndex,
        string memory decode,
        uint256 sort
    ) public Owner(id, msg.sender) {
        uint256 materialId = _composes[pmt721][pmt721_id];
        PMTStruct memory p = _materialIdToPmt721[materialId];
        uint256 materialId1 = _composes[p.pmt721][p.pmt721_id];
        require(materialId1 == 0, "The item must not have been synthesized");
        emit ConfigEvent(
            _currentID.current(),
            name,
            time,
            position,
            zIndex,
            decode,
            sort
        );
    } */

    function make(
        string memory name,
        string memory rawData,
        string memory time,
        string memory position,
        string memory zIndex,
        string memory decode,
        uint256 quantity
    ) public {
        require(quantity > 0, "The quantity must be greater than 0");

        bytes32 d = keccak256(abi.encodePacked(rawData));
        require(_dataOwner[d] == address(0), "This data already has an owner");
        _currentID.decrement();
        _make(_currentID.current(), rawData, d, quantity, msg.sender);

        _dataOwner[d] = msg.sender;
        emit ConfigEvent(
            _currentID.current(),
            name,
            time,
            position,
            zIndex,
            decode,
            0
        );
    }

    function _reMake(
        address to,
        uint256 id,
        uint256 quantity
    ) private {
        require(quantity > 0, "The quantity must be greater than 0");
        // bytes32 d = getMaterial(pmt721, pmt721_id);
        // require(_dataOwner[d] == msg.sender, "Only the owner");
        // uint256 _pmt721_id = IPMT721(toPmt721).currentID();
        // _make(id, "", d, quantity, to);
    }

    /* function reMake(
        address toPmt721,
        address pmt721,
        uint256 pmt721_id,
        uint256 quantity
    ) public isMint(toPmt721, quantity) Owner(pmt721, pmt721_id, msg.sender) {
        _reMake(toPmt721, pmt721, pmt721_id, quantity);
    } */

    /* function compose(
        PMTStruct[] memory list,
        string memory name,
        string memory time,
        string memory position,
        string memory zIndex,
        string memory decode
    ) public {
        uint256 len = list.length;
        require(len > 1, "The quantity must be greater than 1");
        emit ConfigEvent(
            _currentID.current(),
            name,
            time,
            position,
            zIndex,
            decode,
            0
        );

        PMTStruct memory p = PMTStruct(pmt721, pmt721_id);

        bytes32 dataBytes;

        for (uint256 i; i < len; i++) {
            PMTStruct memory temp = list[i];
            bytes32 d = getMaterial(temp.pmt721, temp.pmt721_id);
            dataBytes = dataBytes ^ d;
            _compose(_materialId + 1, temp, msg.sender);
        }
        emit ComposeEvent(p, list, true);
        require(
            _dataOwner[dataBytes] == address(0) ||
                _dataOwner[dataBytes] == msg.sender,
            "This data already has an owner"
        );
        _dataOwner[dataBytes] = msg.sender;
        _make(_currentID.current(), "", dataBytes, 1, msg.sender);
        _materialIdToPmt721[_materialId] = p;
    } */

    function _make(
        uint256 id,
        string memory rawData,
        bytes32 dataBytes,
        uint256 quantity,
        address to
    ) private {
        _mint(to, id, quantity, "");
        /* emit MaterialEvent(
            address(0),
            to,
            pmt721,
            pmt721_id,
            pmt721_id,
            pmt721_id,
            rawData,
            false,
            quantity
        ); */
    }

    /* function addition(uint256 materialId, PMTStruct[] memory list) public {
        PMTStruct memory c = _materialIdToPmt721[materialId];
        require(
            msg.sender == _PMT721Minter[c.pmt721] ||
                _PMT721Minter[c.pmt721] == address(this),
            "You don't have permission to edit it"
        );

        require(
            msg.sender == IPMT721(c.pmt721).ownerOf(c.pmt721_id),
            "Only the owner"
        );

        bytes32 dataBytes = getMaterial(c.pmt721, c.pmt721_id);
        uint256 material_id = _composes[c.pmt721][c.pmt721_id];
        require(material_id == 0, "The item must not have been synthesized");
        for (uint256 i; i < list.length; i++) {
            PMTStruct memory temp = list[i];
            bytes32 d1 = getMaterial(temp.pmt721, temp.pmt721_id);
            dataBytes = dataBytes ^ d1;
            _compose(materialId, list[i], msg.sender);
        }
        emit ComposeEvent(c, list, false);
        _dataOwner[dataBytes] = msg.sender;
        _materials[c.pmt721][c.pmt721_id] = dataBytes;
    }

    function _compose(
        uint256 materialId,
        PMTStruct memory item,
        address _sender
    ) private Owner(item.pmt721, item.pmt721_id, _sender) {
        uint256 material_id = _composes[item.pmt721][item.pmt721_id];
        require(material_id == 0, "this Material composed");
        _composes[item.pmt721][item.pmt721_id] = materialId;
    }

    function subtract(PMTStruct memory item, PMTStruct[] memory list)
        public
        Owner(item.pmt721, item.pmt721_id, msg.sender)
    {
        uint256 material_id = _composes[item.pmt721][item.pmt721_id];
        require(material_id == 0, "this Material composed");

        PMTStruct memory t = list[0];
        uint256 materialId = _composes[t.pmt721][t.pmt721_id];
        PMTStruct memory p = _materialIdToPmt721[materialId];
        require(
            p.pmt721_id == item.pmt721_id && p.pmt721 == item.pmt721,
            "error"
        );

        bytes32 dataBytes = getMaterial(item.pmt721, item.pmt721_id);
        uint256 len = list.length;

        if (len == 1) {
            bytes32 d1 = getMaterial(t.pmt721, t.pmt721_id);
            dataBytes = dataBytes ^ d1;
            delete _composes[t.pmt721][t.pmt721_id];
            delete _materialIdToPmt721[t.pmt721_id];
        } else {
            for (uint256 i = 1; i < len; i++) {
                PMTStruct memory temp = list[i];
                uint256 _material_id = _composes[temp.pmt721][temp.pmt721_id];
                require(
                    _material_id == materialId,
                    "The item was not synthesized into the ids"
                );

                bytes32 d2 = getMaterial(temp.pmt721, temp.pmt721_id);
                dataBytes = dataBytes ^ d2;
                delete _composes[temp.pmt721][temp.pmt721_id];
                delete _materialIdToPmt721[materialId];
            }
        }
        emit ComposeEvent(PMTStruct(address(0), 0), list, false);
    }

    function _getBytes(bytes32 dataBytes, PMTStruct memory temp)
        private
        view
        returns (bytes32)
    {
        bytes32 d1 = keccak256(abi.encodePacked(temp.pmt721, temp.pmt721_id));
        bytes32 d2 = getMaterial(temp.pmt721, temp.pmt721_id);
        return dataBytes ^ d1 ^ d2;
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
        }
        require(
            _PMT721Minter[msg.sender] != address(0),
            "Only PMT721 contract calls"
        );
        uint256 _material_id = _composes[msg.sender][pmt721_id];
        require(_material_id == 0, "The item must not have been synthesized");

        if (from != address(0)) {
            emit MaterialEvent(
                from,
                to,
                msg.sender,
                pmt721_id,
                0,
                0,
                "",
                false,
                quantity
            );
        }
    } */
}
