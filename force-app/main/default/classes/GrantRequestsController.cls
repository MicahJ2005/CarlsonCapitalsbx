public with sharing class GrantRequestsController {         
    public List<FSTR__Business_Process__c> acpGrants {get; set;}
    public List<FinServ__FinancialAccount__c> acpFAs {get;set;}
    public Integer faCount {get;private set;}
    public Integer grantCount {get;set;}
    public boolean showAll {get;set;}
    private User U;
    private id householdid;

    // for individual grant request page
    public final fstr__business_process__c indReq {get;private set;}
    public List<String> charOrgFieldPaths {get;private set;}
    public List<Attachment> attachments {get;private set;}
    private Map<String, Schema.SObjectType> globalDescribe;

    public GrantRequestsController(){
        faCount = 0;
        grantCount = 0;
        showAll = FALSE;
        
        //just in case we want to test outside of portal
        if(ApexPages.currentPage().getParameters().containskey('hid'))
            householdid = ApexPages.currentPage().getParameters().get('hid');
                
        u = [select contactid, contact.accountid, Portal_Upload_Allowed__c from user where id = :Userinfo.getuserid()];
        if(u.contact.accountid != null) {
             //householdid  =  u.contact.accountid;
            List<AccountContactRelation> relations = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE FinServ__PrimaryGroup__c = True AND ContactId = :u.contactId];
            if (!relations.isEmpty()) {
                householdid = relations[0].AccountId;
            }
        }
         
        if(householdid != null){
            acpFAs = [Select id, name, Portal_Display_Name__c, FinServ__FinancialAccountNumber__c, FinServ__Balance__c
                      From   FinServ__FinancialAccount__c where   FinServ__FinancialAccountType__c IN ('ACP', 'ACP Charitable Gift Fund') and FinServ__Household__c=:householdid ];
        }        
        
        grantCount = [Select COUNT() From FSTR__Business_Process__c 
                         Where  FSTR__Business_Process__c.FSTR__Business_Account__c=:householdId and FSTR__Business_Process__c.RecordType.Name IN ('Grant Request')];
        
        acpGrants = [Select FSTR__Due_Date__c,CreatedDate,Charitable_Organization__c,Charitable_Organization__r.Name,Proposed_Grant_Amount__c,Special_Project_Name__c,Acknowledgement_Option__c,From_Account__c,FSTR__Status__c 
                         From FSTR__Business_Process__c 
                         Where  FSTR__Business_Process__c.FSTR__Business_Account__c=:householdId 
                         and FSTR__Business_Process__c.RecordType.Name IN ('Grant Request')
                         Order By FSTR__Due_Date__c DESC LIMIT 10];
    }
    
    public PageReference showAll(){
        acpGrants = [Select FSTR__Due_Date__c,CreatedDate,Charitable_Organization__c,Charitable_Organization__r.Name,Proposed_Grant_Amount__c,Special_Project_Name__c,Acknowledgement_Option__c,From_Account__c,FSTR__Status__c 
                         From FSTR__Business_Process__c 
                         Where  FSTR__Business_Process__c.FSTR__Business_Account__c=:householdId 
                         and FSTR__Business_Process__c.RecordType.Name IN ('Grant Request')
                         Order By FSTR__Due_Date__c DESC LIMIT 1000];
        showAll=TRUE;
        return null;
    }

    /*******************************************************************************************************
    * @description Constructor for individual grant request page
    * @param sc StandardController (page extension controller)
    * @return none
    */    
    public GrantRequestsController(ApexPages.StandardController sc) {
        charOrgFieldPaths = new List<String>(); 
        charOrgFieldPaths.addAll(assembleFieldSet('fstr__business_process__c','grantrequest').keySet());
        indReq = Database.query('Select '+assembleQueryString(charOrgFieldPaths)+' From fstr__business_process__c Where Id=\''+sc.getId()+'\' Limit 1');
        try {
            attachments = [Select Name,CreatedDate From Attachment Where ParentId = :sc.getId() and (Name Like '%Charity%' or Name Like '%Acknowledgement%')];
        } catch (Exception e) { }
        // TODO provide sharing access for business processes with this record type to portal users
        // TODO additional operations on the individual grant requests
    }

    /*******************************************************************************************************
    * @description Assembles a map of field name and label
    * @param objectType 
    * @param recordType 
    * @return Map of field labels by field name
    */    
    private Map<String,String> assembleFieldSet(String objectType,String recordType) {
        if (globalDescribe==null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        Map<String,String> fieldLabelsByPath = new Map<String,String>();
        List<String> fieldPathList = new List<String>();

        Schema.SObjectType sObjType = globalDescribe.get(objectType);
        Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
        // return a list of available field sets on this object
        Map<String,Schema.FieldSet> fsMap = describeResult.FieldSets.getMap();
        //System.debug(fsMap);
        for (Schema.FieldSetMember fsm : fsMap.get(recordType).getFields()) {
            fieldLabelsByPath.put(fsm.getFieldPath(),fsm.getLabel());                               
        }         

        return fieldLabelsByPath;       
    }

    /*******************************************************************************************************
    * @description Assembles list of fields into a single string for use in queries
    * @param flattenString list of field names
    * @return List of fields assembled into a single string
    */    
    private String assembleQueryString(List<String> flattenString) {
        String retStr = '';
        for (String s : flattenString) {
            if (retStr!='') {
                retStr+=',';
            }
            retStr+=s;
        }

        return retStr;
    }    
        
}