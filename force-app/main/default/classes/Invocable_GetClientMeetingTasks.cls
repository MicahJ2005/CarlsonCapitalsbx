/**
 * @description       : Called from "Record-Trigger: Client Meeting Note" flow
 * @author            : Sophia Murphy (Demand Chain)
 * Modifications Log 
 * 08.14.2024	Sophia Murphy (Demand Chain)
 * 				Initial Creation
 * 
 * 01.20.2025	Sophia Murphy (Demand Chain)
 * 				Updated to create based on household type as well
**/
global class Invocable_GetClientMeetingTasks {
    
	@InvocableMethod(label='Get Client Meeting Tasks')
    global static List<ReturnValue> getTasks(List<InputValue> inputValueList) {
        List<Client_Meeting_Task__c> taskList = new List<Client_Meeting_Task__c>();
        
        String mtgId = inputValueList[0].meetingId;
        String secName = inputValueList[0].taskSection;
        String hhType = inputValueList[0].householdType;
        
        //Query for all tasks in the section, related to this meetingId
        taskList = [SELECT Id, Key__c, Notes__c, Question__c, Section__c, Status__c, Date_Completed__c
                   FROM Client_Meeting_Task__c
                   WHERE Client_Meeting_Note__c = :mtgId
                   AND Section__c = :secName];
        
        //If they do not exist - query the custom metadata and create them
        if(taskList.size() == 0) {
            List<Client_Meeting_Task__c> insertList = new List<Client_Meeting_Task__c>();
            for(Client_Meeting_Template__mdt template : [SELECT DeveloperName, MasterLabel, Question__c, Section__c
                                                         	, Display_for_all__c, Display_for_CP__c, Display_for_IWM__c
                                                         FROM Client_Meeting_Template__mdt 
                                                         WHERE Section__c = :secName]) {
                
                Boolean addTask = false;
                if(template.Display_for_all__c == true && hhType != 'Carlson Portfolios' && hhType != 'Integrated Wealth Management') {
                	addTask = true;
                }
                if(template.Display_for_CP__c == true && hhType == 'Carlson Portfolios') {
                	addTask = true;
                }
                if(template.Display_for_IWM__c == true && hhType == 'Integrated Wealth Management') {
                	addTask = true;
                }
                
                if(addTask) {                        
                	Client_Meeting_Task__c task = new Client_Meeting_Task__c();
                	task.Client_Meeting_Note__c = mtgId;
                	task.Key__c = template.DeveloperName;
                	task.Section__c = template.Section__c;
                	task.Question__c = template.Question__c;
                	insertList.add(task);
                }
            }
            if(insertList.size() > 0) {
                insert insertList;
            }
            
            taskList = [SELECT Id, Key__c, Notes__c, Question__c, Section__c, Status__c, Date_Completed__c
                   FROM Client_Meeting_Task__c
                   WHERE Client_Meeting_Note__c = :mtgId
                   AND Section__c = :secName];
            
        } //END: if(taskList.size()
        
        //Then return the list of created tasks
        List<ReturnValue> returnList = new List<ReturnValue>();
        ReturnValue retVal = new ReturnValue();
        retVal.taskList = taskList;
        returnList.add(retVal);
        return returnList;
    }
    
    global class InputValue {
        @InvocableVariable
        global String meetingId;
        
        @InvocableVariable
        global String taskSection;
        
        @InvocableVariable
        global String householdType;
        
    }
    
    global class ReturnValue {
        @InvocableVariable
        global List<Client_Meeting_Task__c> taskList;
    }
}