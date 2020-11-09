global without sharing class ABSM_activityEventReportBatch implements Database.Batchable<sObject>{
    //Test Class Name : ABSM_activityTaskReportBatchTest
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'select id, WhoId, whatId, Primary_Account__c from Event where CreatedDate ='+System.Label.ABSM_eventBatchStartDate+' And Primary_Account__c = Null';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Event> EventList){
        Set<Id> leadIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> whatIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        Set<Id> custEngIdSet = new Set<Id>(); 
        Set<Id> CasesIdSet = new Set<Id>();
        Set<Id> cusInitiativeIdSet = new Set<Id>();
        Set<Id> servEngIdSet = new Set<Id>();
        Set<Id> EndCusIdSet = new Set<Id>();
        Set<Id> servConsIdSet = new Set<Id>();
        Map<id, Event> updatedEventMap = new Map<id, Event>();
        String IdObjectType = NULL;
        for(Event evtObj : EventList){
            updatedEventMap.put(evtObj.Id, evtObj);
            if(evtObj.WhoId !=null){
                Id who_id = evtObj.WhoId;
                IdObjectType = String.valueOf(who_id.getsobjecttype());
                if(IdObjectType == 'Lead'){
                    leadIdSet.add(evtObj.WhoId);                                //Storing IDs of Lead
                }
                if(IdObjectType == 'Contact'){
                    contactIdSet.add(evtObj.WhoId);                             //Storing IDs of contact
                }
            }
            else{
                if(evtObj.WhatId !=null && evtObj.WhoId ==null){                                    //WhatId Section
                    whatIdSet.add(evtObj.WhatId);
                }
            }
        }
        Map<id,Lead> leadIdMap = new Map<id,Lead>();
        if(leadIdSet.size() > 0){
            leadIdMap = new Map<id,Lead>([select id,Account__c from Lead where Id IN:leadIdSet]);
        }
        Map<id,Contact> contactIdMap = new Map<id,Contact>();
        if(contactIdSet.size() > 0){
            contactIdMap = new Map<id,Contact>([select id, AccountId  from Contact where Id IN:contactIdSet]);
        }
        for(Event evtObj: EventList){
            if(evtObj.WhoId != Null){
                if(leadIdMap.get(evtObj.WhoId)!=null && leadIdMap.get(evtObj.WhoId).Account__c != null){
                    evtObj.Primary_Account__c = leadIdMap.get(evtObj.WhoId).Account__c;
                }
                else{
                    evtObj.Primary_Account__c = Null;
                }
                if(contactIdMap.get(evtObj.WhoId)!=null && contactIdMap.get(evtObj.WhoId).AccountId != null){
                    evtObj.Primary_Account__c = contactIdMap.get(evtObj.WhoId).AccountId;
                }
                else{
                    if(evtObj.WhatId != null){
                        whatIdSet.add(evtObj.WhatId);
                    }
                    else{
                        if(evtObj.WhatId == null && leadIdMap.get(evtObj.WhoId)!=null && leadIdMap.get(evtObj.WhoId).Account__c == null){
                            evtObj.Primary_Account__c = Null;
                        }
                    }
                }
            }
        }
        if(whatIdSet.size() > 0){
            for(Id IdObj: whatIdSet){
                Id what_id = IdObj;
                if(what_id != null){
                    IdObjectType = String.valueOf(what_id.getsobjecttype());
                    if(IdObjectType == 'Account'){
                        accountIdSet.add(what_id);                              //Storing IDs of Account
                    }
                    if(IdObjectType == 'Opportunity'){
                        oppIdSet.add(what_id);                                  //Storing IDs of Opportunity 
                    }
                    if(IdObjectType == 'Quote'){
                        quoteIdSet.add(what_id);                                //Storing IDs of Quote 
                    }
                    if(IdObjectType == 'Customer_Engagement__c'){
                        custEngIdSet.add(what_id);                              //Storing IDs of Customer Engagements
                    }
                    if(IdObjectType == 'Case'){
                        CasesIdSet.add(what_id);                                //Storing IDs of Case 
                    }
                    if(IdObjectType == 'Customer_Initiatives__c'){
                        cusInitiativeIdSet.add(what_id);                        //Storing IDs of cusInitiativeIdSet 
                    }
                    if(IdObjectType == 'Service_Engagement__c'){
                        servEngIdSet.add(what_id);                              //Storing IDs of Service_Engagement__c 
                    }
                    if(IdObjectType == 'End_Customer_Contracts__c'){
                        EndCusIdSet.add(what_id);                               //Storing IDs of customer Initiative 
                    }
                    if(IdObjectType == 'ServiceContract'){
                        servConsIdSet.add(what_id);                             //Storing IDs of ServiceContract 
                    }
                }
            }
        }
        Map<id,Account> accountIdMap = new Map<id,Account>();
        if(accountIdSet.size() > 0){
            accountIdMap = new Map<id,Account>([select id, Name from Account where Id IN:accountIdSet]);
        }
        Map<id,Opportunity> oppIdMap = new Map<id,Opportunity>();
        if(oppIdSet.size() > 0){
            oppIdMap = new Map<id,Opportunity>([select id, AccountId from Opportunity where Id IN:oppIdSet]);
        }
        Map<id,Quote> quoteIdMap = new Map<id,Quote>();
        if(quoteIdSet.size() > 0){
            quoteIdMap = new Map<id,Quote>([select id, AccountId from Quote where Id IN:quoteIdSet]);
        }
        Map<id,Customer_Engagement__c> custEngIdMap = new Map<id,Customer_Engagement__c>();
        if(custEngIdSet.size() > 0){
            custEngIdMap = new Map<id,Customer_Engagement__c>([select id, Account_Name__c from Customer_Engagement__c where Id IN:custEngIdSet]);
        }
        Map<id,Case> caseIdMap = new Map<id,Case>();
        if(CasesIdSet.size() > 0){
            caseIdMap = new Map<id,Case>([select id, account.Id from Case where Id IN:CasesIdSet]);
        }
        Map<id,Customer_Initiatives__c> cusInitiativeIdMap = new Map<id,Customer_Initiatives__c>();
        if(cusInitiativeIdSet.size() > 0){
            cusInitiativeIdMap = new Map<id,Customer_Initiatives__c>([select id, plan_number__r.Account_Name__c from Customer_Initiatives__c where Id IN:cusInitiativeIdSet]);
        }
        Map<id,Service_Engagement__c> servEngIdMap = new Map<id,Service_Engagement__c>();
        if(servEngIdSet.size() > 0){
            servEngIdMap = new Map<id,Service_Engagement__c>([select id, name, Account__c from Service_Engagement__c where Id IN:servEngIdSet]);
        }
        Map<id,End_Customer_Contracts__c > EndCusIdMap = new Map<id,End_Customer_Contracts__c>();
        if(EndCusIdSet.size() > 0){
            EndCusIdMap = new Map<id,End_Customer_Contracts__c>([select id, Account__c from End_Customer_Contracts__c where Id IN:EndCusIdSet]);
        }
        Map<id,ServiceContract> servConsIdMap = new Map<id,ServiceContract>();
        if(servConsIdSet.size() > 0){
            servConsIdMap = new Map<id,ServiceContract>([select id, AccountId from ServiceContract where Id IN:servConsIdSet]);
        }
        for(Event evtObj: EventList){
            if(accountIdMap.get(evtObj.WhatId)!=null && accountIdMap.get(evtObj.WhatId).id != null){        //Account
                evtObj.Primary_Account__c = accountIdMap.get(evtObj.WhatId).id;
            }
            if(oppIdMap.get(evtObj.WhatId)!=null && oppIdMap.get(evtObj.WhatId).id != null){                //Opportunity
                evtObj.Primary_Account__c = oppIdMap.get(evtObj.WhatId).AccountId;
            }
            if(quoteIdMap.get(evtObj.WhatId)!=null && quoteIdMap.get(evtObj.WhatId).id != null){            //Quote
                evtObj.Primary_Account__c = quoteIdMap.get(evtObj.WhatId).AccountId;
            }
            if(custEngIdMap.get(evtObj.WhatId)!=null && custEngIdMap.get(evtObj.WhatId).id != null){        //Customer Engagements
                evtObj.Primary_Account__c = custEngIdMap.get(evtObj.WhatId).Account_Name__c;
            }
            if(cusInitiativeIdMap.get(evtObj.WhatId)!=null && cusInitiativeIdMap.get(evtObj.WhatId).id != null){    //Customer_Initiatives__c
                evtObj.Primary_Account__c = cusInitiativeIdMap.get(evtObj.WhatId).plan_number__r.Account_Name__c;
            }
            if(caseIdMap.get(evtObj.WhatId)!=null && caseIdMap.get(evtObj.WhatId).id != null){              //Case
                evtObj.Primary_Account__c = caseIdMap.get(evtObj.WhatId).account.Id;
            }
            if(servEngIdMap.get(evtObj.WhatId)!=null && servEngIdMap.get(evtObj.WhatId).id != null){        //Service_Engagement__c
                evtObj.Primary_Account__c = servEngIdMap.get(evtObj.WhatId).Account__c;
            }
            if(EndCusIdMap.get(evtObj.WhatId)!=null && EndCusIdMap.get(evtObj.WhatId).id != null){          //EndCusIdMap
                evtObj.Primary_Account__c = EndCusIdMap.get(evtObj.WhatId).Account__c;
            }
            if(servConsIdMap.get(evtObj.WhatId)!=null && servConsIdMap.get(evtObj.WhatId).id != null){      //ServiceContracts
                evtObj.Primary_Account__c = servConsIdMap.get(evtObj.WhatId).AccountId;
            }
            updatedEventMap.put(evtObj.Id, evtObj);
        }
        if(updatedEventMap.size()>0){
            Database.update(updatedEventMap.values(), false);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //if(Test.isRunningTest()){
            //ABSM_activityEventReportBatch obj = new ABSM_activityEventReportBatch();
            //String cronID = System.scheduleBatch(obj, 'Event Report Batch', 60, 50);
        //}
    }
}