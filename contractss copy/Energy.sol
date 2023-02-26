// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PixelsMetaverseEnergy is ERC20 {
    address private _minter;
    address private _owner;

    constructor() ERC20("PixelsMetaverseEnergy", "PME") {
        _mint(msg.sender, 102400 * 10 ** 18);
        _owner = _msgSender();
    }

    modifier minter() {
        require(_msgSender() == _minter, "Only Minter Can Do It!");
        _;
    }

    function mint(address to, uint256 amount) external minter {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external {
        require(
            _minter == _msgSender() || account == msg.sender,
            "You're not authorized to do this!"
        );
        _burn(account, amount);
    }

    function setMinter(address pixels_metaverse) external {
        require(_minter == address(0), "The Minter address is set!");
        require(_owner == _msgSender(), "Only Owner Can Do It!");
        _minter = pixels_metaverse;
    }
}
