public with sharing class ABSM_AccAgreementsController {
    @AuraEnabled
    public static list<End_Customer_Contracts__c> getAgreements(String accId){
        if(accId!=null && accId!=''){
             return ([select id,Name from End_Customer_Contracts__c where Account__c=:accId]);
        }else{
            return null;
        }
       
    }
    
     @auraEnabled
    public static void trackUsage(String subFunctionality, String accountId) {
        try {   
            SalesAccountExplorerController.trackUsage(subFunctionality, accountId);
        } catch(Exception e) {
            system.debug('Exception in Class: ABSM_AccAgreementsController, Method:trackUsage: ' + e.getMessage());
        }
    }
    
}