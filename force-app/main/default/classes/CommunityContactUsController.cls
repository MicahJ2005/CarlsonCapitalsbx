public class CommunityContactUsController{

    public FSTR__Business_Process__c thisBP {get;set;}
    public Task thisTask {get;set;}
    public Boolean submitted {get;private set;}    
    private User U;    
    private id householdid;    
    private id recordTypeId;    
    
    public CommunityContactUsController(){
        thisBP = new FSTR__Business_Process__c();
        submitted = false;
        
        if(ApexPages.currentPage().getParameters().containskey('hid'))
            householdid = ApexPages.currentPage().getParameters().get('hid');
            
        u = [select contactId, contact.accountid, Portal_Upload_Allowed__c from user where id = :Userinfo.getuserid()];
        if(u.contactId != null) {
            //householdid  =  u.contact.accountid; 
            List<AccountContactRelation> relations = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE FinServ__PrimaryGroup__c = True AND ContactId = :u.contactId];
            if (!relations.isEmpty()) {
                householdid = relations[0].AccountId;
            }
        }
        
        for(recordtype r : [select id from recordtype where developername = 'Portal_Contact_Us' and sobjecttype = 'FSTR__Business_Process__c' limit 1]){
            recordTypeId = r.id;
        }       
                
    }
    
    /*
    public PageReference SaveRecord(){
        try{
            thisBP.recordtypeid = recordTypeId;
            thisBP.fstr__client__c = u.contactid;
            thisBP.fstr__business_account__c = householdid;
            thisBP.fstr__due_date__c = System.today();
            thisBP.fstr__subject__c = 'Contact Us Request from Community';            
            thisBP.Delay_Creation__c = true;
            thisBP.fstr__status__c = 'Open';
            PortalCustomSetting__c bpAssignee = PortalCustomSetting__c.getOrgDefaults();
            if(bpAssignee != null && bpAssignee.Business_Process_Assignee__c != null){
                thisBP.OwnerId = bpAssignee.Business_Process_Assignee__c; 
            }
            insert thisBP;
        }catch (Exception ex){
            ApexPages.addMessages(ex);
            return null;            
        }  
        submitted = true;    
        return null;
    } */

    public PageReference SaveRecord(){
        try {
            thisTask = new Task(
                WhoId = u.contactid,
                Subject = 'Contact Us Request from Community',
                Status = 'Open',
                ActivityDate = System.today(),
                WhatId = householdid,
                Description = thisBP.Notes__c
            );
            PortalCustomSetting__c bpAssignee = PortalCustomSetting__c.getOrgDefaults();
            if(bpAssignee != null && bpAssignee.Business_Process_Assignee__c != null){
                thisTask.OwnerId = bpAssignee.Business_Process_Assignee__c; 
            }
            insert thisTask;
        }catch (Exception ex){
            ApexPages.addMessages(ex);
            return null;            
        }  
        submitted = true;    
        return null;
    }   
}