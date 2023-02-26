// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IManage {
    struct EthnosStruct {
        address ethnos; //伊诺斯
        string name; // 伊诺斯的称号，例如 元宇宙一世 等等
        uint32 time; //多久开始成为伊诺斯的
        uint256 pme; // 打响指的时候获得的 元宇宙资金库中的资金 数量
    }

    struct MetaverseStruct {
        address manager; //合约的管理者，也可以是该区域的占领者
        uint8 types; //land的类型，是否是中立或者非中立
        uint32 changeTime; //改变区域类型的时间
    }

    struct LandStruct {
        address manager; //合约的管理者，也可以是该区域的占领者
        uint8 types; //land的类型，是否是中立或者非中立 0 1 2 10 12 20 21
        uint32 changeTime; //改变区域类型的时间
        uint8 corporateTax; //企业所得税
        uint8 individualTax; //个人所得税
        uint40 price; //区域建设价格
    }

    struct IDToAreaStruct {
        address area; //id对应的合约地址
        uint8 types; //区域的类型
        uint32 changeTime; //改变区域类型的时间
        uint8 corporateTax; //企业所得税
        uint8 individualTax; //个人所得税
        uint40 price; //区域建设价格
    }

    struct AreaStruct {
        address owner; //区域的所有者
        uint8 land; //区域的land id
        uint8 area; //区域id
        uint8 people; //当前的人数
        uint8 salary; //薪资
        uint8 types; //区域的类型
        uint32 energyTime; //下一次集体补充能量的时间点
        uint32 typesTime; //改变区域类型的时间
    }

    struct UserStruct {
        uint8 land; //当前用户所在的土地id
        uint8 area; //当前用户所在的区域id
        uint8 joined; //是否加入该区域
    }

    struct UserAttributeStruct {
        uint8 output; //当前用户的输出力
        uint8 absorb; //吸收 缓冲力 用nft721的像素NFT来，可以购买盾牌等
        uint8 todayOutput; //今天的产量
        uint8 settlement; //已结算的产量
        uint64 unpaid; //未结算税收的商品数量
        uint64 position; //当前所在位置坐标
        uint64 speed; //当前的速度，购买车子 或者飞机 或者瞬间转移等道具
    }
}
