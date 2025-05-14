/**
* @author Orchestrate LLC
* @date 2016
*
* @group Utilities
*
* @description Provides methods commonly used across Apex classes.
*/
public class Utility {
  //This variable will be reset upon each new trigger activiation.
  //I don't think I need to have the two functions for this to work, but that is how the official Salesforce documentation did it, so I figured I'd do it that way too. 
  private static boolean tradeUpdated = false;
  
  public static boolean hasTradeUpdated() {
    return tradeUpdated;
  }
  
  public static void setTradeToUpdated() {
    tradeUpdated = true;
  } 

  // assembles Type string according to CCM specs
  public static String assembleIdString(Set<Id> idSet) {
    String retStr = '';

    for (Id s : idSet) {
      if (retStr!='') {
        retStr+=',';
      }
      retStr+='\''+s+'\'';      
    }

    return retStr;
  }  

  public static void sendBatchNotificationEmail(String jobType,String jobId,String msgString) {
        AsyncApexJob a = [SELECT id, ApexClassId, 
                       JobItemsProcessed, TotalJobItems, 
                       NumberOfErrors, CreatedBy.Email 
                       FROM AsyncApexJob 
                       WHERE id = :jobId];
        
        String emailMessage = 'Your batch job '
             + jobType
             + 'has finished.  It executed ' 
             + a.totalJobItems 
             + ' batches.  Of which, ' + a.jobitemsprocessed 
             + ' processed without any exceptions thrown and ' 
             + a.numberOfErrors +
             ' batches threw unhandled exceptions.';

        emailMessage+='<br/>'+msgString;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.createdBy.email};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('noreply@salesforce.com');
        mail.setSenderDisplayName('Batch Job Summary');
        mail.setSubject(jobType+'Batch job completed');
        mail.setPlainTextBody(emailMessage);
        mail.setHtmlBody(emailMessage);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
  }

  // for Client Inventory and Discovery form notifications
    @future
    public static void createQueueTask(String recordType,String recordId,String accountId,String contactId,String clientName) {
      String apexPage = '/apex/'+recordType.deleteWhitespace();
   //   if (recordType=='Client Inventory') {
      //apexPage += 'ClientInventory';
   //   } else if (recordType=='Client Discovery') {
      //apexPage += 'ClientDiscovery';
   //   } else if (recordType=='Client Budget') {
      //apexPage += 'ClientBudget';
   //   }      
      // 'in queue' user same in both production and sandbox - 005i0000000h0uG
      Task t = new Task(OwnerId='005i0000000h0uG',
                WhatId=accountId,
                WhoId=contactId,
                Queue__c='Admin',
                ActivityDate=System.today(),
                Status='Not Started',
                Type=recordType+' Completed',
                Subject='[PORTAL] Client '+clientName+' has completed the '+recordType+' form',
                Description='Location: '+URL.getSalesforceBaseUrl().toExternalForm()+apexPage+'?id='+recordId);
      insert t;
    }      

    //@future
    public static void sendClientInformationNotification(Set<Id> idSet,Map<String,Boolean> triggerMap,String objType) {
    Boolean isCompletedForm = false;
    Boolean afterInsert = false;
    Boolean matchingTemplate = true;
      objType = objType.toLowerCase();
    //clientDiscovery = [Select Id From Discover_Questionnaire__c Where CreatedById=:currentUser.Id and IsCoClient__c=:isCoClient Limit 1];
    List<EmailTemplate> templates = [Select DeveloperName from EmailTemplate where DeveloperName in ('Client_Inventory_Files_Uploaded','Client_Inventory_Started','Client_Inventory_Completed','Client_Questionnaire_Started','Client_Questionnaire_Completed','Co_Client_Questionnaire_Started','Co_Client_Questionnaire_Completed','Client_Budget_Started')];
    Map<String,EmailTemplate> templateByName = new Map<String,EmailTemplate>();
    for (EmailTemplate e : templates) {
      templateByName.put(e.DeveloperName,e);
    }
    List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
    List<Task> emailTasks = new List<Task>();
    EmailTemplate template;
    // determine which template we need to use
    if (triggerMap.containsKey('isAttachment') && triggerMap.get('isAttachment') && objType=='client_inventory__c') {
      template = templateByName.get('Client_Inventory_Files_Uploaded');
    } else if (triggerMap.containsKey('isComplete') && triggerMap.get('isComplete')) {
      isCompletedForm = true;
      if (objType=='client_inventory__c') {
        template = templateByName.get('Client_Inventory_Completed');
      } else if (objType=='discover_questionnaire__c') {
        template = templateByName.get('Client_Questionnaire_Completed');
      }
    } else if (triggerMap.containsKey('isAfter') && triggerMap.containsKey('isInsert') && triggerMap.get('isAfter') && triggerMap.get('isInsert')) {
      afterInsert = true;
      if (objType=='client_inventory__c') {
        template = templateByName.get('Client_Inventory_Started');
      } else if (objType=='discover_questionnaire__c') {
        template = templateByName.get('Client_Questionnaire_Started');
      } else if (objType=='client_budget__c') {
        template = templateByName.get('Client_Budget_Started');
      }
    } else {
      // no matching template
      matchingTemplate = false;
    }
    if (matchingTemplate && !idSet.isEmpty()) {
      List<sObject> objs = Database.query('Select Household__c,Household__r.OwnerId,Household__r.Owner.Email,Household__r.FinServ__PrimaryContact__c'+(objType=='discover_questionnaire__c' ? ',IsCoClient__c' : '')+' From '+objType+' Where Household__c!=null and Id in ('+assembleIdString(idSet)+')');
      for (sObject c : objs) {
        try {
          Id primaryContactId = (Id)c.getSObject('Household__r').get('FinServ__PrimaryContact__c');
          // set co-client template if we have it
          if (objType=='discover_questionnaire__c' && (Boolean)c.get('IsCoClient__c')) {
            if (isCompletedForm) {
              template = templateByName.get('Co_Client_Questionnaire_Completed');
            } else if (afterInsert) {
              template = templateByName.get('Co_Client_Questionnaire_Started');
            }
          }
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          // test
          //mail.setToAddresses(new List<String>{'pcedev@orchestratellc.com'}); 
          // production
          mail.setToAddresses(new List<String>{'ginger@carlsoncap.com',(String)c.getSObject('Household__r').getSObject('Owner').get('Email')}); 
          mail.setTargetObjectId(primaryContactId);
          mail.setWhatId((Id)c.get('Id'));
          mail.setTemplateID(template.Id); 
          mail.setSaveAsActivity(true);
          mail.setTreatTargetObjectAsRecipient(false);
          System.debug(mail);
          // add email message to list
          emailMsgs.add(mail);          
        
        } catch (Exception e) {
          System.debug('Error while trying to send notification email: '+e.getMessage()+' '+e.getStackTraceString());
        }
      }    
      Messaging.sendEmail(emailMsgs);  
    }    
    }

    //'Client_Inventory_Completed','Client_Inventory_Files_Uploaded','Co_Client_Questionnaire_Completed',

    //List<sObject> sObject objs = new List<sObject>();
    //List<Client_Inventory__c> objs = [Select Household__r.OwnerId,Household__r.Owner.Email,Household__r.Primary_Contact__c From Client_Inventory__c Where Household__c!=null and Id in :inventoryIds];
    //for (Client_Inventory__c c : objs) {
    //  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //  // test
    //  //mail.setToAddresses(new List<String>{'pcedev@orchestratellc.com'}); 
    //  // production
    //  mail.setToAddresses(new List<String>{'ginger@carlsoncap.com',c.Household__r.Owner.Email}); 
    //  mail.setTargetObjectId(c.Household__r.Primary_Contact__c);
    //  mail.setWhatId(c.Id);
    //  mail.setTemplateID(template.Id); 
    //  mail.setSaveAsActivity(false);
    //  mail.setTreatTargetObjectAsRecipient(false);
    //  System.debug(mail);
    //  emailMsgs.add(mail);
    //}


  //  @future
  //  public static void sendNotificationEmail(String submissionType,String recordId,String firstname,String lastName,String advisorEmails) {
  //    List<String> notificationEmails = advisorEmails.split(';');
  //    String apexPage = 'ClientDiscovery';
  //    if (submissionType=='Client Inventory') {
    //  apexPage = 'ClientInventory';
  //    }      
    //System.debug('Sending Notification Email: submissionType '+submissionType);
    //System.debug('Sending Notification Email: recordId '+recordId);
    //System.debug('Sending Notification Email: firstname '+firstname);
    //System.debug('Sending Notification Email: lastName '+lastName);
    //System.debug('Sending Notification Email: advisorEmail '+advisorEmails);

    //if (!notificationEmails.isEmpty()) {
    //  Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    //  message.toAddresses = notificationEmails;//currentUser.Contact.Account.Primary_Advisor__r.Email - 'sayer@orchestratellc.com'
    //  message.subject = submissionType+' Completed';
    //  message.plainTextBody = '[PORTAL] Client '+firstName+' '+lastName+' has completed the '+submissionType+' form. View it here: '+URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+apexPage+'?id='+recordId;
    //  Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { message };
               
    //  Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    //  System.debug(results);
    //}    
  //  }  
}