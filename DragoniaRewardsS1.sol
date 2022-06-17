// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

/// @title Dragon Trainer NFT Rewards contract for Defend Dragonia Season 1
/// @author 0xNaut

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DragoniaRewardsS1 is ERC1155, Ownable, ReentrancyGuard {
    
    // Reward IDs
    // CARD_IRON = 0;
    // CARD_AQUA = 1;
    // BOARD_AQUA = 2;
    // CARD_AMETHYST = 3;
    // BOARD_AMETHYST = 4;
    // CARD_VENOM = 5;
    // BOARD_VENOM = 6;
    // CARD_LEGACYBRONZE = 7;
    // CARD_LEGACYSILVER = 8;

    mapping(uint256 => bool) public rewardsLive;
    mapping(address => mapping(uint256 => bool)) public claimedReward;
    string public baseURI = "ipfs://bafybeidbev6wi4cljwycodurzwvm3atdri6klofirqpf4ehlypw5aoqjg4/";
    string public uriEnding = ".json";
    uint256 public PRICE = 70; // Price in Dragonia Experience Points per Reward
    IDragonTrainer public dragonTrainerContract;

    constructor(IDragonTrainer _nftContract) ERC1155("") {
        dragonTrainerContract = _nftContract;
    }

    function mint(uint256 id) public nonReentrant {
        require(rewardsLive[id], "Rewards not live");
        require(!claimedReward[msg.sender][id], "Already claimed this reward");
        require(
            dragonTrainerContract.getExp(msg.sender, 1) >= (id + 1) * PRICE,
            "Not enough Exp in Season 1"
        );
        claimedReward[msg.sender][id] = true;
        _mint(msg.sender, id, 1, "");
    }

    function setRewardsLive(uint256 id) external onlyOwner {
        rewardsLive[id] = !rewardsLive[id];
    }

    function uri(uint256 id) override public view returns (string memory) {
        return(string(abi.encodePacked(
            baseURI,
            Strings.toString(id),
            uriEnding
        )));
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setURIEnding(string calldata newURIEnding) external onlyOwner {
        uriEnding = newURIEnding;
    }
}

interface IDragonTrainer {
    function getExp(address user, uint256 season) external view returns (uint256 xp);
}