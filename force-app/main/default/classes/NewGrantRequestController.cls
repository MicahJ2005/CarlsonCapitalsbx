public with sharing class NewGrantRequestController{
    public FSTR__Business_Process__c thisBP {get;set;}
    private FSTR__Business_Process__c grant {get;set;}
    public Charitable_Organization__c charOrg {get;set;}
    public Charitable_Organization__c charitableOrg {get;set;}    
    public List<SelectOption> acpAccounts {get;set;}      
    public Boolean submitted {get;private set;}
    public Boolean charOrgLookupFilled {get;private set;}    
    private User U; 
    private id householdid;    
    private id recordTypeId; 
    private Id householdAccountId; 

    private Map<String,String> oldCharOrgInfoByField = new Map<String,String>();
    
    public NewGrantRequestController(){
        thisBP = new FSTR__Business_Process__c();
        charOrg = new Charitable_Organization__c();        
        acpAccounts = new List<SelectOption>();        
        submitted = false;
        charOrgLookupFilled = false;
        id cloneid = null;        
        
        if(ApexPages.currentPage().getParameters().containskey('hid'))
            householdid = ApexPages.currentPage().getParameters().get('hid');
        
        if(ApexPages.currentPage().getParameters().containskey('cloneid'))
                cloneid = ApexPages.currentPage().getParameters().get('cloneid');                
        
        if(cloneid != null) {
            grant = [Select Charitable_Organization__c,Proposed_Grant_Amount__c,Special_Project_Name__c,Acknowledgement_Option__c,From_Account__c 
                         From FSTR__Business_Process__c where id = :cloneid];
            System.debug(grant);
            charOrg = [Select Name, Address_Line_1__c, Address_Line_2__c, City__c, State__c, Zip_Code__c, Tax_ID__c 
                         From Charitable_Organization__c where id = :grant.Charitable_Organization__c];
            System.debug(charOrg);
            charOrgLookupFilled = true;
            thisBP.Charitable_Organization__c = grant.Charitable_Organization__c;
            thisBP.Special_Project_Name__c = grant.Special_Project_Name__c;
            thisBP.Proposed_Grant_Amount__c = grant.Proposed_Grant_Amount__c;
            thisBP.Acknowledgement_Option__c = grant.Acknowledgement_Option__c;
            thisBP.From_Account__c = grant.From_Account__c;            
        }
            
        u = [select name, contactid, contact.accountid, Portal_Upload_Allowed__c from user where id = :Userinfo.getuserid()];
        if(u.contact.accountid != null)
             householdid  =  u.contact.accountid;

        if (u.contactid != null) {
            List<AccountContactRelation> relations = [SELECT Id, AccountId, Account.Name, Account.FirstName, ContactId, Contact.FirstName, Roles FROM AccountContactRelation WHERE FinServ__PrimaryGroup__c = true AND ContactId = :u.ContactId];
            if (relations != null && !relations.isEmpty()) {
                householdAccountId = relations[0].AccountId;
            }
        }
        
        if(householdid != null){
            for(FinServ__FinancialAccount__c fa : [select id, name, FinServ__FinancialAccountNumber__c	 from FinServ__FinancialAccount__c where FinServ__FinancialAccountType__c IN ('ACP Charitable Gift Fund', 'ACP') and FinServ__PrimaryOwner__c=:householdid ]){
                acpAccounts.add(new Selectoption(fa.id, fa.name)); 
            }
        }        
        
        for(recordtype r : [select id from recordtype where developername = 'Grant_Request' and sobjecttype = 'FSTR__Business_Process__c' limit 1]){
            recordTypeId = r.id;            
        }
        
    } 
    
    public PageReference CharOrgLookupPopulated(){
        
        if(thisBP.Charitable_Organization__c != null){
            charOrgLookupFilled = true;
            charOrg = [SELECT Id,Name,Address_Line_1__c,Address_Line_2__c,City__c,State__c,Zip_Code__c,Tax_ID__c FROM Charitable_Organization__c Where Id=:thisBP.Charitable_Organization__c LIMIT 1];
            // gather 'old' charitable org info in case it is updated
            oldCharOrgInfoByField = populateOldCharOrgInfoByField(charOrg);
        } else {
            charOrgLookupFilled = false;
            charOrg = new Charitable_Organization__c();
            oldCharOrgInfoByField = new Map<String,String>();
        }
        return null;
    } 

    public PageReference saveAndNew(){
        return validateAndSubmit(true);
    }   
    
    public PageReference SaveRecord(){
        return validateAndSubmit(false);
    }
    
    public PageReference Cancel(){
        pageReference page = new pageReference('/apex/grantrequests');
        page.setRedirect(true);
        return page;
    }

    private PageReference validateAndSubmit(Boolean saveAndNew) {
        PageReference pr;
        Boolean saveSuccess = false;
        // if records pass validations submit/upsert
       ApexPages.Message msg = validateRecords();

       if (msg!=null) {
            ApexPages.addMessage(msg);
            saveSuccess = false;
       } else {
            try {
                submitRecords();
                saveSuccess = true;
            } catch (Exception ex){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,ex.getMessage()));
            }  
       }

       // if this is a 'save and new' redirect to a new page
       if (saveSuccess && saveAndNew) {
            pr = Page.newgrantrequest;
            pr.setRedirect(true);
       } 

       // otherwise stay on the same page
       return pr;              
    }

    // submits records for save
    private void submitRecords() {
        thisBP.recordtypeid = recordTypeId;
        thisBP.fstr__client__c = u.contactid;
        if (householdAccountId != null) {
            thisBP.fstr__business_account__c = householdAccountId;
        }
        else {
            thisBP.fstr__business_account__c = householdid;
        }
        thisBP.fstr__due_date__c = System.today();                            
        thisBP.Delay_Creation__c = true;
        thisBP.New_Char_Org_Info_Flag__c = false;
        thisBP.Request_Method__c = 'ACP Portal';
        thisBP.fstr__status__c = 'Open';
        // if information from an existing grant request has been changed add to the notes
        String oldInfoNotes = checkForFieldChangesAndAddToNotes(charOrg);
        if (oldInfoNotes!=null && oldInfoNotes.length()>0) {
            thisBP.Additional_Notes__c = oldInfoNotes;
            thisBP.New_Char_Org_Info_Flag__c = true;
        }

        upsert charOrg;
        thisBP.Charitable_Organization__c = charOrg.Id;    

        thisBP.fstr__subject__c = 'New Grant Request from '+ u.name + ' to ' + charOrg.Name;
        // subject can only be 80 characters
        thisBP.fstr__subject__c = thisBP.fstr__subject__c.left(80);
        insert thisBP;     

        // set submitted flag for conditional page rendering 
        submitted = true; 
    }

    // validates records to ensure all required information is populated and returns a page message
    private ApexPages.Message validateRecords() {
        ApexPages.Message msg;

        
           //check that the New Charitable Organization fields are filled in
           if(charOrg.Name == null || charOrg.Address_Line_1__c == null || charOrg.City__c == null || charOrg.State__c == null || charOrg.Zip_Code__c == null){
                msg = new Apexpages.Message(ApexPages.Severity.Error,'Charitable Organization Name, Address Line 1, City, State, & Zip Code are all required.');     
           }
        
        
        if(thisBP.Proposed_Grant_Amount__c == null){
            msg = new Apexpages.Message(ApexPages.Severity.Error,'Proposed Grant Amount is required.');     
        }
        
        if(thisBP.Acknowledgement_Option__c == null){
            msg = new Apexpages.Message(ApexPages.Severity.Error,'Please specify an acknowledgement option.');     
        }
        
        if(thisBP.Grant_Certification__c == FALSE){
            msg = new Apexpages.Message(ApexPages.Severity.Error,'Please certify that you agree.');     
        }

        return msg;
    }

    // populates a map of 'old' charitable org values by field name for later use
    private Map<String,String> populateOldCharOrgInfoByField(Charitable_Organization__c co) {
        Map<String,String> retMap = new Map<String,String>{
            'Name' => co.Name,
            'Address_Line_1__c' => co.Address_Line_1__c,
            'Address_Line_2__c' => co.Address_Line_2__c,
            'City__c' => co.City__c,
            'State__c' => co.State__c,
            'Zip_Code__c' => co.Zip_Code__c,
            'Tax_ID__c' => co.Tax_ID__c 
        };

        return retMap;    
    }    

    // populates a map of 'old' charitable org values by field name
    private String checkForFieldChangesAndAddToNotes(Charitable_Organization__c co) {
        String retStr = '';
        if (oldCharOrgInfoByField!=null && !oldCharOrgInfoByField.isEmpty()) {
            if (oldCharOrgInfoByField.get('Name')!=co.Name) {
                retStr += 'Old Name: ' + oldCharOrgInfoByField.get('Name') + '<br/>';
            }
            if (oldCharOrgInfoByField.get('Address_Line_1__c')!=co.Address_Line_1__c) {
                retStr += 'Old Address Line 1: ' + oldCharOrgInfoByField.get('Address_Line_1__c') + '<br/>';
            }
            if (oldCharOrgInfoByField.get('Address_Line_2__c')!=co.Address_Line_2__c) {
                retStr += 'Old Address Line 2: ' + oldCharOrgInfoByField.get('Address_Line_2__c') + '<br/>';
            }
            if (oldCharOrgInfoByField.get('City__c')!=co.City__c) {
                retStr += 'Old City: ' + oldCharOrgInfoByField.get('City__c') + '<br/>';
            }
            if (oldCharOrgInfoByField.get('Zip_Code__c')!=co.Zip_Code__c) {
                retStr += 'Old Zip Code: ' + oldCharOrgInfoByField.get('Zip_Code__c') + '<br/>';
            }
            if (oldCharOrgInfoByField.get('Tax_ID__c')!=co.Tax_ID__c) {
                retStr += 'Old Tax ID: ' + oldCharOrgInfoByField.get('Tax_ID__c');
            }       
        } 

        if (retStr!='') {
            retStr = 'The user changed the following Charitable Organization information:<br/>' + retStr;
        }

        return retStr;    
    }        

}