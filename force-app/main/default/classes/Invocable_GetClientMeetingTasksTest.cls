/**
 * @description       : Unit Test for Invocable_GetClientMeetingTasks
 * @author            : Sophia Murphy (Demand Chain)
 * Modifications Log 
 * 08.16.2024	Sophia Murphy (Demand Chain)
 * 				Initial Creation
**/
@isTest
public with sharing class Invocable_GetClientMeetingTasksTest {
    
    @isTest
    public static void dmlTest() {
        //Create a Household Account
        Account hAcct = new Account(Name = 'Test');
        insert hAcct;
        
        //Create a client meeting note
        Client_Meeting_Note__c note = new Client_Meeting_Note__c(Household__c = hAcct.Id);
        insert note;

        //Get a valid section from custom metadata
        Client_Meeting_Template__mdt template = ([SELECT Section__c 
                                                         FROM Client_Meeting_Template__mdt 
                                                         LIMIT 1]);

        //Pass the section name and meeting id into the invocable
        List<Invocable_GetClientMeetingTasks.InputValue> inputList = new List<Invocable_GetClientMeetingTasks.InputValue>();
        Invocable_GetClientMeetingTasks.InputValue input = new Invocable_GetClientMeetingTasks.InputValue();
        input.meetingId = note.Id;
        input.taskSection = template.Section__c;
        input.householdType = 'test';
        inputList.add(input);
        
        Invocable_GetClientMeetingTasks.getTasks(inputList);
    }
}