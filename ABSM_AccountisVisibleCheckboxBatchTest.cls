// ClassName: ABSM_AccountisVisibleCheckboxBatchTest
// User Stories: PJABSM-3012
// Related class: ABSM_AccountisVisibleCheckboxBatch
// Author: Alex Lai
// Description: This test class tests the a batch class that looks for Contact records where the EBA Survey Date is older than 7 months and unchecks the checkbox.

@isTest 
public class ABSM_AccountisVisibleCheckboxBatchTest
{
    static testMethod void testMethod1() 
    {
        Account a = new Account(Name='Test Account',Country_Picklist__c='United States', Account_CSN__c='11111111111111');
        AccountTriggerOperations.SKIP_ACCOUNT_TRIGGER = true;
        insert a;
        Asset__c asset = new Asset__c(Name='TestAsset', End_Customer_Account__c=a.id, usage_type__c = 'COM');
        insert asset;

		
        Test.startTest();
            ABSM_AccountisVisibleCheckboxBatch obj = new ABSM_AccountisVisibleCheckboxBatch();
            DataBase.executeBatch(obj);   
        Test.stopTest();
        List<Account> acc = [SELECT Id, isvisible__c FROM Account WHERE Id =: a.Id];
        System.AssertEquals(true,acc[0].isvisible__c);
    }
}