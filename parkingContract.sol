pragma solidity 0.4.25;

contract ParkingContract{

    address private _owner; // address of owner of property, used for payment after parking
    address private _driver; // address of driver, used to refund deposit
    string private _physical_address; // physical address of parking space
    uint256 private _deposit; // driver pays deposit first, then gets refunded the balance after the fee
    uint private _fee;
    enum Parking_state{AVAILABLE, NEED_OWNER_VERIFICATION, READY_TO_START, IN_USE, REQUEST_TO_END}
    Parking_state private _parking_state;

    constructor(string physical_address, uint deposit, uint fee) public{
        _owner = msg.sender;
        require(bytes(physical_address).length!=0, "please specify a physical address"); // check for empty string
        _physical_address = physical_address;
        require(deposit>fee, "deposit should be larger than parking fee"); // deposit should be larger than parking fee
        require(deposit>0, "deposit should be greater than zero");
        require(fee>0, "fee should be greater than zero");
        _deposit = deposit;
        _fee = fee;
        _parking_state = Parking_state.AVAILABLE;
    }

    function get_contract_details() public view returns(string, uint256, uint256){
        // This function's purpose is to view the contract details
        return(_physical_address, _deposit, _fee);
    }

    function get_state() public view returns(Parking_state){
        return(_parking_state);
    }

    function challenge() public notOwner{
        // owner has no need to challenge himself and waste gas
        require(_parking_state==Parking_state.AVAILABLE, "Can only challenge when parking state is: (0)AVAILABLE");
        _parking_state = Parking_state.NEED_OWNER_VERIFICATION;
    }

    function complete_challenge() public onlyOwner{
        // only the owner can chose to move the parking_state forwards after verification
        require(_parking_state == Parking_state.NEED_OWNER_VERIFICATION, "Can only call when state is: (1)NEED_OWNER_VERIFICATION");
        _parking_state = Parking_state.READY_TO_START;
    }

    function reset_parking_state() public{
        // This is in the case where driver challenges, but decides not to park
        // should not be able to reset while lot in use
        require(_parking_state != Parking_state.AVAILABLE, "Parking state is already (0)AVAILABLE"); // to save gas from other statements
        require(_parking_state != Parking_state.IN_USE, "Can only reset parking state when parking state is: not IN_USE");
        require(_parking_state != Parking_state.REQUEST_TO_END, "Can only reset parking state when parking state is: not (4)REQUEST_TO_END");
        _parking_state = Parking_state.AVAILABLE;
    }

    function start_parking() public payable notOwner{
        // the owner has no need to pay for parking in his own space (and wasting gas)
        require(_parking_state != Parking_state.IN_USE, "Parking state already (3)IN_USE");
        require(_parking_state != Parking_state.REQUEST_TO_END, "Already requested to end parking, cannot start again");
        require(_parking_state != Parking_state.AVAILABLE, "Please challenge owner first");
        require(_parking_state != Parking_state.NEED_OWNER_VERIFICATION, "Please wait for owner verification");
        require(_parking_state == Parking_state.READY_TO_START, "Please challenge owner first");
        require(msg.value == _deposit, "Please specify the correct deposit amount");
        _parking_state = Parking_state.IN_USE;
        _driver = msg.sender;
    }

    function request_end_parking() public onlyDriver{
        // only the driver parking should be able to request to end the parking session
        require(_parking_state == Parking_state.IN_USE, "Can only request end parking when parking state is: (3)IN_USE");
        _parking_state = Parking_state.REQUEST_TO_END;
    }

    function approve_end_parking() public onlyOwner{
        // checks
        // only the owner should be able to approve the end of Parking_state
        require(_parking_state == Parking_state.REQUEST_TO_END, "Can only end parking when parking state is: (4)REQUEST_TO_END");
        uint256 tmp_refund = _deposit-_fee;
        uint256 tmp_fee = _fee;
        // the fees should be less than the deposit at all times
        // changing either should have been checked, but just in case of underflow
        require(tmp_refund < _deposit, "Underflow detected: Kindly find the developer and scream at him");
        // effects
        _parking_state = Parking_state.AVAILABLE;
        address tmp_driver = _driver;
        _driver = 0;
        // interactions
        tmp_driver.transfer(tmp_refund);
        _owner.transfer(tmp_fee);
    }

    function change_deposit(uint256 new_deposit) public onlyOwner{
        // only owner should be able to change the deposit amount
        // and owner should only be able to do this when no driver is parking
        // or after the challenge (because the driver may already have read the contract and wants to accept)
        require(_parking_state == Parking_state.AVAILABLE, "Parking state must be available to change deposit");
        require(new_deposit>_fee, "deposit should be larger than parking fee"); // deposit should be larger than parking fee
        require(new_deposit>0, "new deposit should be greater than zero");
        _deposit = new_deposit;
    }

    function change_fee(uint256 new_fee) public onlyOwner{
        // only owner should be able to change the deposit amount
        // and owner should only be able to do this when no driver is parking
        // or after the challenge (because the driver may already have read the contract and wants to accept)
        require(_parking_state == Parking_state.AVAILABLE,  "Parking state must be available to change deposit");
        require(_deposit>new_fee, "deposit should be larger than parking fee"); // deposit should be larger than parking fee
        require(new_fee>0, "new fee should be greater than zero");
        _fee = new_fee;
    }


    modifier onlyOwner{
        require(msg.sender==_owner, "Error: Only owner can call this");
        _;
    }

    modifier notOwner{
        require(msg.sender!=_owner, "Error: Owner should not need to call this");
        _;
    }

    modifier onlyDriver{
        require(msg.sender==_driver, "Error: Only driver can call this");
        _;
    }

}