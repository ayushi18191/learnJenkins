/*****************************************************************************************************************
 * Copyright by Autodesk, Inc.
 * 
 * The information contained herein is confidential, proprietary to
 * Autodesk, Inc., and considered a trade secret as defined in section
 * 499C of the penal code of the State of California. Use of
 * this information by anyone other than authorized employees of 
 * Autodesk, Inc. is granted only under a written non-disclosure
 * agreement, expressly prescribing the scope and manner of such use.
 * 
 * $Id$ : ABSM_AccountOwnerUtilityTest
 * $Created Date$ : 31-May-2019
 * $Author$ : @mit
 * $Description$ : Test Class for ABSM_AccountOwnerUtility
 ********************************************************************************************************************/
@isTest(SeeAllData=false)
public class ABSM_AccountOwnerUtilityTest {
    /**
    *  Description: Create test data for Test Class
    *  @name      : createTestData
    **/
    @testsetup
    static void createTestData(){
        List<Account> accList = new List<Account>();
        Account testAccount = new Account(GEO__c = 'APAC',Name = 'TestAccount',Type = 'Distributor',Verification_Status__c = 'Verified',Account_CSN__c='123456', Country_Picklist__c = 'Japan', Named_Account__c = true);
        accList.add(testAccount);
        Account testAccount1 = new Account(GEO__c = 'EMEA',Name = 'TestAccount1',Type = 'Distributor',Verification_Status__c = 'Verified',Account_CSN__c='1234567', Country_Picklist__c = 'Albania', Named_Account__c = true);
        accList.add(testAccount1);
        //@mit: updating the GEO to EMEA from AMERICAS, for negative testing and covering scneario when there is no GEO match
        Account testAccount2 = new Account(GEO__c = 'EMEA',Name = 'TestAccount2',Type = 'Distributor',Verification_Status__c = 'Verified',Account_CSN__c='12345678', Country_Picklist__c = 'Argentina', Named_Account__c = true);
        accList.add(testAccount2);
        //@mit:
        Account nonNamedAccount = new Account(GEO__c = 'AMERICAS',Name = 'TestAccount2',Type = 'Distributor',Verification_Status__c = 'Verified',Account_CSN__c='123456789', Country_Picklist__c = 'Argentina');
        accList.add(nonNamedAccount);
        Account partnerAccount = new Account(GEO__c = 'AMERICAS',Name = 'TestAccount2',Type = 'Distributor',Verification_Status__c = 'Verified',Account_CSN__c='1234567890', Country_Picklist__c = 'Argentina', ispartner__c = true, CPM_Admin_User__c = UserInfo.getUserEmail(), Customer_Account_Group__c='Ship-To Party' );
        accList.add(partnerAccount);
        Database.insert(accList,true);
        
        Profile p = [Select p.Name, p.Id From Profile p where p.Name ='Autodesk Sales Service User'];
        
        List<User> userList = new List<User>();
        User partnerUser1 = new User();
        partnerUser1.LastName ='Test_name2121212121213';
        partnerUser1.Alias ='user1';
        partnerUser1.Email ='testemail'+Math.round(Math.random()*Math.pow(10, 7))+'@testemail.com';
        partnerUser1.Username ='testemail'+Math.round(Math.random()*Math.pow(10, 7))+'@testemai.com';
        partnerUser1.CommunityNickname = 'TestCommunityName123243';
        partnerUser1.ProfileId = p.Id;
        partnerUser1.TimeZoneSidKey ='Asia/Kolkata';
        partnerUser1.LocaleSidKey ='en_IN';
        partnerUser1.EmailEncodingKey ='UTF-8';
        partnerUser1.LanguageLocaleKey ='en_US';
        userList.add(partnerUser1);
        
        
        User partnerUser2 = new User();
        partnerUser2.LastName ='Test_name21212121212';
        partnerUser2.Alias ='user2';
        partnerUser2.Email ='testemail'+Math.round(Math.random()*Math.pow(10, 7))+'@testemail.com';
        partnerUser2.Username ='testemail'+Math.round(Math.random()*Math.pow(10, 7))+'@testemai.com';
        partnerUser2.CommunityNickname = 'TestCommunityName12324';
        partnerUser2.ProfileId = p.Id;
        partnerUser2.TimeZoneSidKey ='Asia/Kolkata';
        partnerUser2.LocaleSidKey ='en_IN';
        partnerUser2.EmailEncodingKey ='UTF-8';
        partnerUser2.LanguageLocaleKey ='en_US';
        userList.add(partnerUser2);
        
        User partnerUser3 = new User();
        partnerUser3.LastName ='Test_name212121212123';
        partnerUser3.Alias ='user3';
        partnerUser3.Email ='testemail'+Math.round(Math.random()*Math.pow(10, 7))+'@testemail.com';
        partnerUser3.Username ='testemail'+Math.round(Math.random()*Math.pow(10, 7))+'@testemai.com';
        partnerUser3.CommunityNickname = 'TestCommunityName12384';
        partnerUser3.ProfileId = p.Id;
        partnerUser3.TimeZoneSidKey ='Asia/Kolkata';
        partnerUser3.LocaleSidKey ='en_IN';
        partnerUser3.EmailEncodingKey ='UTF-8';
        partnerUser3.LanguageLocaleKey ='en_US';
        userList.add(partnerUser3);
        
        Database.insert(userList, true);
        /***PJABSM-2548: commented below
        // creating regional portfolios
        List<Regional_Portfolio__c> regPortList = new List<Regional_Portfolio__c>();
        Regional_Portfolio__c regP1 = new Regional_Portfolio__c(Portfolio_Status__c='Active',OwnerId=partnerUser2.id,Director_ID__c=partnerUser1.id,Fiscal_Year__c='2020',GEO__c='AMER');
        regPortList.add(regP1);
        Regional_Portfolio__c regP2 = new Regional_Portfolio__c(Portfolio_Status__c='Active',OwnerId=partnerUser2.id,Director_ID__c=partnerUser1.id,Fiscal_Year__c='2020',GEO__c='APAC');
        regPortList.add(regP2);
        Regional_Portfolio__c regP3 = new Regional_Portfolio__c(Portfolio_Status__c='Active',OwnerId=partnerUser2.id,Director_ID__c=partnerUser1.id,Fiscal_Year__c='2020',GEO__c='EMEA');
        regPortList.add(regP3);
        Regional_Portfolio__c regP4 = new Regional_Portfolio__c(Portfolio_Status__c='Active',OwnerId=partnerUser2.id,Director_ID__c=partnerUser1.id,Fiscal_Year__c='2021',GEO__c='AMER');
        regPortList.add(regP4);
        Regional_Portfolio__c regP5 = new Regional_Portfolio__c(Portfolio_Status__c='Active',OwnerId=partnerUser2.id,Director_ID__c=partnerUser1.id,Fiscal_Year__c='2021',GEO__c='APAC');
        regPortList.add(regP5);
        Regional_Portfolio__c regP6 = new Regional_Portfolio__c(Portfolio_Status__c='Active',OwnerId=partnerUser2.id,Director_ID__c=partnerUser1.id,Fiscal_Year__c='2021',GEO__c='EMEA');
        regPortList.add(regP6);
        Database.insert(regPortList, true);
        
         // creating a SRP
        List<Sales_Rep_Portfolio__c> SRPList = new List<Sales_Rep_Portfolio__c>();
        Sales_Rep_Portfolio__c salesRepP1 = new Sales_Rep_Portfolio__c(Portfolio_Status__c='Active',Regional_Portfolio__c=regP1.Id,Portfolio_Description__c='SRP1',SalesRep_ID__c = partnerUser3.id,OwnerId=partnerUser3.id);
        SRPList.add(salesRepP1);
        Sales_Rep_Portfolio__c salesRepP2 = new Sales_Rep_Portfolio__c(Portfolio_Status__c='Active',Regional_Portfolio__c=regP2.Id,Portfolio_Description__c='SRP2',SalesRep_ID__c = partnerUser3.id,OwnerId=partnerUser3.id);
        SRPList.add(salesRepP2);
        Sales_Rep_Portfolio__c salesRepP3 = new Sales_Rep_Portfolio__c(Portfolio_Status__c='Active',Regional_Portfolio__c=regP3.Id,Portfolio_Description__c='SRP3',SalesRep_ID__c = partnerUser3.id,OwnerId=partnerUser3.id);
        SRPList.add(salesRepP3);
        Database.insert(SRPList, true);
        
        List<Portfolio_Member__c> pmList = new List<Portfolio_Member__c>();
        Portfolio_Member__c portfolioMember1 = new Portfolio_Member__c(Account_CSN__c=testAccount.id,Portfolio_Member_Status__c='Active' , Sales_Rep_Portfolio__c=salesRepP1.id,Qlikview_Ref_ID__c='',Potential_Score__c='LOW');
        pmList.add(portfolioMember1);
        Portfolio_Member__c portfolioMember2 = new Portfolio_Member__c(Account_CSN__c=testAccount.id,Sales_Rep_Portfolio__c=salesRepP2.id,Qlikview_Ref_ID__c='',Potential_Score__c='MEDIUM',Portfolio_Member_Status__c='Active' , Assigned_Country__c = 'Japan',NAG__c = 'Named Account' );
        pmList.add(portfolioMember2);
        Portfolio_Member__c portfolioMember3 = new Portfolio_Member__c(Account_CSN__c=testAccount1.id, Portfolio_Member_Status__c='Active',Sales_Rep_Portfolio__c=salesRepP3.id,Qlikview_Ref_ID__c='',Assigned_Country__c = '',Potential_Score__c='HIGH');
        pmList.add(portfolioMember3);
        Portfolio_Member__c portfolioMember4 = new Portfolio_Member__c(Account_CSN__c=testAccount2.id, Portfolio_Member_Status__c='Active',Sales_Rep_Portfolio__c=salesRepP1.id,Qlikview_Ref_ID__c='',Assigned_Country__c = 'Anguilla',Potential_Score__c='HIGH');
        pmList.add(portfolioMember4);
        Database.insert(pmList, false);
        
        List<Customer_Account_Team_Member__c> CATRecordToInsert =  new List<Customer_Account_Team_Member__c>(); 
        Customer_Account_Team_Member__c custAccNewRecord = new Customer_Account_Team_Member__c();
                            
         custAccNewRecord.End_Customer_Account__c = testAccount.ID ;
         custAccNewRecord.Team_Member__c= testAccount.OwnerID ;
         custAccNewRecord.GEO__c = testAccount.Geo__c ;
         custAccNewRecord.Role__c = 'Account CSM Manager' ;
         CATRecordToInsert.add(custAccNewRecord);
        
        Customer_Account_Team_Member__c custAccNewRecord1 = new Customer_Account_Team_Member__c();
                            
         custAccNewRecord1.End_Customer_Account__c = testAccount.ID ;
         custAccNewRecord1.Team_Member__c= testAccount.OwnerID ;
         custAccNewRecord1.GEO__c = testAccount.Geo__c ;
         custAccNewRecord1.Role__c = 'Account Owner';
         CATRecordToInsert.add(custAccNewRecord1);
        
        database.insert(CATRecordToInsert) ;
        ***/
    }
    /***PJABSM-2548: commented below
    @istest
    static void accountOwnerUpdateTest(){
        
        Map<String,Regional_portfolio__C> regPort = new Map<String,Regional_portfolio__C>([select Id, name ,GEO__c  From Regional_portfolio__C where GEO__c = 'APAC' OR GEO__c = 'EMEA' OR GEO__c = 'AMER']);
        Test.startTest();
            Mustang_BatchProcessAccountUpdate batch = new Mustang_BatchProcessAccountUpdate(regPort.keySet());
            database.executeBatch(batch);
        Test.stopTest();
        Account testAccount2 = [Select Id,ownerId from Account where Name = 'testAccount2' limit 1];
        System.assertEquals(testAccount2.ownerId,System.label.CM_ADMIN_USERID);
    }***/
    
    /**
    *  Description: @mit: Negative Testing, owner should revert back to CM_ADMIN when there is no GEO match for Portfolio
    *  @name      : createTestData
    **/
    @istest
    static void noGeoMatchTest(){
        
        Account testAccount2 = [Select Id from Account where Name = 'testAccount2' AND Named_Account__c = true limit 1];
        Test.startTest();
            //@mit:
            testAccount2.ownerId = UserInfo.getUserId();
            update testAccount2;
            testAccount2 = [Select Id,ownerId from Account where Name = 'testAccount2' limit 1];
            System.assertEquals(testAccount2.ownerId,System.label.CM_ADMIN_USERID);
            Account childAccount = new Account(GEO__c = 'APAC',Name = 'TestChildAccount',Type = 'Distributor',Verification_Status__c = 'Verified',Account_CSN__c='423456789', Country_Picklist__c = 'Japan', ParentId = testAccount2 .Id);
            insert childAccount;
            Account testAccount1 = [Select Id from Account where Name = 'TestAccount1' AND Named_Account__c = true limit 1];
            childAccount.ParentId = testAccount1.Id;
            update childAccount;
            childAccount.ParentId = null;
            update childAccount;
        Test.stopTest();
    }
}