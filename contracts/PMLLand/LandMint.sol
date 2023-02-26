// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
pragma abicoder v2;

import "./Land.sol";
// import "hardhat/console.sol";

contract PMLandMint is PMLand {
    address private immutable _pawnshop;

    constructor(
        address _endpoint,
        address payable pawnshop,
        uint256[] memory ids
    ) payable PMLand(_endpoint) {
        uint256 len = ids.length;
        _totalSupply = len;
        for (uint256 i = 0; i < len; ) {
            _mint(msg.sender, ids[i]);
            unchecked {
                ++i;
            }
        }
        _pawnshop = pawnshop;
    }

    function getPawnshop() external view returns (address) {
        return _pawnshop;
    }

    function mint(address to, uint256[] memory ids) external payable lock {
        uint256 len = ids.length;
        require(len <= 9, "Quantity over limit");
        uint256 total;
        unchecked {
            _totalSupply += len;
            total = _price * len;
        }
        require(msg.value == total, "The quantity ERROR");

        for (uint256 i = 0; i < len; ) {
            uint256 id = ids[i];
            require(id < 1024, "The maximum ID is 1023");
            _mint(to, id);
            unchecked {
                ++i;
            }
        }
        _safeTransferETH(_pawnshop, msg.value);
    }
}
