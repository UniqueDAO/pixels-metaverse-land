// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPML {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract PMLandPawnshop {
    uint256 private _price = 1;
    address private _pml;
    address private immutable _owner;

    modifier lock() {
        require(_price == 1, "LOCKED");
        _price = 0.1024 ether;
        _;
        _price = 1;
    }

    modifier owner() {
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

    constructor() payable {
        _owner = msg.sender;
    }

    function getPML() external view returns (address) {
        return _pml;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function setPML(address pml) external owner {
        require(_pml == address(0), "Cannot be zero address");
        _pml = pml;
    }

    function _safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function refund(address to, uint256[] calldata ids) external lock {
        uint256 len = ids.length;
        for (uint256 i = 0; i < len; ) {
            IPML(_pml).transferFrom(msg.sender, address(this), ids[i]);
            unchecked {
                ++i;
            }
        }
        uint256 total;
        unchecked {
            total = len * 0.1 ether;
        }
        _safeTransferETH(to, total);
    }

    function claim(address to, uint256[] calldata ids) external payable lock {
        uint256 len = ids.length;
        uint256 total;
        unchecked {
            total = _price * len;
        }
        require(msg.value == total, "The quantity ERROR");
        for (uint256 i = 0; i < len; ) {
            IPML(_pml).transferFrom(address(this), to, ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external lock owner {
        require(block.timestamp > 2666620624, "Time Error");
        _safeTransferETH(_owner, address(this).balance);
    }

    receive() external payable {}
}
