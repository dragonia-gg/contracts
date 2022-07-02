// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

/// @title Defend Dragonia Deck and Board Skin NFTs
/// @author 0xNaut

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract DefendDragoniaSkins is ERC1155, Ownable, ReentrancyGuard {

    // Reward IDs
    // Honorary Deck Skins
    // 0: Orange Steel (Crowly)
    // 1: Lime Steel (Naut)
    // 2: Neon Steel (Optimism)
    // 3: Pink Steel (Quixotic)
    // 4: Deep Purple Steel (Daily Gwei)
    // 5: Navy Steel (Synthetix)
    // Other confirmed Skins
    // 6: Optimism Launch Deck
    // 7: Optimism Launch Board
    // 8: Synthetix Launch Deck
    // 9: Synthetix Launch Board
    // 10: Blue Steel Deck
    // 11: Red Steel Deck
    // MORE TBA

    mapping(uint256 => bool) public rewardLive;
    mapping(uint256 => bool) public onlyClaimable;
    mapping(address => mapping(uint256 => bool)) public claimedReward;
    uint256 public PRICE = 0.003 ether;
    string public baseURI = "ipfs://bafybeibopqg4urrea6ohetpdvtk5ttwc34kaht2sthi7crzbf26vnpluve/";
    string public uriEnding = ".json";
    address public dragonTrainer = 0x9e925d6D3c35Fe70DD164D4D39bdb12533b143f5;

    constructor() ERC1155("") {
        for (uint256 i = 0; i <= 5; i++) {
            onlyClaimable[i] = true;
        }
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(rewardLive[id], "Reward not live");
        require(!onlyClaimable[id], "Reward not mintable");
        require(msg.value >= amount * PRICE, "Not enough ETH");
        _mint(msg.sender, id, amount, "");
    }

    function claim(uint256 id) public nonReentrant {
        require(rewardLive[id], "Reward not live");
        require(onlyClaimable[id], "Reward not claimable");
        require(!claimedReward[msg.sender][id], "Already claimed");
        require(
            IERC721(dragonTrainer).balanceOf(msg.sender) > 0,
            "Must own a Dragonia Dragon Trainer to claim this reward"
        );
        claimedReward[msg.sender][id] = true;
        _mint(msg.sender, id, 1, "");
    }

    function mintToMany(uint256 id, uint256 amount, address[] calldata list) external onlyOwner {
        for (uint256 i = 0; i < list.length; i++) {
            _mint(list[i], id, amount, "");
        }
    }

    function setRewardState(uint256 id, bool live, bool claimOnly) external onlyOwner {
        rewardLive[id] = live;
        onlyClaimable[id] = claimOnly;
    }

    function toggleRewardLive(uint256 id) external onlyOwner {
        rewardLive[id] = !rewardLive[id];
    }

    function toggleRewardClaimOnly(uint256 id) external onlyOwner {
        onlyClaimable[id] = !onlyClaimable[id];
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

    function setCollectionPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }
}