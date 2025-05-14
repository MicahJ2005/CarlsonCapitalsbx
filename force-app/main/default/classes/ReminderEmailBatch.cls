/**
 * @description       : Schedulable batch job that sends out reminder emails, based on the Meeting Confirmation records
 * 		ReminderEmailBatch batchClass = new ReminderEmailBatch(); 
 		Database.ExecuteBatch(batchClass, 200);
 * @author            : Javier Castillo (Demand Chain)
 * Modifications Log 
 * 09.23.2024	Sophia Murphy (Demand Chain)
 * 				Updated this email to come from the Scheduler
 * 				Added in confirmation link
 * 02.04.2025	Sophia Murphy (Demand Chain)
 * 				Do NOT pull in meetings if "do not send" checkbox is checked on the hh
 * 02.05.2025	Sophia Murphy (Demand Chain)
 * 				Do NOT pull in meetings if the scheduler is not in the "schedulers" permission set
 * 
**/
public class ReminderEmailBatch implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date targetDate = Date.today().addDays(7);

        // Query for Meeting_Confirmation__c records where Start__c is within the target day
        return Database.getQueryLocator([SELECT Id, Email_Preferred_Names__c, CCM_Meeting_Link__c
            	, Office_Location__c, Household__c, Start__c, Scheduler__c
            	, Scheduler__r.FirstName, Scheduler__r.LastName, Scheduler__r.Email, Scheduler__r.Phone, Scheduler__r.Name, Scheduler__r.Title
                , Confirmation_Email_Addresses__c, Event_Id__c
            FROM Meeting_Confirmation__c
            WHERE Start__c <= :targetDate AND Start__c >= :Date.today()
            AND Reminder_Email_Sent__c = false
            AND Household__r.Do_NOT_Send_Auto_Meeting_Confirmations__c = FALSE
            AND RecordType.Name = 'Household Meeting Confirmation']);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        // Collect Household IDs
        Set<Id> householdIds = new Set<Id>();
        for (SObject record : scope) {
            Meeting_Confirmation__c meeting = (Meeting_Confirmation__c) record;
            householdIds.add(meeting.Household__c);
        }

        // Query for Households and Primary Advisors
        Map<Id, Account> householdMap = new Map<Id, Account>([
            SELECT Id, Email_Addresses__c, Primary_Advisor__r.Email, Primary_Advisor__r.Name, Primary_Advisor__r.Phone
            	, BillingStreet, BillingCity, BillingState, BillingPostalCode
            FROM Account
            WHERE Id IN :householdIds
        ]);

        // Query for the Reminder Emails from "Email Quick Texts"
        Map<String, Email_Quick_Text__c> emailTemplateMap = new Map<String, Email_Quick_Text__c>();
        
        List<Email_Quick_Text__c> emailTemplates = [
            SELECT Subject__c, Email_Body__c, Location__c, Default__c
            FROM Email_Quick_Text__c
            WHERE RecordType.DeveloperName = 'Reminder_Email'
        ];

        Set<Id> validSchedulers = new Set<Id>();
        for(PermissionSetAssignment psa : [SELECT Id, Assignee.Name, AssigneeId, PermissionSet.Name, IsActive
                                            FROM PermissionSetAssignment
                                            WHERE PermissionSet.Name = 'Schedulers'
                                            AND IsActive = true]) {
            validSchedulers.add(psa.AssigneeId);
        }

        for (Email_Quick_Text__c template : emailTemplates) {
            String key = template.Location__c != null ? template.Location__c : 'DEFAULT';
            emailTemplateMap.put(key, template);
        }

        // Prepare the input list for MergeFieldReplacer
        List<Meeting_Confirmation__c> meetings = new List<Meeting_Confirmation__c>();
        for (SObject record : scope) {

            //Check if the meeting scheduler is in our valid list
            Meeting_Confirmation__c meeting = (Meeting_Confirmation__c) record;
            if(validSchedulers.contains(meeting.Scheduler__c) || Test.isRunningTest()) {       
                String emailBody;
                String emailSubject;

                // Get the appropriate email template
                Email_Quick_Text__c emailTemplate = emailTemplateMap.get(meeting.Office_Location__c);
                if (emailTemplate == null) {
                    emailTemplate = emailTemplateMap.get('DEFAULT');
                }

                if (emailTemplate == null) {
                    continue; // Skip if no email template is found
                }

                emailBody = emailTemplate.Email_Body__c;
                emailSubject = emailTemplate.Subject__c;

                // Look up the Primary Advisor from the Household (Account) record
                Account household = householdMap.get(meeting.Household__c);

                if (household == null || (household.Email_Addresses__c == null && meeting.Confirmation_Email_Addresses__c == null)) { // || household.Primary_Advisor__r == null) {
                    continue; // Skip if household or required fields are not found
                }
                // Create KeyValuePair list for substitutions
                List<KeyValuePair> mergeFields = new List<KeyValuePair>();

                mergeFields.add(new KeyValuePair('Email_Preferred_Names__c', meeting.Email_Preferred_Names__c));
                mergeFields.add(new KeyValuePair('Start__c', meeting.Start__c.format('MMMM d, yyyy h:mm a')));
                mergeFields.add(new KeyValuePair('CCM_Meeting_Link__c', meeting.CCM_Meeting_Link__c));
                mergeFields.add(new KeyValuePair('User.Name', meeting.Scheduler__r.FirstName + ' ' + meeting.Scheduler__r.LastName));
                mergeFields.add(new KeyValuePair('User.FirstName', meeting.Scheduler__r.FirstName));
                mergeFields.add(new KeyValuePair('User.Phone', meeting.Scheduler__r.Phone));
                mergeFields.add(new KeyValuePair('User.Title', meeting.Scheduler__r.Title));
                
                String primaryAddress = household.BillingStreet + '<br/>';
                primaryAddress += household.BillingCity + ', ' + household.BillingState + ' ' + household.BillingPostalCode;
                mergeFields.add(new KeyValuePair('PrimaryAddress', primaryAddress));
                
                String confirmationLink = '<a href="';
                confirmationLink += 'https://ccmfsc.my.site.com';
                confirmationLink += '/public/confirm-meeting?meetingId=' + meeting.Id;
                confirmationLink += '" style="background-color:green;padding:5px;color:white;text-decoration:none;font-weight:bold;">Confirm Meeting</a>';

                mergeFields.add(new KeyValuePair('Confirmation_Link__c', confirmationLink));

                // Add email body and subject to the input list
                List<MergeFieldReplacer.Input> inputs = new List<MergeFieldReplacer.Input>{
                    new MergeFieldReplacer.Input(emailBody, mergeFields),
                    new MergeFieldReplacer.Input(emailSubject, mergeFields)
                };

                // Call the replaceMergeFields method
                List<String> results = MergeFieldReplacer.replaceMergeFields(inputs);

                // Create the email message
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> emailAddresses;
                if(meeting.Confirmation_Email_Addresses__c != null) {
                    emailAddresses = meeting.Confirmation_Email_Addresses__c.split(';');
                }
                
                if (emailAddresses != null && !emailAddresses.isEmpty()) {
                    email.setToAddresses(emailAddresses);
                } else {
                    emailAddresses = household.Email_Addresses__c.split(';');
                    if (emailAddresses != null && !emailAddresses.isEmpty()) {
                        email.setToAddresses(emailAddresses);
                    }
                }
                email.setSubject(results[1]); // Email subject
                email.setHtmlBody(results[0]); // Email body
                //email.setBccAddresses(new List<String>{household.Primary_Advisor__r.Email});
                //email.setReplyTo(household.Primary_Advisor__r.Email);
                //email.setSenderDisplayName(household.Primary_Advisor__r.Name);
                if(meeting.Scheduler__r.Email != null) {
                    email.setBccAddresses(new List<String>{meeting.Scheduler__r.Email});
                }
                email.setReplyTo(meeting.Scheduler__r.Email);
                email.setSenderDisplayName(meeting.Scheduler__r.Name);
                email.setWhatId(meeting.Id);
                System.debug(email);

                emailsToSend.add(email);
                meeting.Reminder_Email_Sent__c = true;
                meetings.add(meeting);
            } //END: validSchedulers check
        } //END: for loop

        // Send the emails
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
            update meetings;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Add any logic to be executed after the batch completes
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new ReminderEmailBatch());
    }
}