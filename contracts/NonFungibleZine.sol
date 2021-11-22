// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract NonFungibleZine is ERC721, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Track indexes (users) which have claimed their tokens
    mapping(uint256 => uint256) private claimedBitMap;
    mapping(address => uint256) private amountClaimable;
    mapping(address => uint256) private amountClaimed;

    // Define starting contract state
    bytes32 merkleRoot;
    bool merkleSet = false;
    bool public earlyAccessMode = true;
    bool public mintingIsActive = false;
    string public baseURI = "ipfs://QmVe2GvB6Xzzv3UsRBh3feHprC9QS2mHZ1pu2Ayp9348ec/";
    uint256 public constant maxSupply = 1000;
    uint256 public constant maxMints = 2;

    constructor() ERC721("Non-Fungible Zine", "NFZ") {}

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or pause
    function toggleMinting() external onlyOwner {
        if (mintingIsActive) {
            mintingIsActive = false;
        } else {
            mintingIsActive = true;
        }
    }

    // Flip the early access mode to allow/disallow public minting vs whitelist
    function toggleEarlyAccessMode() external onlyOwner {
        if (earlyAccessMode) {
            earlyAccessMode = false;
        } else {
            earlyAccessMode = true;
        }
    }

    // Specify a new IPFS URI for metadata
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    // Get total supply based upon counter
    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    // Specify a merkle root hash from the gathered k/v dictionary of
    // addresses and their claimable amount of tokens - thanks Kiwi!
    // https://github.com/0xKiwi/go-merkle-distributor
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        merkleSet = true;
    }

    // Return bool on if merkle root hash is set
    function isMerkleSet() public view returns (bool) {
        return merkleSet;
    }

    // Check if an index has claimed tokens
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // Store if an index has claimed their tokens
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    // Claim and mint tokens
    function mintItem(
      uint256 index,
      address account,
      uint256 amount,
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    ) external {
        require(mintingIsActive, "Minting is not active.");
        require(numberOfTokens > 0, "Must mint at least 1 token");
        require(numberOfTokens <= maxMints, "Cannot mint more than 2 at a time");
        require(tokensMinted().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply");

        if (earlyAccessMode) {
            require(msg.sender == account, "Can only be claimed by the hodler");
            require(!isClaimed(index), "Drop already claimed");
            // Verify merkle proof
            bytes32 node = keccak256(abi.encodePacked(index, account, amount));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
            // Update the claimable amount for address
            if (amountClaimable[msg.sender] == 0) {
                amountClaimable[msg.sender] = amount;
            }
            // Ensure not trying to mint more than claimable
            require(amountClaimed[msg.sender].add(numberOfTokens) <= amountClaimable[msg.sender], "Cannot mint more than what is claimable");
        } else {
            require(balanceOf(msg.sender).add(numberOfTokens) <= maxMints, "Minting would exceed maximum amount of 2 items per wallet.");
        }

        // Mint i tokens where i is specified by function invoker
        for(uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, tokensMinted().add(1));
            _tokenSupply.increment();
            if (earlyAccessMode) {
                // Increment amount claimed counter while in earlyAccessMode
                amountClaimed[msg.sender] = amountClaimed[msg.sender].add(1);
                if (amountClaimed[msg.sender] == amountClaimable[msg.sender]) {
                    // Mark it claimed
                    _setClaimed(index);
                }
            }
        }
    }

    // Override the below functions from parent contracts

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}
