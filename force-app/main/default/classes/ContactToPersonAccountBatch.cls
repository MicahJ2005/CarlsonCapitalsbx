/*
 * This Batch class changes the Contacts to Person Accounts that comes from integration on Daily Basis. 
 * @author Sammy Zawahiri -- (Demand Chain)
 * @date 2023-02-16
*/
global class ContactToPersonAccountBatch implements Database.Batchable<sObject>, Schedulable {
    public String query;
    
    // Query to retrieve all contacts of the specified record type
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(query != null){
            return Database.getQueryLocator(query);
        }
        Id householdMemberId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Household_Member').getRecordTypeId();
        Id preciseFPRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Precise_FP_Contact').getRecordTypeId();
        return Database.getQueryLocator([
            SELECT Id, Name, firstName, LastName, Email, Birthdate, AccountId, SSN__c, Role__c, Phone, Child_Full_Name__c, Child_Phone__c,
            Child_SSN__c, Child_Birthdate__c, Child_First_Name__c, Child_Last_Name__c, Child_Middle_Name__c, Child_Email__c, Child_Age__c,
            Other_Family_Full_Name__c,Other_Family_Member_Full_Name__c, Other_Family_Phone__c, Other_Family_Email__c,Other_Family_First_Name__c,Other_Family_Last_Name__c,Other_Family_Middle_Name__c, OtherPhone, Other_Family_SSN__c, Other_Family_Birthdate__c, Other_Family_Age__c
            FROM Contact
            WHERE (RecordTypeId =:householdMemberId OR RecordTypeId =:preciseFPRecordTypeId) AND IsPersonAccount = false AND AccountId != Null AND Account.RecordType.Name = 'Household'
        ]);
    }
    
    // Method that processes each batch of records
    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        List<Id> contactIdsToDelete = new List<Id>();
        List<Account> personAccounts = new List<Account>();
        
        //Create new Map That will hold a unique Key 
        map<string, Id> contactNameToAccoutIdmap = new map<string, Id>();
        map<string, String> contactNameToRoleIdmap = new map<string, String>();
        // Loop through the contacts and create PersonAccount records
        for (Contact contact : scope) {
            //System.debug('Contact ID'+contact.Id);
            //System.debug('Account ID'+contact.AccountId);
            contactNameToAccoutIdmap.put(contact.Firstname+'#'+contact.LastName+'#'+contact.email, contact.AccountId);
            contactNameToRoleIdmap.put(contact.Firstname+'#'+contact.LastName+'#'+contact.email, contact.Role__c);
            Account personAccount = new Account();
            personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            personAccount.FirstName = contact.FirstName;
            personAccount.LastName = contact.LastName;
            personAccount.PersonEmail = contact.Email;
            personAccount.PersonBirthdate = contact.Birthdate;
            personAccount.SSN__pc  = contact.SSN__c;
            personAccount.PersonHomePhone = contact.Phone;
            personAccount.Child_Full_Name__pc = contact.Child_Full_Name__c;
            personAccount.Child_First_Name__pc = contact.Child_First_Name__c;
            personAccount.Child_Middle_Name__pc = contact.Child_Middle_Name__c; 
            personAccount.Child_Last_Name__pc = contact.Child_Last_Name__c;
            personAccount.Child_Phone__pc = contact.Child_Phone__c;
            personAccount.Child_SSN__pc = contact.Child_SSN__c;
            personAccount.Child_Birthdate__pc = contact.Child_Birthdate__c;
            personAccount.Child_Email__pc = contact.Child_Email__c;
            personAccount.Child_Age__pc = contact.Child_Age__c;
            //personAccount.Other_Family_Full_Name__pc = contact.Other_Family_Full_Name__c;
            personAccount.Other_Family_First_Name__pc = contact.Other_Family_First_Name__c;
            personAccount.Other_Family_Middle_Name__pc = contact.Other_Family_Middle_Name__c;
            personAccount.Other_Family_Last_Name__pc = contact.Other_Family_Last_Name__c;
            personAccount.Other_Family_Member_Full_Name__pc = contact.Other_Family_Member_Full_Name__c;
            personAccount.Other_Family_Full_Name__pc = contact.Other_Family_Full_Name__c;
            personAccount.Other_Family_Email__pc = contact.Other_Family_Email__c;
            personAccount.Other_Family_Phone__pc = contact.Other_Family_Phone__c;
            personAccount.Other_Family_SSN__pc = contact.Other_Family_SSN__c;
            personAccount.Other_Family_Birthdate__pc = contact.Other_Family_Birthdate__c;
            personAccount.Other_Family_Age__pc = contact.Other_Family_Age__c;
            
            personAccounts.add(personAccount);
            
            contactIdsToDelete.add(contact.Id); 
        }
        
        // Insert the new Person Account records
        
        Database.SaveResult[] srList = Database.insert(personAccounts, false);
        System.debug('SRLIST'+srList);
        
        set<Id> newpersonAccountIdSet = new set<Id>();
        //loop on results
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess() == true) {
                newpersonAccountIdSet.add(sr.getId());
            }
        }
        System.debug('New Accounts'+newpersonAccountIdSet);
        
        List<Account> newPersonAccountList = [SELECT Id, FirstName, LastName, PersonEmail, PersonContactId FROM Account WHERE Id IN:newpersonAccountIdSet];
        List<AccountContactRelation> contactToAccount = new List<AccountContactRelation>();
        
        for (Account personAccount : newPersonAccountList) {
            AccountContactRelation newrelationship = new AccountContactRelation();
            newrelationship.ContactId = personAccount.PersonContactId;
            newrelationship.AccountId = contactNameToAccoutIdmap.get(personAccount.FirstName+'#'+personAccount.LastName+'#'+personAccount.PersonEmail);
            newrelationship.Roles = contactNameToRoleIdmap.get(personAccount.FirstName+'#'+personAccount.LastName+'#'+personAccount.PersonEmail); 
            contactToAccount.add(newrelationship);
        }
        
        //Insert the Relationship between Contact and account in the database
        System.debug('before insert account to contact');
        insert contactToAccount;
        
        //Delete the original Contact records
        Database.delete(contactIdsToDelete, false);
        
        System.debug('Contact deleted');
    }
    
    // Method that runs after all batches have completed
    global void finish(Database.BatchableContext bc) {
    }
    global void execute(SchedulableContext SC) {
        
        
        ContactToPersonAccountBatch cToPaBatch = new ContactToPersonAccountBatch();
        ID batchprocessid = Database.executeBatch(cToPaBatch);
    } 
}