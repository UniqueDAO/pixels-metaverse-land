// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./PMT721A.sol";
import "./IManage.sol";

/* 
产量高的可以改变产量低的人的值，降低的数量是两者的差值，如果不想被打，只有不停的逃跑。
每个人都有个位置，就是他在某个land中的某个area里面的某个位置。都是xy点坐标标识。
可以通过销毁不同数量的PMT20来让位置移动的速度进行不同程度的加快，想快速移动，那么需要
销毁更多的PMT20。每个人的历史产量就是他的攻击力的数据值。可以选择攻击姿态或者防御姿态，
此时需要消耗更多的PMT20。对于
加入响应式nft，比如文字控制，事件控制，声音控制，键盘按键控制等等
 */

interface IPMT721 {
    function initialize(
        string memory name,
        string memory symbol,
        uint256 _MAX_QUANTITY
    ) external;
}

interface IPML {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IPME {
    function burn(address account, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract PixelsMetaverseDivision is IManage {
    IPML internal _pml;
    IPME internal _pme;

    mapping(address => uint256) internal _metaverses;

    mapping(uint256 => LandStruct) internal _landTypes;
    // event MetaverseEvent(uint256 land, uint256 types, uint256 tax);

    event PMT721Event(address pmt721, address owner, string name, string desc);

    mapping(uint256 => mapping(uint256 => uint256)) internal _landAreas;
    mapping(uint256 => mapping(uint256 => IDToAreaStruct)) internal _idToAreas;
    // event LandEvent(
    //     uint256 land,
    //     uint256 area,
    //     uint256 types,
    //     uint256 corporateTax,
    //     uint256 individualTax,
    //     uint256 price,
    //     uint256 noSettlement
    // );

    mapping(address => AreaStruct) internal _areas;
    // event AreaEvent(
    //     address owner,
    //     uint8 land,
    //     uint8 area,
    //     uint8 types,
    //     uint8 people,
    //     uint32 changeTime,
    //     uint32 timeMeal,
    //     uint8 salary,
    //     uint152 unpaid
    // );

    mapping(address => UserStruct) internal _users;
    // event UserEvent(
    //     address areas,
    //     uint8 output,
    //     uint8 settlement,
    //     uint8 joined,
    //     uint64 unpaid
    // );

    modifier landOwner(uint256 land) {
        address owner = IPML(_pml).ownerOf(land);
        require(msg.sender == owner, "You don't have permission to set it");
        _;
    }

    modifier areaOwner(address area) {
        AreaStruct memory a = _areas[area];
        require(msg.sender == a.owner, "You don't have permission to set it");
        _;
    }

    constructor(address pml, address pme) {
        _pml = IPML(pml);
        _pme = IPME(pme);
    }

    function setLandTypes(
        uint256 land,
        uint8 types,
        uint256 payment
    ) external landOwner(land) {
        LandStruct memory l = _landTypes[land];
        uint256 diff = l.types - types;
        if (diff * 64 > payment) {
            _landTypes[land].types = types;
        }
        require(payment < types, "You don't have permission to set it");
    }

    function getLandTypes(uint256 land)
        external
        view
        returns (LandStruct memory)
    {
        return _landTypes[land];
    }

    function setLandArea(
        uint256 land,
        uint256 area,
        uint256 corporateTax,
        uint256 individualTax,
        uint256 price
    ) external landOwner(land) {
        require(price != 0, "You don't have permission to set it");
        uint256 _landArea = _landAreas[land][area];
        _landAreas[land][area] =
            ((corporateTax << 200) | (individualTax << 208) | (price << 216)) |
            ((_landArea >> 200) << 200);
    }

    function setAreaTypesOrUpdateArea(
        address area,
        address owner,
        uint256 types,
        string memory name,
        string memory desc,
        string memory pmt721Name,
        string memory pmt721Symbol,
        uint256 _MAX_QUANTITY
    ) external {
        AreaStruct memory a = _areas[area];
        require(a.owner == msg.sender, "You don't have permission to set it");
        require(a.land != 0, "You don't have permission to set it");

        uint256 _landArea = _landAreas[a.land][a.area];
        uint256 time = block.timestamp % (2**32);
        time = time + (types + 1) * 1 days;
        _landAreas[a.land][a.area] =
            (types << 160) |
            (time << 168) |
            ((_landArea >> 200) << 200) |
            (1 << 216);

        createPMT721(
            a.land,
            a.area,
            owner,
            name,
            desc,
            pmt721Name,
            pmt721Symbol,
            _MAX_QUANTITY
        );
    }

    function getLandArea(uint256 land, uint256 area)
        public
        view
        returns (IDToAreaStruct memory)
    {
        uint256 _area = _landAreas[land][area];
        return
            IDToAreaStruct(
                address(uint160(_area)),
                uint8(_area >> 160),
                uint32(_area >> 168),
                uint8(_area >> 200),
                uint8(_area >> 208),
                uint40(_area >> 216)
            );
    }

    function createPMT721(
        uint256 land,
        uint256 area,
        address owner,
        string memory name,
        string memory desc,
        string memory pmt721Name,
        string memory pmt721Symbol,
        uint256 _MAX_QUANTITY
    ) public returns (address pmt721) {
        IDToAreaStruct memory l = getLandArea(land, area);
        require(
            l.area == address(0) && l.price != 0,
            "You don't have permission to set it1"
        );

        require(
            (land > 0 && area < 64) || land == 0,
            "You don't have permission to set it2"
        );

        if (land == 0) {
            IPME(_pme).burn(msg.sender, 10**20);
        }

        if (l.price > 1) {
            address _landOwner = _pml.ownerOf(land);
            bool isSuccess = IPME(_pme).transferFrom(
                msg.sender,
                _landOwner,
                uint256(l.price) * (10**18)
            );
            require(isSuccess, "You don't have permission to set it3");
        }

        bytes memory bytecode = type(PMT721A).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(land, area, msg.sender));
        assembly {
            pmt721 := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        uint256 _area = _landAreas[land][area];
        _landAreas[land][area] =
            _addressToUint256(pmt721) |
            ((_area >> 160) << 160);

        _areas[pmt721] = AreaStruct(
            msg.sender,
            uint8(land),
            uint8(area),
            0,
            0,
            0,
            0,
            0
        );
        IPMT721(pmt721).initialize(pmt721Name, pmt721Symbol, _MAX_QUANTITY);
        emit PMT721Event(pmt721, owner, name, desc);
    }

    function _addressToUint256(address value)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := value
        }
    }

    function setSalary(address area, uint8 salary) external areaOwner(area) {
        _areas[area].salary = salary;
    }

    function setAreaOwner(address area, address owner)
        external
        areaOwner(area)
    {
        _areas[area].owner = owner;
    }

    function setTimeMeal(address area) external {
        AreaStruct memory a = _areas[area];
        require(msg.sender == a.owner, "You don't have permission to set it");
        IPME(_pme).burn(msg.sender, a.people * 10**18);
        _areas[area].energyTime == (block.timestamp + 1 days) % (2**32);
    }

    function getArea(address area) external view returns (AreaStruct memory) {
        return _areas[area];
    }

    function handleOutput(uint8 _output) external {
        _users[msg.sender].output = _output;
    }

    function joinArea(uint8 land, uint8 area) external {
        UserStruct memory u = _users[msg.sender];
        if (u.land != 0) {
            AreaStruct memory a = _areas[
                address(uint160(_landAreas[land][area]))
            ];
            bool isSuccess = IPME(_pme).transferFrom(
                msg.sender,
                a.owner,
                u.output * 10**18
            );
            require(isSuccess, "You don't have permission to set it");
            _users[msg.sender].joined = 0;
        }

        _users[msg.sender].land = land;
        _users[msg.sender].area = area;
    }

    function handleJoinArea(
        uint8 land,
        uint8 area,
        address user,
        uint8 isJoin
    ) external {
        UserStruct memory u = _users[user];
        require(
            u.land == land && u.area == area,
            "You don't have permission to set it"
        );
        AreaStruct memory a = _areas[address(uint160(_landAreas[land][area]))];
        require(a.owner == msg.sender, "You don't have permission to set it");

        _users[msg.sender].joined = isJoin;
        if (isJoin == 0) {
            bool isSuccess = IPME(_pme).transferFrom(
                msg.sender,
                user,
                u.output * 10**18
            );
            require(isSuccess, "You don't have permission to set it");
            _users[msg.sender].land = 0;
            _users[msg.sender].area = 0;
        }
    }

    function claimSalary() external {
        UserStruct memory u = _users[msg.sender];
        IDToAreaStruct memory l = getLandArea(u.land, u.area);
        AreaStruct memory a = _areas[l.area];
        address _landOwner = _pml.ownerOf(u.land);
        bool isSuccess = IPME(_pme).transferFrom(
            address(this),
            a.owner,
            l.individualTax * u.settlement
        );
        bool isSuccessArea = IPME(_pme).transferFrom(
            address(this),
            _landOwner,
            l.corporateTax * u.settlement
        );
        bool isSuccessSalary = IPME(_pme).transferFrom(
            address(this),
            msg.sender,
            l.corporateTax * u.settlement
        );
        require(
            isSuccessArea && isSuccess && isSuccessSalary,
            "You don't have permission to set it"
        );
    }

    function getUser(address user) external view returns (UserStruct memory) {
        return _users[user];
    }
}
