//01.13.2025	Sophia Murphy (Demand Chain)
//				Updated to use an org-wide email address as the scheduler
@isTest
public class ReminderEmailBatchTest {
    
    @testSetup
    static void setupTestData() {
        
        Integer howManyTestRecords = 10;
        Id confirmationEmailRecordType = Schema.SObjectType.Email_Quick_Text__c.getRecordTypeInfosByName().get('Confirmation Email').getRecordTypeId();

        insert new Email_Quick_Text__c(
                Name = 'Confirmation_Email',
                Email_Body__c = 'This is a test email template',
            	Location__c = 'Bloomington',
                Subject__c = 'Test Email Template',
                RecordTypeId = confirmationEmailRecordType
            );
        
        Id reminderEmailRecordType = Schema.SObjectType.Email_Quick_Text__c.getRecordTypeInfosByName().get('Reminder Email').getRecordTypeId();
        // Create test Email_Quick_Text__c records
        insert new Email_Quick_Text__c(
                Name = 'Reminder_Email',
                Email_Body__c = 'This is a test email template',
            	Location__c = 'Bloomington',
                Subject__c = 'Test Email Template',
                RecordTypeId = reminderEmailRecordType
            );
        
        // Create test Account records
        List<Account> households = new List<Account>();
        for (Integer i = 0; i < howManyTestRecords; i++) {
            households.add(new Account(
                Email_Addresses__c = 'test' + i + '@example.com',
                Primary_Advisor__c = Userinfo.getUserId(),
                Name = 'Test Account'
            ));
        }
        insert households;
        
        Set<String> orgWideAddresses = new Set<String>();
        for(OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress]) {
            orgWideAddresses.add(owea.Address);
        }
        
        User scheduler = [SELECT Id FROM User WHERE Email IN :orgWideAddresses AND isActive = true LIMIT 1];

        // Create test Meeting_Confirmation__c records
        Id householdMeetingRecordType = Schema.SObjectType.Meeting_Confirmation__c.getRecordTypeInfosByName().get('Household Meeting Confirmation').getRecordTypeId();
        List<Meeting_Confirmation__c> meetings = new List<Meeting_Confirmation__c>();
        for (Integer i = 0; i < howManyTestRecords; i++) {
            meetings.add(new Meeting_Confirmation__c(
                Household__c = households[i].Id,
                Start__c = Date.today().addDays(i),
                //Scheduler__c = Userinfo.getUserId(),
                Scheduler__c = scheduler.Id,
                Reminder_Email_Sent__c = false,
                RecordTypeId = householdMeetingRecordType,
                Office_Location__c = 'Bloomington',
                Confirmation_Email_Addresses__c = households[i].Email_Addresses__c
            ));
        }
        insert meetings;
    }

    @isTest
    static void testReminderEmailBatch() {
        // Start the test
        Test.startTest();

        // Instantiate the batch class
        ReminderEmailBatch batchClass = new ReminderEmailBatch();

        // Execute the batch job
        Database.executeBatch(batchClass, 200);

        // End the test
        Test.stopTest();
    }
}