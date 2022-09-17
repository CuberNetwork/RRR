pragma solidity ^0.8.0;

contract RealEstate {
    using SafeMath for uint256;
    // ------------------------------ Variables ------------------------------
    address private owner; // owner, who deploy this smart contract
    IRBAC roleContract; // reference to contract RoleBasedAcl
    // number of certificate (token id)
    uint256 public certificateCount;
    // State of certificate
    enum State {PENDDING, ACTIVATED, IN_TRANSACTION} //sate of token. 0: PENDING - 1: ACTIVATE - 2: IN_TRANSACTION

    // mapping token to owners
    mapping(uint256 => address[]) tokenToOwners;
    // mapping token to owner approved (activate || sell)
    mapping(uint256 => address[]) tokenToApprovals;
    // mapping token to state of token
    mapping(uint256 => State) public tokenToState; // Default: 0 => 'PENDDING'
    // mapping token to notary
    mapping(uint256 => address) public tokenToNotary;
    // mapping token to certificate
    mapping(uint256 => string) public tokenToCert;

  
    event NewCertificate(
        uint256 idCertificate,
        address[] owners,
        address notary
    );

    ///  This emits when ownership of any NFTs changes by any mechanism
    event Transfer(
        address[] oldOwner,
        address[] newOwner,
        uint256 idCertificate
    );

    // Emits when the owner activate certificate (PENDDING => ACTIVATED)
    event Activate(uint256 idCertificate, address owner, State state);

    constructor(IRBAC _roleContract) public {
        // Initialize roleContract
        roleContract = _roleContract;
        owner = msg.sender;
    }

    // ------------------------------ Modifiers ------------------------------

    modifier onlyPending(uint256 _id) {
        require(
            tokenToState[_id] == State.PENDDING,
            "RealEstate: Require state is PENDDING"
        );
        _;
    }

    modifier onlyActivated(uint256 _id) {
        require(
            tokenToState[_id] == State.ACTIVATED,
            "RealEstate: Require state is ACTIVATED"
        );
        _;
    }

    modifier onlyInTransaction(uint256 _id) {
        require(
            tokenToState[_id] == State.IN_TRANSACTION,
            "RealEstate: Require state is iN_TRANSACTION"
        );
        _;
    }

    modifier onlyOwnerOf(uint256 _id) {
        require(
            _checkExitInArray(tokenToOwners[_id], msg.sender),
            "RealEstate: You're not owner of certificate"
        );
        _;
    }

    function getOwnersOf(uint256 _id) public view returns (address[] memory) {
        return tokenToOwners[_id];
    }

 
    function getOwnerApproved(uint256 _id)
        public
        view
        returns (address[] memory)
    {
        return tokenToApprovals[_id];
    }

 
    function setRoleContractAddress(IRBAC _contractAddress) public {
        require(owner == msg.sender, "RealEstate: Require owner");
        roleContract = _contractAddress;
    }

 
    function createCertificate(
        string memory _certificate,
        address[] memory _owners
    ) public {
        require(
            roleContract.hasRole(msg.sender, 1),
            "RealEstate: Require notary"
        );
        // require owner not to be notary(msg.sender)
        require(
            !_checkExitInArray(_owners, msg.sender),
            "RealEstate: You are not allowed to create your own property"
        );
        certificateCount = certificateCount.add(1);
        tokenToCert[certificateCount] = _certificate;
        tokenToOwners[certificateCount] = _owners;
        tokenToNotary[certificateCount] = msg.sender;
        emit NewCertificate(certificateCount, _owners, msg.sender);
    }


    function activate(uint256 _id) public onlyOwnerOf(_id) onlyPending(_id) {
        require(
            !_checkExitInArray(tokenToApprovals[_id], msg.sender),
            "RealEstate: Account already approved"
        );
        // store msg.sender to list approved
        tokenToApprovals[_id].push(msg.sender);
        // if all owner approved => set state of certificate to 'ACTIVATED'
        if (tokenToApprovals[_id].length == tokenToOwners[_id].length) {
            tokenToState[_id] = State.ACTIVATED;
            // set user approve to null
            delete tokenToApprovals[_id];
        }
        emit Activate(_id, msg.sender, tokenToState[_id]);
    }

   