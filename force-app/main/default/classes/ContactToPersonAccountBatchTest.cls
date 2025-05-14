@isTest
private class ContactToPersonAccountBatchTest {
    @isTest
    static void testBatchJob() {
        // Create test data for Contact records
        List<Contact> testContacts = new List<Contact>();
        for(Integer i=0; i<200; i++){
            Contact contact = new Contact(
                FirstName = 'Test First Name' + i,
                LastName = 'Test Last Name' + i,
                Email = 'testemail' + i + '@test.com',
                AccountId = null,
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Household_Member').getRecordTypeId()
            );
            testContacts.add(contact);
        }
        
        for(Integer i=200; i<400; i++){
            Contact contact = new Contact(
                FirstName = 'Test First Name' + i,
                LastName = 'Test Last Name' + i,
                Email = 'testemail' + i + '@test.com',
                AccountId = null,
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Precise_FP_Contact').getRecordTypeId()
            );
            testContacts.add(contact);
        }
        
        insert testContacts;
        
        // Create test data for Account records
        RecordType householdRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Household' LIMIT 1];
        List<Account> testAccounts = new List<Account>();
        for(Integer i=0; i<10; i++){
            Account account = new Account(
                Name = 'Test Household' + i,
                RecordTypeId = householdRT.Id
            );
            testAccounts.add(account);
        }
        insert testAccounts;
        
        for(Integer i=0; i<10; i++){
            Contact contact = testContacts[i];
            Account account = testAccounts[i];
            contact.AccountId = account.Id;
        }
        update testContacts;
        
        Test.startTest();
        ContactToPersonAccountBatch batchJob = new ContactToPersonAccountBatch();
        batchJob.query = 'SELECT Id, Name, Role__c, firstName, LastName, Email, Birthdate, AccountId, SSN__c, Phone, Child_Full_Name__c, Child_Phone__c, Child_SSN__c, Child_Birthdate__c, Child_First_Name__c, Child_Last_Name__c, Child_Middle_Name__c, Child_Email__c, Child_Age__c, Other_Family_Full_Name__c,Other_Family_Member_Full_Name__c, Other_Family_Phone__c, Other_Family_Email__c,Other_Family_First_Name__c,Other_Family_Last_Name__c,Other_Family_Middle_Name__c, OtherPhone, Other_Family_SSN__c, Other_Family_Birthdate__c, Other_Family_Age__c FROM Contact WHERE (RecordTypeId = \''+Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Household_Member').getRecordTypeId()+'\' OR RecordTypeId = \''+Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Precise_FP_Contact').getRecordTypeId()+'\') AND IsPersonAccount = false AND AccountId != Null AND Account.RecordType.Name = \'Household\'';
        Database.executeBatch(batchJob);
        Test.stopTest();
    }
    @isTest
    public static void ContactToAccount_Schedule_Test() {
        Test.startTest();
        ContactToPersonAccountBatch schdBatch = new ContactToPersonAccountBatch();
        String sch = '0 0 12 * * ? *';
        String jobID = system.schedule('Batch test', sch, schdBatch); 
        Test.stopTest();
    }
}