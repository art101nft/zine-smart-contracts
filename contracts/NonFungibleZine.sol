// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract NonFungibleZine is ERC721, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    bool public mintingIsActive = false;
    string public baseURI = "ipfs://QmQFgdnThKder4uneCPcdgEZxXUzit2vTqfoKFg48WE2gT/";
    uint256 public constant maxSupply = 1000;
    uint256 public constnat maxMints = 2;

    constructor() ERC721("Non-Fungible Zine", "NFZ") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function toggleMinting() external onlyOwner {
        if (mintingIsActive) {
            mintingIsActive = false;
        } else {
            mintingIsActive = true;
        }
    }

    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function mint() public payable {
        require(mintingIsActive, "Minting is not active.");
        require(tokensMinted() < maxSupply, "Minting would exceed max supply.");
        _safeMint(msg.sender, _tokenSupply.current() + 1);
        _tokenSupply.increment();
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
