/**************************************************************************************************************
* Copyright by Autodesk, Inc.
* 
* The information contained herein is confidential, proprietary to
* Autodesk, Inc., and considered a trade secret as defined in section
* 499C of the penal code of the State of California. Use of
* this information by anyone other than authorized employees of 
* Autodesk, Inc. is granted only under a written non-disclosure
* agreement, expressly prescribing the scope and manner of such use.
* 
* $Id$ : ABSM_AccountOwnerUtility
* $Created Date$ :  04/29/2019
* $Author$ : Amit Pundir (ABSM)
* $Description$ : PJABSM-951: Consolidated Logic for Account Owner Updates
* $Test Coverage$ : 90% Mustang_BatchProcessAccountUpdateTest
* $Modified Date$ : 12/17/2019
* $Description$ : PJABSM-1843: moved the Portfolio account transfer logic to Heroku	   
* $Modified Date$ : 04/30/2020
* $Description$ : PJABSM-2548: limit the account ownership logic to non-individual partner type accounts
                  non-individual non-partner type account owner will be driven from Heroku
**************************************************************************************************************/
public without sharing class ABSM_AccountOwnerUtility {
    
    public static Map<Id,List<Portfolio_Member__c>>account_PortfolioMembersMap = new Map<Id,List<Portfolio_Member__c>>();
    public static set <Id> updatedAccountId = new set<Id>();//use this set in child batch to update account owner 
    
    /**
    *  @description      : use this method when Account Ids are sent
    *  @name             : calculateAccountOwner
    *  @param            : set<Id>
    *  @throws exception : NONE
    
    public static List<Account> calculateAccountOwner(set<Id> accountIdSet) {
        List<Account>accountList = getAccounts(accountIdSet);
        return calculateAccountOwner(accountList);
    }**/
    
    /**
    *  @description      : use this method to avoid SOQL when Account files are available in Trigger
    *  @name             : calculateAccountOwner
    *  @param            : List<Account>
    *  @throws exception : NONE
    **/
    public static List<Account> calculateAccountOwner(List<Account>accountList) {
        
		/***PJABSM-2548: changes starts							   
        Set<Id> mustangGenericOwnerIds = new Set<Id>();
        mustangGenericOwnerIds = getMustangGenericUserIds('MSTNG_GenericOwnerIds');
        //create set of GP Accounts else for child Accounts, map will be empty
        set<Id>globalParentAccountIds = new set<Id>();
        Set<Id> partnerAccounts = new Set<Id>();
        Set<string> userNames = new Set<string>();
		//PJABSM-1928: bypass child Portfolio Accounts
		set<Id>globalParentIdSet = new set<Id>();
		for(Account acc: accountList){
			if(String.isNotBlank(acc.GP_Account__c) ){
				globalParentIdSet.add(acc.GP_Account__c);
			}
		}
		//for(Portfolio_Member__c pm: [select id, Account_CSN__c from Portfolio_Member__c where Account_CSN__c IN: accountList]){
		//PJABSM-1928: bypass child Portfolio Accounts changes ends
        for(Portfolio_Member__c pm: [select id, Account_CSN__c from Portfolio_Member__c where Account_CSN__c IN: globalParentIdSet]){
			if(account_PortfolioMembersMap.containsKey(pm.Account_CSN__c) ){
				account_PortfolioMembersMap.get(pm.Account_CSN__c).add(pm);
			}else{
				account_PortfolioMembersMap.put(pm.Account_CSN__c,new List<Portfolio_Member__c>{pm});
			}
		}***/
		Set<Id> partnerAccounts = new Set<Id>();
        Set<string> userNames = new Set<string>();
        Map<String, ASA_Heroku_Configuration__c> asa_heroku_configuration = ASA_Heroku_Configuration__c.getAll();
        String partnerType = '';
        set<String> partnerTypes = new set<String>();
        if( asa_heroku_configuration.containsKey('partner_account_type') && 
            asa_heroku_configuration.get('partner_account_type').Value__c != null){
            partnerType = asa_heroku_configuration.get('partner_account_type').Value__c;
        }else{
            partnerType = 'Internal,Reseller,Distributor,ISV,Build,A.D.N.,Training Center,Vendor';
	
        }
		partnerTypes.addAll(partnerType.split(','));
        for(Account acc: accountList){
            //Non - Named Account
            /**AccountVerificationProcessTrigger Logic**/
			/**PJABSM-1843:
            if (acc.Named_Account__c != true 
                    && acc.Named_Account_Child__c != 'Yes' 
                    && acc.Named_Account_Grand_Child__c != 'Yes' 
                    && acc.Portfolio_Member_NAG__c == null) {
					**/
			/***PJABSM-2548: limit the account ownership logic to non-individual partner type accounts
			if (!account_PortfolioMembersMap.containsKey(acc.GP_Account__c) ){ //PJABSM-1928: bypass child Portfolio Accounts also						  
                system.debug('Non Portfolio Account'+acc.Id);   
                if (acc.ispartner__c == true ) {
                    if(String.isNotBlank(acc.CPM_Admin_User__c) ){
                        userNames.add(acc.CPM_Admin_User__c);
                        partnerAccounts.add(acc.Id);
                    }
                }else if (acc.Account_CSN__c != null) {
                     acc.OwnerId = System.label.CM_ADMIN_USERID;
                }
            }else{
                globalParentAccountIds.add(acc.GP_Account__c);
            }***/
            if( partnerTypes.contains(acc.Type) && acc.Individual_Flag__c == false) {
                if(String.isNotBlank(acc.CPM_Admin_User__c) ){
                    userNames.add(acc.CPM_Admin_User__c);
                    partnerAccounts.add(acc.Id);
                }else if (acc.Account_CSN__c != null) {
                     acc.OwnerId = System.label.CM_ADMIN_USERID;
                }
            }							
        }
        
        //Partner Accounts Owner Logic
        if(!partnerAccounts.isEmpty() ){
            Map<string,id> userNameToIdMap = new Map<string,id>();
            for (User u : [select id, Username from User where Username in :userNames]){
                userNameToIdMap.put(u.Username,u.id);
            }
            for(Account acc: accountList){
                if(partnerAccounts.contains(acc.Id) && userNameToIdMap.containsKey(acc.CPM_Admin_User__c) ){
                    acc.OwnerId = userNameToIdMap.get(acc.CPM_Admin_User__c);
                }
            }
        }
        
		return accountList;				   
		/***********************PJABSM-1843: POrtfolio Accounts Owner Logic moved to Heroku																				   
        if( globalParentAccountIds.isEmpty() ){//return if there are no Named Accounts; No need to use SOQL
            return accountList;
        }
        //get Active SRP Portfolio Members for current list of Accounts AND NOT assigned to genric users
        if( account_PortfolioMembersMap.isEmpty() ){//account_PortfolioMembersMap is initialized in MUSTANGE batch
            for(Portfolio_Member__c portMem: [Select Id , name ,NAG__c, Account_CSN__c,Account_CSN__r.Geo__c, 
                    Sales_Rep_Portfolio__r.Regional_Portfolio__r.Geo__c ,Sales_Rep_Portfolio__r.Regional_Portfolio__r.Name ,Account_Country__c, 
                    Assigned_Country__c, Sales_Rep_Portfolio__r.SalesRep_ID__c,Sales_Rep_Portfolio__r.OwnerId
                    from Portfolio_Member__c where 
                    Account_CSN__c IN : globalParentAccountIds
                    AND Sales_Rep_Portfolio__r.Portfolio_Status__c = 'Active' 
                    AND Sales_Rep_Portfolio__r.SalesRep_ID__c NOT IN: mustangGenericOwnerIds]){
                        
                if(account_PortfolioMembersMap.containsKey(portMem.Account_CSN__c) ){
                    account_PortfolioMembersMap.get(portMem.Account_CSN__c).add(portMem);
                }else{
                    account_PortfolioMembersMap.put(portMem.Account_CSN__c,new List<Portfolio_Member__c>{portMem});
                }
            }
        }
        system.debug('account_PortfolioMembersMap : '+ account_PortfolioMembersMap );
        for(Account acc: accountList){
            //MIDMARKET, Named Account Ownership Logic
            system.debug('Account Id: '+acc.Id);
            system.debug('account_PortfolioMembersMap containsKey acc Id: '+account_PortfolioMembersMap.containsKey(acc.Id));
            system.debug('account_PortfolioMembersMap containsKey acc GP_Account__c: '+account_PortfolioMembersMap.containsKey(acc.GP_Account__c));
            if(account_PortfolioMembersMap.containsKey(acc.Id) ||   //GP Accounts
                account_PortfolioMembersMap.containsKey(acc.GP_Account__c)){   //Child Accounts
                
                String regGeo = ''; String accountGeo = '';
                Boolean portfoloMatch = false;
                Portfolio_Member__c matchedPortfolio = new Portfolio_Member__c();
                for(Portfolio_Member__c portMember : account_PortfolioMembersMap.get(acc.GP_Account__c)){//use GP_Account__c to get PM for child or GP itself
                    
                    //max 3 iterations for each Account, assuming it is associated with 3 different GEO
                    regGeo = Label.MSTNG_AMER.equalsIgnoreCase(portMember.Sales_Rep_Portfolio__r.Regional_Portfolio__r.Geo__c)?(portMember.Sales_Rep_Portfolio__r.Regional_Portfolio__r.Geo__c).left(4):portMember.Sales_Rep_Portfolio__r.Regional_Portfolio__r.Geo__c;
                    //accountGeo = Label.MSTNG_AMER.equalsIgnoreCase(portMember.Account_CSN__r.Geo__c)?(portMember.Account_CSN__r.Geo__c).left(4):portMember.Account_CSN__r.Geo__c;
                    //consider current account GEO else child accounts were also owned based on parent GEO
                    accountGeo = Label.MSTNG_AMER.equalsIgnoreCase(acc.Geo__c)?(acc.Geo__c).left(4):acc.Geo__c;
                    
                    //find the best match for Account Owner
                    if(String.isNotBlank(regGeo) && regGeo.equalsIgnoreCase(accountGeo)){
                        matchedPortfolio = portMember;
                        portfoloMatch = true;
                        //only if GEO matches, we should match the country
                        String assignedCountries = portMember.Assigned_Country__c;
                        if(String.isBlank(assignedCountries) ){
                            matchedPortfolio = portMember;//Assigned Country Match 
                            portfoloMatch = true;
                        }
                        if(String.isNotBlank(assignedCountries) && String.isNotBlank(acc.Country__c) 
                            && assignedCountries.containsIgnoreCase(acc.Country__c) 
                            && (portMember.Sales_Rep_Portfolio__r.SalesRep_ID__c).equals(portMember.Sales_Rep_Portfolio__r.OwnerId)){
                            system.debug('assigned country found new owner is assigned');
                            matchedPortfolio = portMember;
                            portfoloMatch = true;
                            break;//best match when geo, country and owner matches, break the for loop
                        }
                    }
                }
                
                System.debug('Portfolio Match Found for Account Id:'+acc.Id + '?' +portfoloMatch);
                //once a mathcing PM is found
                if(portfoloMatch){
                    System.debug('matching portfolio: '+matchedPortfolio);
                    if( String.isNotBlank(matchedPortfolio.Sales_Rep_Portfolio__r.SalesRep_ID__c)
                        && (matchedPortfolio.Sales_Rep_Portfolio__r.SalesRep_ID__c).equals(matchedPortfolio.Sales_Rep_Portfolio__r.OwnerId) ){
                        //&& tobehired!=null && !(tobehired.Id).equals(matchedPortfolio.Sales_Rep_Portfolio__r.SalesRep_ID__c)){
                        //@mit: commented since we added genericUserIds check in query itself
                        
                        //MJA batch then picks it up for child Account Owner Update (based on IsOwnerUpdated__c flag)
                        if(matchedPortfolio.Sales_Rep_Portfolio__r.SalesRep_ID__c.equals(acc.OwnerID)){
                            if(String.isBlank(acc.parentId) ){
                                acc.IsOwnerUpdated__c = true; //update the flag to be picked by MJA Batch for child Account Owner Update
                            }
                        }else{
                            acc.OwnerID = matchedPortfolio.Sales_Rep_Portfolio__r.SalesRep_ID__c;
                            updatedAccountId.add(acc.Id);
                            //@mit: WF Rule updates the IsOwnerUpdated__c flag to true when owner changes for Named Account OR 
                            //PM Accounts with NAG value
                        }
                        if(String.isBlank(acc.parentId) ){
                            acc.Portfolio_Member_NAG__c = matchedPortfolio.NAG__c;//copy NAG value only for GP
                        }
                        
                    }
                }else{  //assign generic user if there is no portfolio match
                    if(acc.OwnerId != System.label.CM_ADMIN_USERID){
                        acc.OwnerId = System.label.CM_ADMIN_USERID;
                        updatedAccountId.add(acc.Id);
                    }
                }
            }//end of GP Account or Child Accounts with PM associated If condition
            
			
            //@mit: MJA_SubsidiaryAccUpdate Logic commented below, need to run Mustang Rules as Named_Account_Child__c = Yes
																							  
            //TODO: update the trigger to call the calculateAccountOwner method
				
            //else if(acc.ParentId != null && acc.Named_Account_Child__c == 'Yes'){
                //if(acc.OwnerId != acc.Parent.OwnerId ){
                  //acc.OwnerId = acc.Parent.OwnerId;
                //}
            //}
			
			
            //for mustang child acc - if there is no active SRP on parent then copy parent owner to child acc
            //OR if parent is assigned to generic, then copy generic owner in child as well
            else if (String.isBlank(acc.ParentId) && acc.OwnerId != System.label.CM_ADMIN_USERID) {
                //assign CM_ADMIN user for Named GP Accounts if no Portfolio is matched
                acc.OwnerId = System.label.CM_ADMIN_USERID;
                updatedAccountId.add(acc.Id);
            }else if (acc.ParentId != null && acc.Parent.OwnerId != null && acc.OwnerId != null && acc.OwnerId != acc.parent.OwnerId) {
                //copy parent owner for Child Accounts of Named Accounts
                acc.OwnerId = acc.parent.OwnerId;  //copy parent Account Owner ( for before insert, parent.OwnerId will be null)
                updatedAccountId.add(acc.Id);
            }
        }//end of Account For Loop


        return accountList;//return account list and update in calling method if needed
		PJABSM-1843: changes ends *****/								
    }

    /**
    *  @description      : use this method to query required fields if account Ids are sent
    *  @name             : getAccounts
    *  @param            : set<Id>
    *  @throws exception : NONE
    
    public static List<Account> getAccounts(set<Id> accountIdSet){
        return [select Id, name , Country__c, GP_Account__c, OwnerId,Geo__c, CPM_Admin_User__c, ParentId, Parent.OwnerID,  Named_Account__c , 
                Named_Account_Child__c, Named_Account_Grand_Child__c, Portfolio_Member_NAG__c, Account_CSN__c, ispartner__c  from Account where Id IN: accountIdSet];
    }**/

    /**
    *  @description      : retruns set of User Ids containing Genric users
    *  @name             : getMustangGenericUserIds
    *  @param            : set<Id>
    *  @throws exception : NONE
    
    public static Set<Id> getMustangGenericUserIds(String context){

        Set<Id> genericUserIds = new Set<Id>();
        Set<String> genericUsers= new Set<String>(); 
        genericUsers.add(System.Label.MSTNG_To_Be_Hired);//always add Mustang To Be Hired even if not added in custom setting
        Map<String, Settings__c> settings = Settings__c.getall();

        if(settings.containsKey(context) && settings.get(context).Value1__c != null){
            genericUsers.addAll(settings.get(context).Value1__c.split(';'));
        }
        for(User usr: [SELECT Id,Name from User where Name IN: genericUsers]){
            genericUserIds.add(usr.Id);
        }
        return genericUserIds;
    }**/
}