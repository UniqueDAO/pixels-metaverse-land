// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// slither and myth path
// import "/Users/hsiang/Desktop/mine/code/web3/pixels-metaverse-land/node_modules/@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
// import "/Users/hsiang/Desktop/mine/code/web3/pixels-metaverse-land/node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PMLand is ERC721, NonblockingLzApp {
    uint256 internal _price = 1;
    uint256 internal _totalSupply;

    mapping(uint16 => mapping(address => uint256)) public _queue;

    event CrossEvent(address from, uint16 chainId, uint256 asset);

    struct Assets {
        address owner;
        uint256[] ids;
    }

    constructor(
        address _endpoint
    ) payable ERC721("PMLand", "PML") NonblockingLzApp(_endpoint) {}

    modifier lock() {
        require(_price == 1, "LOCKED");
        _price = 0.1024 ether;
        _;
        _price = 1;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function allowCrossChain(
        uint16 _dstChainId,
        uint256[] calldata ids
    ) external payable lock {
        uint256 len = ids.length;
        require(len < 10, "Quantity over limit");

        uint256 asset = 0;
        unchecked {
            for (uint256 i = 0; i < len; ) {
                asset = _concatId(asset, ids[i]);
                ++i;
            }
            asset = (_dstChainId << 70) | asset;
        }
        uint160 beforeValue = uint160(_queue[_dstChainId][msg.sender]);
        if (beforeValue > 0) {
            _safeTransferETH(msg.sender, beforeValue);
        }
        _queue[_dstChainId][msg.sender] = _getAssets(len, asset, msg.value);
    }

    function _concatId(
        uint256 asset,
        uint256 id
    ) private pure returns (uint256) {
        return (asset << 10) | id;
    }

    function _getAssets(
        uint256 len,
        uint256 asset,
        uint256 value
    ) private pure returns (uint256) {
        return (len << 250) | (asset << 160) | value;
    }

    function helpCrossChain(
        uint16 _dstChainId,
        address[] memory users,
        bytes memory _adapterParams
    ) external payable lock {
        uint256 len = users.length;
        uint256[] memory _ids = new uint256[](len);
        uint160 payAmount = 0;
        uint256 amount = 0;

        unchecked {
            for (uint256 i = 0; i < len; ) {
                address owner = users[i];
                uint256 asset = _queue[_dstChainId][owner];
                require(asset > 0, "Not approved");
                uint256 idLen = (asset >> 250) * 10 + 160;
                amount += (asset >> 250);
                payAmount += uint160(asset);

                for (uint256 j = 160; j < idLen; ) {
                    uint256 id = uint16(asset >> j) & 1023;
                    require(
                        _isApprovedOrOwner(address(this), id),
                        "ERC721: token is not approved"
                    );

                    _transfer(owner, address(this), id);
                    j += 10;
                }
                _ids[i] = ((asset >> 160) << 160) | uint160(owner);
                emit CrossEvent(owner, _dstChainId, _ids[i]);
                _queue[_dstChainId][owner] = 0;
                ++i;
            }
        }
        _safeTransferETH(msg.sender, payAmount);

        // uint256 gasLimit = baseGas + (amount << 15) + (len << 14);
        // bytes memory _adapterParams = abi.encodePacked(uint16(1), gasLimit);
        bytes memory _payload = abi.encode(_ids);

        // test call
        // _nonblockingLzReceive(1, bytes(""), 1, _payload);

        uint256 fee = _estimateFees(_dstChainId, address(this), _payload, _adapterParams);
        require(fee <= msg.value, "Too little gas");

        _lzSend(
            _dstChainId,
            _payload,
            payable(msg.sender),
            address(this),
            _adapterParams,
            fee
        );
    }

    function selfCrossChain(
        address _receiver,
        uint16 _dstChainId,
        uint256[] calldata ids,
        bytes memory _adapterParams
    ) external payable lock {
        uint256 len = ids.length;
        require(len < 10, "Quantity over limit");
        uint256[] memory _ids = new uint256[](1);
        uint256 asset = 0;

        unchecked {
            for (uint256 i = 0; i < len; ) {
                uint256 id = ids[i];
                asset = _concatId(asset, id);
                require(
                    ownerOf(id) == msg.sender,
                    "ERC721: token is not approved"
                );

                _transfer(msg.sender, address(this), id);
                ++i;
            }
        }
        _ids[0] = _getAssets(len, asset, uint160(_receiver));
        bytes memory _payload = abi.encode(_ids);

        // test call
        // _nonblockingLzReceive(_dstChainId, _adapterParams, 1, _payload);

        _lzSend(
            _dstChainId,
            _payload,
            payable(msg.sender),
            address(this),
            _adapterParams,
            msg.value
        );
        emit CrossEvent(msg.sender, _dstChainId, _ids[0]);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        uint256[] memory assets = abi.decode(_payload, (uint256[]));

        uint256 len = assets.length;
        uint256 total = _totalSupply;
        unchecked {
            for (uint256 i = 0; i < len; ) {
                uint256 asset = assets[i];
                address receiver = address(uint160(asset));
                uint256 idLen = (asset >> 250) * 10 + 160;
                for (uint256 j = 160; j < idLen; ) {
                    uint256 id = uint16(asset >> j) & 1023;
                    if (_exists(id)) {
                        require(
                            ownerOf(id) == address(this),
                            "The current ID is abnormal"
                        );
                        _transfer(address(this), receiver, id);
                    } else {
                        _mint(receiver, id);
                        ++total;
                    }
                    j += 10;
                }
                ++i;
                emit CrossEvent(address(this), _srcChainId, asset);
            }
        }
        _totalSupply = total;
    }

    function getPayload(
        Assets[] memory _assets
    ) external pure returns (bytes memory _payload) {
        _payload = abi.encode(_assetsToUint256(_assets));
    }

    function _assetsToUint256(
        Assets[] memory _assets
    ) private pure returns (uint256[] memory assets) {
        uint256 len = _assets.length;
        assets = new uint256[](len);
        for (uint256 i = 0; i < len; ) {
            Assets memory _asset = _assets[i];
            uint256 idLen = _asset.ids.length;
            uint256 asset;
            for (uint256 j = 0; j < idLen; ) {
                asset = _concatId(asset, _asset.ids[j]);
                ++j;
            }
            assets[i] = _getAssets(idLen, asset, uint160(_asset.owner));
            ++i;
        }
    }

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        Assets[] memory _assets,
        bytes memory _adapterParams
    ) external view returns (uint256) {
        bytes memory _payload = abi.encode(_assetsToUint256(_assets));
        return _estimateFees(_dstChainId, _userApplication, _payload, _adapterParams);
    }

    function _estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes memory _assets,
        bytes memory _adapterParams
    ) private view returns (uint256 fee) {
        bytes memory _payload = abi.encode(_assets);
        (fee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            _userApplication,
            _payload,
            false,
            _adapterParams
        );
    }
}
