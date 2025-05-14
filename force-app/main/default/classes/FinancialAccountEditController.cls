public with sharing class FinancialAccountEditController {

    public List<FinServ__FinancialAccount__c> finAccts {get;private set;}
    public List<FinServ__AssetsAndLiabilities__c> assets {get;private set;}
    public String householdName {get;private set;}
    public String baseUrl {get;set;}
    public Id householdId {get;private set;}
    public String noEditPCFields {get;set;}
    //public Id pcId {get;private set;}

    public FinancialAccountEditController(ApexPages.StandardController stdController) {

        baseUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/';
        // a list of fields that are not editable with Financial Accounts of the PC Account record type
        //noEditPCFields = 'Household_Business__c,Taxable__c,Account_Closed__c,Total_Assets__c,Cost_Basis__c,As_of_Date__c,Account_Type__c,Account_Number__c,Description__c';
        noEditPCFields = 'FinServ__Household__c,FinServ__TaxStatus__c,OASP_FSC__Active__c,FinServ__Balance__c,Cost_Basis__c,FinServ__FinancialAccountType__c,FinServ__FinancialAccountNumber__c,FinServ__Description__c';
        try {
            householdId = stdController.getRecord().Id; //ApexPages.currentPage().getParameters().get('id');
            System.debug(householdId);
            finAccts = queryFinancialAccounts(householdId); 
            assets = queryAssets(householdId);
            Account a = [Select Name From Account Where Id=:householdId Limit 1];
            householdName = a.Name;
        } catch (QueryException e) {
            // if an Id is not specified or there are no results
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,'Please specify a valid Household/Business Id or one with associated Financial Accounts.'));   
        } catch (Exception e) {
            // send something nice to the screen 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,'We\'re not sure what happened (Hint: '+e.getMessage()+', '+e.getStackTraceString()+')'));   
        }     
    }    

    // retrieves all the fields from the specified field set
    public List<Schema.FieldSetMember> getFields() {
        return sObjectType.FinServ__FinancialAccount__c.FieldSets.Custom_Editing.getFields();
    }

    public List<Schema.FieldSetMember> getAssetFields() {
        return sObjectType.FinServ__AssetsAndLiabilities__c.FieldSets.Custom_Editing.getFields();
    }

    // query all fields in field set related to this Household/Business
    private List<FinServ__FinancialAccount__c> queryFinancialAccounts(Id householdId) {
        String query = 'Select ';
        for(Schema.FieldSetMember f : this.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id,FinServ__Household__r.Name,FinServ__JointOwner__r.Name,FinServ__PrimaryOwner__r.Name From FinServ__FinancialAccount__c Where FinServ__Household__c = \''+householdId+'\' AND FinServ__Status__c != \'Closed\'';
        return Database.query(query);
    }  

    private List<FinServ__AssetsAndLiabilities__c> queryAssets(Id householdId) {
        String query = 'Select ';
        for(Schema.FieldSetMember f : this.getAssetFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id,FinServ__Household__r.Name,FinServ__JointOwner__r.Name,FinServ__PrimaryOwner__r.Name From FinServ__AssetsAndLiabilities__c Where FinServ__Household__c = \''+householdId+'\' AND Closed__c = false';
        return Database.query(query);
    }  

    public PageReference save() {
        try{
        	update finAccts;
            finAccts = queryFinancialAccounts(householdId);
            update assets;
            assets = queryAssets(householdId);
        }catch (DmlException e){
            //ApexPages.addMessages(e);
            System.debug(e + '; ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0)));
        }
        return null;
    }

    public PageReference cancel() {
        finAccts = queryFinancialAccounts(householdId);
        assets = queryAssets(householdId);
        return null;
    }

}