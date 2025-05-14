global without sharing class ProcessDelayCreationProcesses implements Database.Batchable<sObject>,Database.Stateful,Schedulable {
    
    global void execute(SchedulableContext SC) {
        CronTrigger ct = [SELECT Id, CreatedBy.email  FROM CronTrigger WHERE Id = :SC.getTriggerId()];
        try{
            
            ProcessDelayCreationProcesses same = new ProcessDelayCreationProcesses ();
            System.scheduleBatch(same, 'ProcessComposer - Uncheck Delay Creation Box', 1);
           
        }catch (AsyncException ae){
            //probably already scheduled        
            
        }
        catch (Exception ae){
            //probably already scheduled        
            
        }
    }

    global List<fstr__business_process__c> start(Database.BatchableContext bc) {
        return [Select id 
                    From fstr__business_process__c
                    where fstr__status__c = 'Open' and delay_creation__c = true and createddate = today];
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        ApplicationReadWriteMode mode = System.getApplicationReadWriteMode();
        //we can process as long as this isn't a maintenance window
        if (mode == ApplicationReadWriteMode.DEFAULT){
            for(sobject s : scope){
                s.put('delay_creation__c', false);
            }       
            update scope;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        try{
            ProcessDelayCreationProcesses same = new ProcessDelayCreationProcesses();
            System.scheduleBatch(same, 'ProcessComposer - Uncheck Delay Creation Box', 1);
        }catch (AsyncException ae){
            //probably already scheduled
        }   
        catch (Exception ex){
        }
    }
}