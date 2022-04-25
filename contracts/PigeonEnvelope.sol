// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./librarys/Ownable.sol";
import "./librarys/Counters.sol";
import "./librarys/ITag.sol";
import "./librarys/IPodCore.sol";
import "./librarys/ITagClass.sol";
import "./librarys/PodHelper.sol";
import "./librarys/ERC721.sol";

/**
 * @title PigeonEnvelope contract
 */
contract PigeonEnvelope is ERC721, Ownable {
    using PodHelper for *;

    struct Category {
        bytes32 categoryId;
        address operator;
        string baseURI;
        string categoryName;
    }

    event NewCategory(
        address indexed operator,
        bytes32 indexed categoryId,
        string categoryName,
        string baseURI
    );

    event Airdropped(
        address indexed owner,
        bytes32 indexed categoryId,
        uint256 tokenId
    );

    event Opened(bytes32 indexed categoryId, uint256 indexed tokenId);

    event CategoryOperatorTransferred(address oldOperator, address newOperator);

    event TagAddressUpdated(address oldTagAddres, address newTagAddress);

    event TagClassAddressUpdated(
        address oldTagClassAddres,
        address newTagClassAddress
    );

    event TagClassIdUpdated(bytes18 oldTagClassId, bytes18 newTagClassId);

    ITag private _Tag;
    ITagClass private _TagClass;

    bytes18 private _TagClassId;
    uint256 private _TokenId;
    mapping(bytes32 => Category) private _Categories; // CategoryId => Category
    mapping(uint256 => bytes32) private _TokenIdCategory; // TokenId => CategoryId

    constructor(address tagAddress, address tagClassAddress)
        ERC721("PigeonEnvelope", "PEVP")
        Ownable()
    {
        _Tag = ITag(tagAddress);
        _TagClass = ITagClass(tagClassAddress);

        ITagClass.NewValueTagClassParams memory params;
        params.TagName = "PigeonEnvelopeOpenedTag";
        params.Desc = "Using to mark an envelope whether was been opened";
        params.Agent = IPodCore.TagAgent(
            IPodCore.AgentType.Address,
            bytes20(address(this))
        );
        _TagClassId = _TagClass.newValueTagClass(params);
        _TagClass.transferTagClassOwner(_TagClassId, msg.sender);
    }

    function getTagClassId() public view returns (bytes18) {
        return _TagClassId;
    }

    function updateTagClassId(bytes18 newTagClassId) public onlyOwner {
        bytes18 oldTagClassId = _TagClassId;
        _TagClassId = newTagClassId;
        emit TagClassIdUpdated(oldTagClassId, newTagClassId);
    }

    function updateTagAddress(address newTagAddress) public onlyOwner {
        address oldTagAddress = address(_Tag);
        _Tag = ITag(newTagAddress);
        emit TagAddressUpdated(oldTagAddress, newTagAddress);
    }

    function updateTagClassAddress(address newTagClassAddress)
        public
        onlyOwner
    {
        address oldTagClassAddress = address(_TagClass);
        _TagClass = ITagClass(newTagClassAddress);
        emit TagClassAddressUpdated(oldTagClassAddress, newTagClassAddress);
    }

    function newCategory(
        address operator,
        string calldata categoryName,
        string calldata baseURI
    ) public onlyOwner returns (bytes32) {
        require(bytes(categoryName).length > 0, "CategoryName cannot empty");
        bytes32 categoryId = keccak256(
            abi.encodePacked(operator, categoryName)
        );
        require(
            _Categories[categoryId].categoryId == bytes32(0),
            "Duplicate categoryId"
        );

        Category memory category;
        category.categoryId = categoryId;
        category.baseURI = baseURI;
        category.operator = operator;
        category.categoryName = categoryName;
        _Categories[categoryId] = category;
        emit NewCategory(operator, categoryId, categoryName, baseURI);
        return categoryId;
    }

    function transferCategoryOperator(bytes32 categoryId, address newOperator)
        public
    {
        Category memory category = _Categories[categoryId];
        require(category.categoryId != bytes32(0), "Invalid categoryId");
        require(
            category.operator == msg.sender,
            "Only category operator can transfer"
        );
        address oldOperator = category.operator;
        category.operator = newOperator;
        _Categories[categoryId] = category;
        emit CategoryOperatorTransferred(oldOperator, newOperator);
    }

    function airdrop(bytes32 categoryId, address[] calldata addresses) public {
        Category memory category = _Categories[categoryId];
        require(category.categoryId != bytes32(0), "Invalid categoryId");
        require(category.operator == msg.sender, "Invalid operator");

        for (uint256 i = 0; i < addresses.length; i++) {
            _TokenId++;
            _safeMint(addresses[i], _TokenId);
            _TokenIdCategory[_TokenId] = categoryId;
            emit Airdropped(addresses[i], categoryId, _TokenId);
        }
    }

    function open(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Only NFT owner can open envelope");
        IPodCore.TagObject memory object = IPodCore.TagObject(
            IPodCore.ObjectType.NFT,
            bytes20(address(this)),
            tokenId
        );
        require(!_hasOpened(object), "Envelope has already opened");
        _open(object);
        emit Opened(_TokenIdCategory[tokenId], tokenId);
    }

    function hasOpened(uint256 tokenId) public view returns (bool) {
        IPodCore.TagObject memory object = IPodCore.TagObject(
            IPodCore.ObjectType.NFT,
            bytes20(address(this)),
            tokenId
        );
        return _hasOpened(object);
    }

    function _hasOpened(IPodCore.TagObject memory object)
        internal
        view
        returns (bool)
    {
        return _Tag.hasTag(_TagClassId, object);
    }

    function _open(IPodCore.TagObject memory object) internal {
        _Tag.setTag(_TagClassId, object, new bytes(0), 0);
    }

    function getCategoryId(uint256 tokenId) public view returns (bytes32) {
        return _TokenIdCategory[tokenId];
    }

    function getCategory(bytes32 categoryId)
        public
        view
        returns (Category memory)
    {
        return _Categories[categoryId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes32 categoryId = this.getCategoryId(tokenId);
        if (categoryId == bytes32(0)) {
            return "";
        }
        return _Categories[categoryId].baseURI;
    }
}
