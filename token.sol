// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error CustomError();

contract Token is ERC721 {

    struct User {
        address accountAddress;
        string username;
    }

    mapping(address => User) public users;
    mapping(address => bool) isRegistered;
    mapping(string => bool) isNameUnavailable;
    mapping(address => bool) isLoggedIn;

    uint256 public nextTokenId;

    User[] userArr;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function registerUser(string memory _username) public {
        if (isRegistered[msg.sender] == false) {
            if (isNameUnavailable[_username] == false) {
                User memory userInstance = User(msg.sender, _username);
                users[msg.sender] = userInstance;
                userArr.push(userInstance);

                isRegistered[msg.sender] = true;
                isNameUnavailable[_username] = true;
            } else {
                revert CustomError();
            }
        } else {
            revert CustomError();
        }
    }

    function logInUser(string memory _username) public {
        if (isRegistered[msg.sender] == true) {
            if (isLoggedIn[msg.sender] == false) {
                if (
                    keccak256(abi.encodePacked(users[msg.sender].username)) ==
                    keccak256(abi.encodePacked(_username))
                ) {
                    isLoggedIn[msg.sender] = true;
                } else {
                    revert CustomError();
                }
            } else {
                revert CustomError();
            }
        } else {
            revert CustomError();
        }
    }

    function logOutUser() public {
        if (isLoggedIn[msg.sender] == true) {
            isLoggedIn[msg.sender] = false;
        } else {
            revert CustomError();
        }
    }

    function createNFT() external {
        uint256 tokenId = nextTokenId;
        _mint(msg.sender, tokenId);  // Mint the NFT to the caller
        nextTokenId++;
    }
}
