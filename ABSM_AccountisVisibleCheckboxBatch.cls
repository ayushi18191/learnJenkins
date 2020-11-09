// ClassName: ABSM_AccountisVisibleCheckboxBatch
// User Stories: PJABSM-3012
// Author: Alex Lai
// Description: This batch class sets isVisible flag to True under the following conditions. Accounts that have Enrichable ="true", will have the isVisible flag set to true
// Accounts that have legacy source=EDU community, any newly created Accounts with this condition will be automatically hidden
// Accounts with asset end date greater than 2010, with usage type EDU, NFR, COM
// Accounts with agreements end date greater than 2010
// Accounts with Opportunities greater than 2010
// Accounts with Cases created date is greater than last 18 months

global class ABSM_AccountisVisibleCheckboxBatch implements Database.Batchable<sObject>, Database.stateful{

	integer accountsToUpdateCount = 0;
	private Integer updatedAccounts = 0;
    private Integer failedAccounts = 0;
    private Integer eligibleAccountCount = 0;
	private static final String ERR_RECORDID = '#Record Id:';
	private static final String ERRMSG = '#ErrMsg :';
    private static final String ERRFIELDS = '#Fields :';
	//test query
     // String query = 'Select id from account where lastmodifieddate = LAST_N_DAYS:1 and isvisible__c = false and Legacy_Source__c !=\''+'EDUCOMMUNITY'+'\'limit 100';
	
	//String query = 'Select id from account where isvisible__c = false and Legacy_Source__c !=\''+'EDUCOMMUNITY'+'\''; 
    String query = 'Select id, isvisible__c, Legacy_Source__c from account where Account_CSN__c !=\''+''+'\'';

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
	  
   }

   global void execute(Database.BatchableContext BC, List<account> scope){

	   Account [] accountsToUpdate = new List<Account>();
       integer cDays = integer.valueof(System.Label.Account_Visibility_Update_Days);	   
	
		for (Integer i = (scope.size()-1) ; i>= 0 ; i--){
			account eachAcc = scope[i];
			if(eachAcc.Legacy_Source__c == 'EDUCOMMUNITY' || eachAcc.isvisible__c == true){
				scope.remove(i);
			}
		} 
	
		
	   
		for (Account acc: [select id, isVisible__c, 
						(Select Id from Assets3__r where createddate > :Date.Today().addDays(cDays) and (usage_type__c = 'COM' OR usage_type__c = 'EDU' OR usage_type__c = 'NFR') Limit 1),
						(Select Id from Direct_Contracts__r where createddate > :Date.Today().addDays(cDays) Limit 1),
						(Select Id from Opportunities where createddate > :Date.Today().addDays(cDays) Limit 1),
						(Select Id from Cases where createddate > :Date.Today().addDays(cDays) Limit 1),
						(Select Id from Leads__r where createddate > :Date.Today().addDays(cDays) Limit 1)
						from Account WHERE id in: scope]) { 
											         
			if(!acc.Assets3__r.isEmpty() || !acc.Direct_Contracts__r.isEmpty() || !acc.Opportunities.isEmpty() || !acc.Cases.IsEmpty() || !acc.Leads__r.IsEmpty()){
				acc.isVisible__c = true;
				accountsToUpdateCount++;
				accountsToUpdate.add(acc);
				
			}
		} //End account for loop
		
		
		Database.SaveResult[] accUpdate;
		if(!accountsToUpdate.isEmpty()){	// added for logging and update -start
			system.debug('batch updating accounts:'+accountsToUpdate);
			AccountTriggerOperations.SKIP_ACCOUNT_TRIGGER = true;//PJABSM-951
			accUpdate = Database.update(accountsToUpdate,false);
			//PJABSM-860: changes starts
			String impactedRecordIds = '';
			String errorMessage = '';
			Boolean logBatchException = false;                
			for(Integer i=0; i<accUpdate.size(); i++) {
				system.debug('insidefor67>>>');
				if(!accUpdate[i].isSuccess() || test.isRunningTest()) {
					logBatchException = true;
					//Database.Error err = !accUpdate[i].getErrors().isEmpty() ? accUpdate[0].getErrors()[0] : null;
					Database.Error err = !accUpdate[i].getErrors().isEmpty() ? accUpdate[i].getErrors()[0] : null;
					impactedRecordIds += accountsToUpdate[i].Id +'\n';
					
					errorMessage += ERR_RECORDID+accountsToUpdate[i].Id;//@mit:error message was being overridden in every loop
					if(err != null) {
						errorMessage += ERRMSG + err.getMessage()+ERRFIELDS+err.getFields()+'\n';
						system.debug('errorMessage>>>'+errorMessage);
					}
					failedAccounts++; 
					system.debug('failedAccounts>>>'+failedAccounts);					
			
				}else{
					updatedAccounts++;
					system.debug('updatedAccounts>>>'+updatedAccounts);	
				}
			}
			if(logBatchException){
				logBatchException(errorMessage, impactedRecordIds, null, 'ABSM_AccountisVisibleCheckboxBatch', 'execute', 'ABSM_AccountisVisibleCheckboxBatch', 'Account', 'ACCOUNT_RECORD_UPDATE_FAILED', 'ARUF', bc);
			}//PJABSM-860: changes ends
		}// added for logging


		// AccountTriggerOperations.SKIP_ACCOUNT_TRIGGER = true;		
		// update accountsToUpdate;
		// AccountTriggerOperations.SKIP_ACCOUNT_TRIGGER = false;
    }

//added method for logging
    private static void logBatchException(String errorMessage, String impactedRecordIds, String recordId, String className, String methodName, String batchJobName, String objectName, String errorType, String errorSourceCode, Database.BatchableContext BC) {
        
        String apexJobId;
        String apexChildJobId;
        if(BC != null) {
            apexJobId = BC.getJobId();
            apexChildJobId = BC.getChildJobId();
        }
        Batch_Transaction_Log__c bt = new Batch_Transaction_Log__c(Batch_Job_Name__c = batchJobName, Impacted_Record_Id__c = recordId, Impacted_Record_Ids__c = impactedRecordIds, Object_Details__c=objectName, Error_Message__c = errorMessage, Class_Name__c = className, Method_Name__c = methodName, Error_Type__c = errorType, Apex_Job_Id__c = apexJobId, Job_Id__c = apexChildJobId, Error_Source_Code__c = errorSourceCode);
        system.debug('Log :' + bt);
        insert bt;
            
    }

   global void finish(Database.BatchableContext BC){
        //check parent batch status
        AsyncApexJob job = [SELECT CompletedDate,JobItemsProcessed,NumberOfErrors,Status,TotalJobItems,CreatedBy.Name,CreatedDate,ApexClassId FROM AsyncApexJob 
                            where Id = :bc.getJobId() limit 1];

        String errorMessage = '';
        String emailMessage = '';
        errorMessage += 'Apex Job Id:' + bc.getJobId()  + '\n';
        errorMessage += 'Job Created Date:' + job.CreatedDate  + '\n';
        errorMessage += 'Total number of batches:' + job.TotalJobItems  + '\n';
        errorMessage += 'Number of batches successfully processed:' + job.JobItemsProcessed  + '\n';
        errorMessage += 'Total Accounts Updated Successfully:' +updatedAccounts + '\n';
        errorMessage += 'Total Accounts Updated Failed:' +failedAccounts + '\n';   
    
        logBatchException(errorMessage, '', null, 'ABSM_AccountisVisibleCheckboxBatch', 'finish', 'ABSM_AccountisVisibleCheckboxBatch', null, 'SUMMARY_RECORD', '', bc);	   
   }
}