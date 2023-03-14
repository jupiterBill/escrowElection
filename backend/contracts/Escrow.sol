// SPDX-License-Identifier: MIT
pragma solidity  >=0.8.9 <=0.8.17;
contract Escrow {
     address escrowCompanyCeo;
     address[] Agents;
     mapping (address => uint256[]) myTransactions;
     struct Transaction{
         string transactionName;
         bool buyerCondition;
         bool sellerCondition;
         bool fundTransferred;
         address Seller;
         address Buyer;
         address Agent;
         uint256 payment;
     }
    Transaction [] transactions;
    uint256 transactionCount;

     constructor(){
         Agents.push (msg.sender);
         escrowCompanyCeo = msg.sender;
     }

     modifier onlyAgent(uint256 AgentIndex, uint256 transactionIndex){
         require(Agents[AgentIndex] == transactions[transactionIndex].Agent,"Sorry Agent you're not in charge of this fund");
         _;
     }
     modifier onlyPartiesInvolved(uint256 transactionIndex, uint256 AgentIndex){
         require(
             msg.sender == transactions[transactionIndex].Buyer||
             msg.sender == transactions[transactionIndex].Seller||
             Agents[AgentIndex] == transactions[transactionIndex].Agent,
             "Sorry Only Parties Involved can perform this operation"
         );
         _;
     }
     function registerAgent(address newAgent) external {
         require(msg.sender == escrowCompanyCeo,"only CEO can hire new agents");
         Agents.push(newAgent);
     }
     function registerParties(address Seller, string memory transactionName,uint256 AgentIndex) external payable{
        require(AgentIndex < Agents.length , "Sorry no Agent with that index");
        require (msg.value > 0, "Sorry funds has to be greater than zero");  
        transactions.push(Transaction(transactionName,false,false,false,Seller,msg.sender,Agents[AgentIndex],msg.value));
        myTransactions[msg.sender].push(transactionCount);
        myTransactions[Seller].push(transactionCount);
        transactionCount++;
     }
     
     function getTransaction(uint256 transactionIndex) external view returns (Transaction memory){
         return transactions[transactionIndex];
     }
    
     function getMyTransactions() external view returns(Transaction[] memory){
         uint256  myTL = myTransactions[msg.sender].length;
         if(myTL > 0){
         Transaction[] memory tempTransactions;
         for(uint256 i =0; i < myTransactions[msg.sender].length;i ++){
            tempTransactions[i] = transactions[i];
         }
         return(tempTransactions);
         }
     }
    function buyerSatisfied(uint256 transactionIndex) external {
           require(transactionIndex < transactions.length, "Sorry transaction doesnt exist");
           require(transactions[transactionIndex].Buyer == msg.sender, "Sorry you are not the buyer");
           transactions[transactionIndex].buyerCondition = true;
    }
    function sellerSatisfied(uint256 transactionIndex) external {
        require(transactionIndex < transactions.length, "Sorry transaction doesnt exist");
        require(transactions[transactionIndex].Seller == msg.sender, "Sorry you are not the buyer");
           transactions[transactionIndex].sellerCondition = true;
    }
    //transferring 95% of funds to the seller deducting a 5% holding fee
    function transferFunds(uint256 transactionIndex, uint256 AgentIndex) external onlyAgent(AgentIndex,transactionIndex){
           require(AgentIndex < Agents.length && transactionIndex < transactions.length, "invalid Agent Index or transaction Index");
           require(transactions[transactionIndex].buyerCondition && transactions[transactionIndex].buyerCondition, "Both parties are yet to approve funds to be transferred");
           uint256 fund = transactions[transactionIndex].payment;
           uint256 finalFund = (fund*95)/100;
           address recipient = transactions[transactionIndex].Seller;
           (bool sent, ) =  recipient.call{value: finalFund}("");
           require(sent, "Failed to send Ether");
           transactions[transactionIndex].fundTransferred = true;
    }

    function cancelTransaction(uint256 transactionIndex, uint256 AgentIndex) external  onlyPartiesInvolved(transactionIndex,AgentIndex) {
           require (!transactions[transactionIndex].buyerCondition && !transactions[transactionIndex].buyerCondition,"Sorry Both parties already agreed");
           delete transactions[transactionIndex];
    }
}