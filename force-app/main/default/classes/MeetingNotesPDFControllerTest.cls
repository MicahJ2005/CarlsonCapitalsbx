/**
 * @description : Test Class for MeetingNotesPDFController
 *
 * @author Matthew J Lennington -- (Demand Chain)
 * @date 2024-09-27
 *
*/
@isTest
public with sharing class MeetingNotesPDFControllerTest {
    
    @isTest
    static void testGetMeetings() {
        User usrToUse = new User(Id = UserInfo.getUserId());

        System.runAs(usrToUse) {
            // Create test data
            Account household = new Account(Name = 'Test Household');
            insert household;

            Client_Meeting_Note__c meetingNote1 = new Client_Meeting_Note__c(
                Meeting_Theme__c = 'Investment',
                Meeting_Date_Time__c = DateTime.now(),
                Household__c = household.Id
            );
            insert meetingNote1;
            
            Client_Meeting_Task__c meetingTask1 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote1.Id,
                Question__c = 'Test Question 1',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 1'
            );
            insert meetingTask1;

            Client_Meeting_Note__c meetingNote2 = new Client_Meeting_Note__c(
                Meeting_Theme__c = 'Net Worth',
                Meeting_Date_Time__c = DateTime.now(),
                Household__c = household.Id
            );
            insert meetingNote2;
            
            Client_Meeting_Task__c meetingTask2 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote2.Id,
                Question__c = 'Test Question 2',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 2'
            );
            insert meetingTask2;
            
            Client_Meeting_Task__c meetingTask3 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote2.Id,
                Question__c = 'Test Question 3',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 3'
            );
            insert meetingTask3;

            Test.startTest();
            // Call the getMeetings method
            List<Client_Meeting_Note__c> result = MeetingNotesPDFController.getMeetings(
                household.Id, null
            );
            Test.stopTest();

            // Assertions
            System.assertEquals(2, result.size(), 'Expected 2 meetings');
        }
    }

    @isTest
    static void testgetHouseHoldName(){
        User usrToUse = new User(Id = UserInfo.getUserId());

        System.runAs(usrToUse) {
            // Create test data
            Account household = new Account(Name = 'Test Household');
            insert household;

            Test.startTest();
            Account result = MeetingNotesPDFController.getHouseHold(
                household.Id
            );
            Test.stopTest();

             // Assertions
             System.assertEquals(household.Name, result.Name, 'Wrong Account Name');
        }
    }

    @isTest
    static void initTest() {
        User usrToUse = new User(Id = UserInfo.getUserId());

        System.runAs(usrToUse) {
            // Create test data
            Account household = new Account(Name = 'Test Household');
            insert household;

            Client_Meeting_Note__c meetingNote1 = new Client_Meeting_Note__c(
                Meeting_Theme__c = 'Investment',
                Meeting_Date_Time__c = DateTime.now(),
                Household__c = household.Id
            );
            insert meetingNote1;
            
            Client_Meeting_Task__c meetingTask1 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote1.Id,
                Question__c = 'Test Question 1',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 1'
            );
            insert meetingTask1;

            Client_Meeting_Note__c meetingNote2 = new Client_Meeting_Note__c(
                Meeting_Theme__c = 'Net Worth',
                Meeting_Date_Time__c = DateTime.now(),
                Household__c = household.Id
            );
            insert meetingNote2;
            
            Client_Meeting_Task__c meetingTask2 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote2.Id,
                Question__c = 'Test Question 2',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 2'
            );
            insert meetingTask2;
            
            Client_Meeting_Task__c meetingTask3 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote2.Id,
                Question__c = 'Test Question 3',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 3'
            );
            insert meetingTask3;

            Test.startTest();

            PageReference pageRef = Page.MeetingNotesPDF;
            pageRef.getParameters().put('Id', String.valueOf(household.Id));
            Test.setCurrentPage(pageRef);
            MeetingNotesPDFController ctrl = new MeetingNotesPDFController();
            Test.stopTest();


            // Assertions
            System.assertEquals(2, ctrl.notes.size(), 'Expected 2 meetings');
        }
    }


    @isTest
    static void controllerTest() {
        User usrToUse = new User(Id = UserInfo.getUserId());

        System.runAs(usrToUse) {
            // Create test data
            Account household = new Account(Name = 'Test Household');
            insert household;

            Client_Meeting_Note__c meetingNote1 = new Client_Meeting_Note__c(
                Meeting_Theme__c = 'Investment',
                Meeting_Date_Time__c = DateTime.now(),
                Household__c = household.Id
            );
            insert meetingNote1;
            
            Client_Meeting_Task__c meetingTask1 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote1.Id,
                Question__c = 'Test Question 1',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 1'
            );
            insert meetingTask1;

            Client_Meeting_Note__c meetingNote2 = new Client_Meeting_Note__c(
                Meeting_Theme__c = 'Net Worth',
                Meeting_Date_Time__c = DateTime.now(),
                Household__c = household.Id
            );
            insert meetingNote2;
            
            Client_Meeting_Task__c meetingTask2 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote2.Id,
                Question__c = 'Test Question 2',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 2'
            );
            insert meetingTask2;
            
            Client_Meeting_Task__c meetingTask3 = new Client_Meeting_Task__c(
                Client_Meeting_Note__c = meetingNote2.Id,
                Question__c = 'Test Question 3',
                Status__c = 'In Progress',
                Notes__c = 'Test Notes 3'
            );
            insert meetingTask3;

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(household);
            MeetingNotesPDFController ctrl = new MeetingNotesPDFController(sc);
            Test.stopTest();


            // Assertions
            System.assertEquals(2, ctrl.notes.size(), 'Expected 2 meetings');
        }
    }


    @isTest
    static void apexErrorsTest() {
        User usrToUse = new User(Id = UserInfo.getUserId());

        System.runAs(usrToUse) {
            Test.startTest();
            MeetingNotesPDFController ctrl = new MeetingNotesPDFController();
            Test.stopTest();

            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            System.assertNotEquals(0, pageMessages.size());

        }
    }


}