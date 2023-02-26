// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IPixelsMetaverse1155 {
    function handleTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) external;
}

contract PMT1155 is ERC1155 {
    uint256 private _MAX_QUANTITY;
    bool private _paused;
    address private _minter;
    using Counters for Counters.Counter;
    Counters.Counter public _currentID;

    modifier Minter() {
        require(msg.sender == _minter, "You don't have permission to make it");
        _;
    }

    constructor() ERC1155("") {}

    function initialize(uint256 MAX_QUANTITY) public Minter {
        _MAX_QUANTITY = MAX_QUANTITY;
    }

    function mint(
        address to,
        uint256 id,
        uint256 quantity
    ) public Minter {
        require(!_paused, "Can't mint");
        // require(
        //     _MAX_QUANTITY == 0 || _nextTokenId() <= _MAX_QUANTITY,
        //     "Exceed maximum quantity"
        // );
        _mint(to, id, quantity, "");
    }

    function currentID() public view returns (uint256) {
        return _currentID.current();
    }

    function setPause() public Minter {
        _paused = true;
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
            IPixelsMetaverse1155(_minter).handleTransfer(from, to, id, amount);
        }
    }
}
