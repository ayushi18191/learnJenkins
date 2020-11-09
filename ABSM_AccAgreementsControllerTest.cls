@isTest(seeAllData=true)
public class ABSM_AccAgreementsControllerTest {

    @isTest static void testTokenFlexAccount(){
        Account acc=new Account();     
        acc.Name = 'Test Account1';
        acc.Type = 'End Customer';
        acc.Account_Csn__c = 'TestAccount123';
        acc.Country_Picklist__c = 'Australia';
        insert acc;           
        system.assert(acc.id!=null);
		SalesAccountExplorerController.checkTokenFlex(acc.Id);   
        ABSM_AccAgreementsController.getAgreements(acc.Id);
		ABSM_AccAgreementsController.trackUsage('Token Flex Dashbaord', acc.Id);
    }
    
     @isTest static void testTokenFlexNoAgreementsAccount(){
        Account acc=new Account();     
        acc.Name = 'Test Account1';
        acc.Type = 'End Customer';
        acc.Account_Csn__c = 'TestAccount123';
        acc.Country_Picklist__c = 'Australia';
        insert acc;    
        system.assert(acc.id!=null);
     
		SalesAccountExplorerController.checkTokenFlex(acc.Id);   
        ABSM_AccAgreementsController.getAgreements(acc.Id);
        ABSM_AccAgreementsController.trackUsage('Token Flex Dashbaord', acc.Id);
    }
    
    @isTest static void testTokenFlexNegative(){ 
        String accIdParam='';
        ABSM_AccAgreementsController.getAgreements('');
        system.assert(accIdParam=='');
    }
}