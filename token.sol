// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error CustomError();
error UsernameNotAvailable();

contract Token is ERC721 {
    // custom error
    error CustomErrorWithReason(string);

    // Structure to store user information
    struct User {
        address accountAddress;
        string username;
    }

    // Structure to store auction information
    struct Auction {
        bytes4 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
    }

    // mapping to manage users
    mapping(address => User) users;
    mapping(address => bool) isRegistered;
    mapping(string => bool) isUsernameTaken;
    mapping(address => bool) isLoggedIn;

    // mapping to manage auction
    mapping(bytes4 => Auction) auctions;
    mapping(bytes4 => bool) isActive;

    // to increment token id
    uint256 public nextTokenId;

    // Structure type array to store all users
    User[] userArr;

    // bytes4 array to store auction ids
    bytes4[] auctionArr;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    modifier isUserLoggedIn() {
        if (isLoggedIn[msg.sender] == false) {
            revert CustomError();
        }
        _;
    }

    // User registration
    function registerUser(string memory _username) public {
        // Checks if user is already registered
        if (isRegistered[msg.sender] == true) {
            revert CustomError();
        }

        // Checks if username is unavailable
        if (isUsernameTaken[_username] == true) {
            revert UsernameNotAvailable();
        }

        User memory userInstance = User(msg.sender, _username);
        users[msg.sender] = userInstance;
        userArr.push(userInstance);

        isRegistered[msg.sender] = true;
        isUsernameTaken[_username] = true;
    }

    // get users
    function getUsers() public view returns (User[] memory) {
        return userArr;
    }

    // User log in
    function logInUser(string memory _username) public {
        // Checks if user is already registered
        if (isRegistered[msg.sender] == false) {
            revert CustomError();
        }

        // Checks if user is already loggedIn
        if (isLoggedIn[msg.sender] == true) {
            revert CustomError();
        }

        // Checks if user is trying to log in with own username
        if (
            keccak256(abi.encodePacked(users[msg.sender].username)) !=
            keccak256(abi.encodePacked(_username))
        ) {
            revert CustomError();
        }

        isLoggedIn[msg.sender] = true;
    }

    // Logout user
    function logOutUser() public {
        if (isLoggedIn[msg.sender] == true) {
            isLoggedIn[msg.sender] = false;
        } else {
            revert CustomError();
        }
    }

    // Mint NFT to msg.sender
    function createNFT() external isUserLoggedIn {
        _mint(msg.sender, nextTokenId);
        nextTokenId++;
    }

    // putting NFT for sale
    function auctionNFT(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration
    ) external isUserLoggedIn {
        // Verify if the user attempting to start the auction is the owner
        if (ownerOf(_tokenId) != msg.sender) {
            revert CustomErrorWithReason("Only owner can auction");
        }

        // Verify if the duration is enough
        if (_duration < 0) {
            revert CustomErrorWithReason("Duration must be greater than 0");
        }

        bytes4 aId = bytes4(
            keccak256(abi.encodePacked(block.timestamp, _tokenId))
        );

        Auction memory auctionInstance = Auction(
            aId,
            _tokenId,
            msg.sender,
            _startingPrice,
            0,
            address(0),
            block.timestamp + _duration
        );
        auctions[aId] = auctionInstance;
        auctionArr.push(aId);

        isActive[aId] = true;
    }

    function bid(bytes4 _aId) external payable isUserLoggedIn {
        Auction storage auction = auctions[_aId];

        // Check if the auction is active
        if (!isActive[_aId]) {
            revert CustomErrorWithReason("Auction is not active");
        }

        // Prevent the seller from bidding on their own auction
        if (auction.seller == msg.sender) {
            revert CustomErrorWithReason("You cannot bid on your own auction");
        }

        // Check if the bid is high enough
        if (
            msg.value <= auction.highestBid ||
            msg.value <= auction.startingPrice
        ) {
            revert CustomErrorWithReason("Your bid is not high enough");
        }

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{
                value: auction.highestBid
            }(" ");
            if (!success) {
                revert CustomErrorWithReason("Error while transfering fund");
            }
        }

        // updating with highestBid and highestBidder
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
    }

    function auctionEnd(bytes4 _aId) external {
        Auction storage auction = auctions[_aId];

        // Check if the auction is active
        if (!isActive[_aId]) {
            revert CustomErrorWithReason("Auction is not active");
        }

        // Verify if the user attempting to end the auction is the owner
        if (ownerOf(auction.tokenId) != msg.sender) {
            revert CustomErrorWithReason("Only owner can end auction");
        }

        if (auction.highestBidder == address(0)) {
            revert("No bids have been made");
        }

        // Transfer the token to highest bidder
        _transfer(auction.seller, auction.highestBidder, auction.tokenId);

        // transfer the highest bid amount to seller
        (bool success, ) = payable(auction.seller).call{
            value: auction.highestBid
        }(" ");
        
        if (!success) {
            revert CustomErrorWithReason("Error while transfering fund");
        }

        isActive[_aId] = false;
    }

    function showAuctions() public view returns (bytes4[] memory) {
        return auctionArr;
    }

    function showAuctionById(bytes4 _aId) public view returns (Auction memory) {
        return auctions[_aId];
    }
}
