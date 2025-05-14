public with sharing class ClientBudgetCtrl {

    public List<Client_Budget_Item__c> lineItems {get;set;}
    public Boolean isReadOnly {get;private set;}
    //public Boolean isCoClient {get;private set;}
    //public Integer lastSavedMinutesAgo {get;set;}

    private ApexPages.StandardController sc;
    private Id budgetId;
    public Client_Budget__c budget {get;set;}
    public Client_Budget__c aggregateFields {get;set;}    
    private String retURL;
    private User currentUser;

    public ClientBudgetCtrl(ApexPages.StandardController sc) {
        this.retURL = ApexPages.currentPage().getParameters().get('retURL');
        this.sc = sc;        
        isReadOnly = false;
        if (UserInfo.getUserType()=='Standard' && !Test.isRunningTest()) {
            isReadOnly = true;
        }
        currentUser = [Select Name,FirstName,LastName,Email,ContactId,Contact.AccountId,Contact.Account.Name,Portal_Notification_Emails__c From User Where Id=:UserInfo.getUserId() Limit 1];

        // set budget params
        //sc.reset();        
        budget = (Client_Budget__c)sc.getRecord();
        budgetId = sc.getId();
        queryAggregateFields();
        // initial data load
        queryLineItems();                    
    }

    public PageReference onPageLoad() {
        // query for existing or create new on page load
        if (sc.getId()==null && !isReadOnly) {
            Client_Budget__c budget;
            // insert a new client inventory if one does not existing for this user (can be two - client and co-client)
            if ([Select count() From Client_Budget__c Where CreatedById=:currentUser.Id]==0) {
                budget = new Client_Budget__c(CreatedById=currentUser.Id,Name=currentUser.Contact.Account.Name,Date__c=System.today(),Household__c=currentUser.Contact.AccountId);
                insert budget;
                budgetId = budget.Id;
                // create line items if they do not yet exist (new Budget)
                createLineItems(budgetId);
            } else {
                // query for client or co-client version of the questionnairre
                budget = [Select Id From Client_Budget__c Where CreatedById=:currentUser.Id Limit 1];
                queryLineItems();                    
            }
            budgetId = budget.Id;
            PageReference pr = Page.ClientBudget;
            pr.getParameters().put('id',budget.Id);
            //pr.getParameters().put('coclient',String.valueOf(isCoClient));
            return pr.setRedirect(true);
            // redirect page to this page
        } else if (UserInfo.getUserType()!='CspLitePortal') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'This page is editable only by client portal users.'));
        }
        return null;
    }   
    
    // MASTER SAVE METHOD 
    public PageReference quickSaveItems() {
        saveBudget();
        queryAggregateFields();
        return null;
    }   

    //public PageReference saveAndExit() {
    //    saveBudget();
    //    return new PageReference(retURL!=null?retURL:'/');
    //}       


    //public PageReference completeApplication() {
    //    //insert createQueueTask('Client Discovery Questionnaire');
    //    //Utility.createQueueTask('Client Discovery',discoveryId,currentUser.Contact.AccountId,currentUser.ContactId,currentUser.FirstName+' '+currentUser.LastName);
    //    Utility.sendNotificationEmail('Client Budget',budgetId,currentUser.FirstName,currentUser.LastName,currentUser.Portal_Notification_Emails__c);
    //    return saveAndExit();       
    //}   
    
    // PRIVATE METHODS

    private void queryAggregateFields() {
        try {
            aggregateFields = [Select Total_Retirement_Annual__c,Total_Retirement_Monthly__c,Total_Current_Annual__c,Total_Current_Monthly__c From Client_Budget__c Where Id=:sc.getId()];    
        } catch (Exception e) {
            aggregateFields = new Client_Budget__c();
            System.debug(e.getMessage()+e.getStackTraceString());
        }        
    }    


    private void saveBudget() {
        // set savepoint for all operations
        if (!isReadOnly) {
            SavePoint sp = Database.setSavePoint();
            try {
                budget.Household__c = currentUser.Contact.AccountId;
                upsert budget;
                attemptSave(lineItems);
            } catch (Exception e) {
                Database.rollback(sp);
            }   
        }   
    }

    private void attemptSave(List<Client_Budget_Item__c> lineItems) {
        try {
            upsert lineItems;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                        'Problem saving your new Item(s). '+e.getMessage()));
        }       
    }   

    private void queryLineItems() {
        lineItems = new List<Client_Budget_Item__c>();
        try {
            lineItems = [Select Name,Editable_Name__c,Retirement_Monthly_Expense__c,Retirement_Annual_Expense__c,Current_Monthly_Expense__c,Current_Annual_Expense__c
                            From Client_Budget_Item__c 
                            Where Client_Budget__c = :sc.getId() Order By Order__c ASC];
        } catch (Exception e) {
            System.debug(e.getMessage()+e.getStackTraceString());
        }           
    }   

    // creates a new line item as required for a new Budget
    private void createLineItems(Id budgetId) {
        List<String> itemTypes = getItemTypes();
        lineItems = new List<Client_Budget_Item__c>();
        Integer ct = 0;
        // add specific expense types from list
        for (String s : itemTypes) {
            lineItems.add(new Client_Budget_Item__c(Name=s,Client_Budget__c=budgetId,Order__c=ct));
            ct++;
        }
        
        // add 'Other Expense' line items
        Integer totalOtherExpenseItems = 4;
        for (Integer i=0;i<totalOtherExpenseItems;i++) {
            lineItems.add(new Client_Budget_Item__c(Name='Other Expense',Client_Budget__c=budgetId,Editable_Name__c=true,Order__c=ct));
            ct++;
        }

        insert lineItems;
    }
    
    // list of specific budget items
    private static List<String> getItemTypes() {
        return new List<String>{
            'Mortgage or Rent Payments',
            'Utilities',
            'Food',
            'Clothing',
            'Car/Travel Expenses',
            'Insurance Payments: Home',
            'Insurance Payments: Auto',
            'Insurance Payments: Health',
            'Insurance Payments: Disability',
            'Child Care Costs',
            'Medical/Dental/Drug Expenses',
            'Recreation & Entertainment',
            'Charitable Contributions',
            'Debt Payments',
            'Alimony, Child Support, Separate Maintenance',
            'Gifts',
            'Savings',
            'Property Taxes',
            'House Upkeep/Repairs/Maintenance',
            'Education Expenses'
        };        
    }

}