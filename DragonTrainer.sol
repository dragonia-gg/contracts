// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @title NFT and on-chain Gaming Experience contract for Dragonia Dragon Trainer NFTs (dragonia.gg)
/// @author 0xNaut

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract DragonTrainer is ERC721A, Ownable, ReentrancyGuard {
  
  // Mint Section
  uint256 public MAX_SUPPLY = 6000;
  uint256 public PRICE = .07 ether;
  uint256 public MAX_PER_WALLET = 30;
  uint256 public TEAM_AMOUNT = 30;
  bool public mintLive;
  bool public teamMinted;

  // Whitelist Mint
  bytes32 public whitelistMerkleRoot;
  uint256 public WHITELIST_PRICE = .06 ether;
  uint256 public WHITELIST_MAX_MINT = 3;
  bool public whitelistMintLive;

  constructor() ERC721A("Dragonia Dragon Trainer", "DRGNTRNR", 30, 6000) {}

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Not Whitelisted"
    );
    _;
  }

  function mintWhitelist(uint256 amount, bytes32[] calldata merkleProof) external payable isValidMerkleProof(merkleProof, whitelistMerkleRoot) {
    require(whitelistMintLive, "Whitelist mint not live");
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds supply (May be Sold out)");
    require(msg.value == amount * WHITELIST_PRICE, "Wrong price");
    require(numberMinted(msg.sender) + amount <= WHITELIST_MAX_MINT, "Exceeds maximum per wallet for Whitelist Mint (3)");
    _safeMint(msg.sender, amount);
  }

  function mint(uint256 amount) external payable {
    require(mintLive, "Mint not live");
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds supply (May be Sold out)");
    require(msg.value == amount * PRICE, "Wrong price");
    require(numberMinted(msg.sender) + amount <= MAX_PER_WALLET, "Exceeds maximum per wallet (30)");
    _safeMint(msg.sender, amount);
  }

  function mintTeam() external onlyOwner {
    require(!teamMinted, "Already minted");
    teamMinted = !teamMinted;
    _safeMint(msg.sender, 30);
  }

  function toggleMint() external onlyOwner {
    mintLive = !mintLive;
  }

  function toggleWhitelistMint() external onlyOwner {
    whitelistMintLive = !whitelistMintLive;
  }

  function setWhitelistMerkle(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    PRICE = newPrice;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  // URIs
  string private baseURI;
  string private unrevealedURI = "ipfs://bafybeiaejqvrshnudnuzlhihapynehckvyfb34lnib6fxv2jmw6r2f2s7m/0";
  bool public revealed;

  function reveal() public onlyOwner {
    require(!revealed, "Already revealed");
    revealed = !revealed;
  }

  function setBaseURI(string calldata newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function setUnrevealedURI(string calldata newUnrevealedURI) public onlyOwner {
    unrevealedURI = newUnrevealedURI;
  }

  function tokenURI(uint256 tokenId_) public view override returns (string memory) {
    if(!revealed) {
      return unrevealedURI;
    }
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId_)));
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }

  // Game Section
  string private gameCode;
  uint256 public SEASON = 1;
  uint256 public EXP_GAIN = 10;
  mapping(address => mapping(uint256 => uint256)) public seasonExperience;
  mapping(uint256 => uint256) public lastEarnedExpTime;
  mapping(address => uint256) public earnExpTimeMod;
  mapping(address => mapping(uint256 => bool)) public seasonUpgradesClaimed;
  uint256 public TIME_MOD = 24;
  uint256 public TIME_MOD_TRIM = 1;
  uint256 public UPGRADES_COST = 210;
  bool public upgradesLive;

  function getExp(address trainer, uint256 seasonId) public view returns (uint256) {
    return seasonExperience[trainer][seasonId];
  }

  function currentExp() public view returns (uint256) {
    return seasonExperience[msg.sender][SEASON];
  }

  function earnExp(uint256 tokenId, string calldata secret) external nonReentrant {
    require(ownerOf(tokenId) == msg.sender, "Not owner");
    require(
      lastEarnedExpTime[tokenId] + (earnExpTimeMod[msg.sender] + TIME_MOD) * 1 hours <= block.timestamp,
      "Can only earn EXP once per period"
    );
    require(keccak256(bytes(secret)) == keccak256(bytes(gameCode)), "Refresh");
    lastEarnedExpTime[tokenId] = block.timestamp;
    seasonExperience[msg.sender][SEASON] += EXP_GAIN;
  }

  function upgradeExpTimeMod() external nonReentrant {
    require(!seasonUpgradesClaimed[msg.sender][SEASON], "Already upgraded");
    require(upgradesLive, "Upgrades not live");
    require(seasonExperience[msg.sender][SEASON] - UPGRADES_COST >= 0, "Not enough EXP");
    seasonExperience[msg.sender][SEASON] -= UPGRADES_COST;
    seasonUpgradesClaimed[msg.sender][SEASON] = true;
    earnExpTimeMod[msg.sender] = TIME_MOD_TRIM;
  } 

  function setSeason(uint256 newSeason) external onlyOwner {
    SEASON = newSeason;
  }

  function setExpGain(uint256 newExpGain) external onlyOwner {
    EXP_GAIN = newExpGain;
  }
  
  function setGameCode(string calldata secret) external onlyOwner {
    gameCode = secret;
  }

  function setExpEarnTimeModifier(uint256 newTimeMod) external onlyOwner {
    TIME_MOD = newTimeMod;
  }

  function setTimeModTrim(uint256 newTimeModifier) external onlyOwner {
    TIME_MOD_TRIM = newTimeModifier;
  }

  function toggleUpgradesLive() external onlyOwner {
    upgradesLive = !upgradesLive;
  }

  function setUpgradesCost(uint256 newCost) external onlyOwner {
    UPGRADES_COST = newCost;
  }
}