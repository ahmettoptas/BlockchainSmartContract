pragma solidity >=0.6.0;


contract taxi {                 //B21627667 Ahmet Kasım Toptas
    
    struct Person{
        address address_;
        uint256 balance_;
        bool approvePurchaseVoting;                            
        bool approveSellVoting;
        bool approveDriverVoting;
    }
    
    struct CarDealer{
        address address_;
        uint256 balance_;
    }
    
    struct TaxiDriver{
        address address_;
        uint256 balance_;
        uint256 salary_;
        bool valid;                                         //valid for approved driver , 1 for approverd 0 for unapproved
    }
    
    
    

    struct Proposal{
        uint CarID;
        uint price;
        uint offerValidTime;
        bool buyOrSell;             //0 for buy-purchase, 1 for sell-repurchase
    }


    mapping (address => Person) Participants;
    mapping (uint32 => address) private ParticipantAdress;                      
    
    uint32 participantCount;
    

    uint8 apVotingCounter;
    
    uint8 asVotingCounter;

    uint8 adVotingCounter;


    address manager;
    
    
    TaxiDriver   taxiDriver;

    CarDealer   carDealer;

    
    Proposal purchaseProposal;
    Proposal repurchaseSellProposal;
    
    uint ContractBalance;
    
    uint releaseTime = 30 days;
    uint initialReleaseTime  = block.timestamp;      
    bool monthCheckerRelease = true;
    
    uint tax = 10 ether;
    
    uint maintanance_tax_time = 180 days;
    uint initial_maintanance_tax_time  = block.timestamp;        
    bool monthCheckerTax = true;
    
    uint payDivider_time = block.timestamp;
    bool payDividentChecker = true;

    
    uint ParticipationFee = 100 ether;
    
    uint ownedCarId;
    uint carIdModulus = 10 ** 32;         //for 32 digit carId
    
        
    uint32 expenseCounter = 0;
    uint32 payDivideCounter = 0;
    
    uint temp = 1 ether;                    // converter to ether
    
    
    
    modifier just_manager(){
        require(msg.sender == manager);
        _;
    }
    
        
    modifier just_participant(){
        require((Participants[msg.sender].address_)==msg.sender);
        _;
    }
    
    modifier just_taxiDriver(){
    require((taxiDriver.valid == true) && (taxiDriver.address_)==msg.sender);
    _;
    }
    
    
    modifier just_carDealer(){
    require((carDealer.address_)==msg.sender);
    _;
    }
    
    
    constructor() public{
    manager = msg.sender; 
    }
    
    function join() public payable {
        require((participantCount<9) && (Participants[msg.sender].address_)!=msg.sender);
        require((msg.sender != carDealer.address_));
        require(msg.sender != taxiDriver.address_);
        require(msg.sender != manager);
        require(msg.value == ParticipationFee);
        ContractBalance += ParticipationFee;
        uint32 j = 0;
        //ParticipantAdress[participantCount] = msg.sender;
        
        for (; j < 9; j++) {  //for loop example
            if(ParticipantAdress[j]==address(0)){
                break;
            }
                 
        }
        
        ParticipantAdress[j] = msg.sender;
        
        participantCount++;
        Participants[msg.sender] = Person(msg.sender, 0, false, false, false);       // address is sender ,0 is balance ,falses are votings

        
    }
    
    function deleteUser(address userAdress) public just_manager{
        payable(userAdress).transfer(ParticipationFee);

        delete Participants[userAdress];
        participantCount--;
        uint32 j = 0;

        for (; j < 9; j++) { 
            if(ParticipantAdress[j]==userAdress){
                break;
            }
        }
        delete ParticipantAdress[j];
        
    }
    
    
    function setCarDealer(address _dealerId) public just_manager {
        
        carDealer = CarDealer(_dealerId, 0);                                    // address is setted ,0 is balance, driver is valid 
        initial_maintanance_tax_time = block.timestamp;    

    }
    
    
    
    
    function carProposeToBusiness(uint _carId, uint price, uint validTime)public just_carDealer{
        require(_carId<uint(carIdModulus));                             //controls less than 33 digits
        uint id = _carId;                                                   
        uint time = block.timestamp + validTime;

        uint pr = price * temp;
        
        purchaseProposal = Proposal(id, pr, time, true);
        

        
    }
    
     function approvePurchaseCar() public just_participant {
        require(Participants[msg.sender].approvePurchaseVoting == false && purchaseProposal.CarID != 0);       //checks there is proposal
        Participants[msg.sender].approvePurchaseVoting = true;
        apVotingCounter++;
        
    }
    
        function changeVoteBuy() public just_participant{               //participant can change their actually votes or reset their votes for next purchase proposal
        
        require(Participants[msg.sender].approvePurchaseVoting == true);
        Participants[msg.sender].approvePurchaseVoting = false;
        apVotingCounter--;
        
    }
    


    function purchaseCar() public just_manager{
        require(purchaseProposal.CarID != 0 && purchaseProposal.offerValidTime >= block.timestamp &&  purchaseProposal.price < ContractBalance && purchaseProposal.buyOrSell == true);
        require(participantCount/2 < apVotingCounter);
        uint amount = purchaseProposal.price;
        
        carDealer.balance_ += amount;
        ContractBalance -= amount;
        
        ownedCarId = purchaseProposal.CarID;
        delete purchaseProposal;


        
        payable(carDealer.address_).transfer(amount);
    }
    
    
    function repurchaseCarPropose(uint _carId, uint price, uint validTime)public just_carDealer{
        
        uint id = _carId % carIdModulus;
        uint time = block.timestamp + validTime;

        uint pr = price * temp;
        
        repurchaseSellProposal = Proposal(id, pr, time, false);
        

    }
    
     function approveSellCar() public just_participant {
        require(Participants[msg.sender].approveSellVoting == false && repurchaseSellProposal.CarID != 0);
        Participants[msg.sender].approveSellVoting = true;
        asVotingCounter++;
        
    }
    
    function changeVoteSell() public just_participant{          //participant can change their actually votes or reset their votes for next sell repurchase proposal
        
        require(Participants[msg.sender].approveSellVoting == true);
        Participants[msg.sender].approveSellVoting = false;
        asVotingCounter--;
        
    }
    
    

    function repurchaseCar() public just_carDealer payable {
        require(msg.value == repurchaseSellProposal.price && repurchaseSellProposal.CarID != 0 && repurchaseSellProposal.offerValidTime >= block.timestamp && purchaseProposal.buyOrSell == false);
        require(participantCount/2 < asVotingCounter);
        

        carDealer.balance_ -= repurchaseSellProposal.price;
        ContractBalance += repurchaseSellProposal.price;
        delete repurchaseSellProposal;
        ownedCarId = 0;
        
    }
    

    function propeseDriver(address _dealerId,uint _ether) public just_manager {

        _ether = temp * _ether;
        taxiDriver = TaxiDriver(_dealerId, 0, _ether,false);                                    // address is setted ,0 is balance , 2 is taxiDriver 3 salary, 4 is valid
    }
        
    function approveDriver() public just_participant {
        require(Participants[msg.sender].approveDriverVoting == false && taxiDriver.address_ != address(0));
        Participants[msg.sender].approveDriverVoting = true;
        adVotingCounter++;
                                           
    }
    
        
    function changeVoteDriver() public just_participant{          //participant can change their actually votes or reset their votes for next sell repurchase proposal
        
        require(Participants[msg.sender].approveDriverVoting == true);
        Participants[msg.sender].approveDriverVoting = false;
        adVotingCounter--;
        
    }
    
    function setDriver()public just_manager{
        require(participantCount/2 < adVotingCounter && taxiDriver.valid==false);
        
        initialReleaseTime = block.timestamp;
        monthCheckerRelease = true;
        taxiDriver.valid = true;
        
        
    }
    
    function fireDriver()public just_manager{
        require(address(this).balance>=taxiDriver.salary_);
        payable(taxiDriver.address_).transfer(taxiDriver.salary_);
        ContractBalance -= taxiDriver.salary_;

        delete taxiDriver;
    }
    

    
    function payTaxiCharge()public payable{
        ContractBalance += msg.value;
    }


    
    function releaseSalary()public just_manager{
        if(monthCheckerRelease == false){
            if(initialReleaseTime + releaseTime <=  block.timestamp){
                monthCheckerRelease = true;
            }
        }
        require(monthCheckerRelease == true && taxiDriver.valid == true);
        taxiDriver.balance_+= taxiDriver.salary_;
        monthCheckerRelease = false;
        initialReleaseTime = block.timestamp;

    }
    
    function getSalary()public just_taxiDriver{
        require(address(this).balance >= taxiDriver.balance_ && taxiDriver.balance_ > 0);
        
        payable(taxiDriver.address_).transfer(taxiDriver.balance_);
        ContractBalance -= taxiDriver.balance_;
        taxiDriver.balance_ = 0;
        
    }



    
    function payCarExpenses()public just_manager{
        if(monthCheckerTax == false){
            if(initial_maintanance_tax_time + maintanance_tax_time <=  block.timestamp){
                monthCheckerTax = true;
            }
        }
        require(monthCheckerTax == true && address(this).balance>=tax);
        payable(carDealer.address_).transfer(tax);
        initial_maintanance_tax_time = block.timestamp;
        monthCheckerTax = false;
        ContractBalance -= tax;
        
        expenseCounter += 1;
    }

    
    function payDividend()public just_manager{
        require(expenseCounter == payDivideCounter + 1);
        if(payDividentChecker == false){
            if(payDivider_time + maintanance_tax_time <=  block.timestamp){
                payDividentChecker = true;
            }
        }
        require(payDividentChecker == true);
        uint incomePerCapita = ContractBalance/participantCount;
        
        uint32 j = 0;

        for (; j < 9; j++) { 
            if(ParticipantAdress[j]!=address(0)){
                Participants[ParticipantAdress[j]].balance_ += incomePerCapita;
            }
        }
        payDividentChecker = false;
        payDivider_time = block.timestamp;
        payDivideCounter += 1;
        
    }
    function getDividend()public just_participant{
        uint amount = Participants[msg.sender].balance_;
        payable(msg.sender).transfer(amount);
        Participants[msg.sender].balance_ = 0;
    }
    
    function contractBalanceView()public view returns(uint){
        return ContractBalance;
    }
    
    function addressBalanceView()public view returns(uint){
        return address(this).balance;
    }
    
    
    fallback() external {
        revert ();
    }


    
   
}
