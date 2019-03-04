pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ParameterStore.sol";
import "./Slate.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract Gatekeeper {
    // EVENTS
    event PermissionRequested(uint requestID, bytes metadataHash);
    event SlateCreated(uint slateID, address indexed recommender, bytes metadataHash);

    // STATE
    using SafeMath for uint256;

    uint constant ONE_WEEK = 604800;

    // The timestamp of the start of the first batch
    uint public startTime;
    uint public batchLength = ONE_WEEK * 13; // 13 weeks

    // Parameters
    ParameterStore public parameters;

    struct Request {
        bytes metadataHash;
        bool approved;
    }

    // The requests made to the Gatekeeper. Maps requestID -> Request.
    mapping(uint => Request) public requests;

    // The total number of requests created
    uint public requestCount;

    // The slates created by the Gatekeeper. Maps slateID -> Slate.
    mapping(uint => Slate) public slates;

    // The total number of slates created
    uint public slateCount;

    // IMPLEMENTATION
    /**
     @dev Initialize a Gatekeeper contract.
     @param _startTime The start time of the first batch
     @param _slateStakeAmount The number of tokens required to stake on a slate
    */
    constructor(uint _startTime, uint _slateStakeAmount) public {
        startTime = _startTime;

        uint length = 1;
        string[] memory names = new string[](length);
        uint[] memory values = new uint[](length);

        names[0] = "slateStakeAmount";
        values[0] = _slateStakeAmount;

        parameters = new ParameterStore(names, values);
    }

    /**
    * @dev Get the number of the current batch.
    */
    function currentBatchNumber() public view returns(uint) {
        uint elapsed = now.sub(startTime);
        uint batchNumber = elapsed.div(batchLength);

        return batchNumber;
    }

    /**
    * @dev Get the start of the current batch.
    */
    function currentBatchStart() public view returns(uint) {
        uint batchNumber = currentBatchNumber();
        return startTime.add(batchLength.mul(batchNumber));
    }

    // SLATE GOVERNANCE
    /**
    * @dev Create a new slate with the associated requestIds and metadata hash.
    * @param batchNumber The batch to submit for
    * @param category The category to submit the slate for
    * @param requestIDs A list of request IDs to include in the slate
    * @param metadataHash A reference to metadata about the slate
    */
    function recommendSlate(
        uint batchNumber,
        uint category,
        uint[] memory requestIDs,
        bytes memory metadataHash
    )
        public returns(uint)
    {
        // NOTE: all requestIDs must be valid
        // NOTE: category must be valid
        // NOTE: batchNumber must be the current one
        // NOTE: metadataHash must be valid

        // create slate
        Slate s = new Slate(msg.sender, metadataHash, requestIDs);

        // Record slate and return its ID
        uint slateID = slateCount;
        slates[slateID] = s;
        slateCount = slateCount.add(1);

        emit SlateCreated(slateID, msg.sender, metadataHash);
        return slateID;
    }

    // ACCESS CONTROL
    /**
    @dev Request permission to perform the action described in the metadataHash
    @param metadataHash A reference to metadata about the action
    */
    function requestPermission(bytes memory metadataHash) public returns(uint) {
        require(metadataHash.length > 0, "metadataHash cannot be empty");

        // Create new request
        Request memory r = Request({
            metadataHash: metadataHash,
            approved: false
        });

        // Record request and return its ID
        uint requestID = requestCount;
        requests[requestID] = r;
        requestCount = requestCount.add(1);

        emit PermissionRequested(requestID, metadataHash);
        return requestID;
    }
}
