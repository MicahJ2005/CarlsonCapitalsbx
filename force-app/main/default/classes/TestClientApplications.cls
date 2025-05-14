/**
* @author Orchestrate LLC
* @date 2016
*
* @group Tests
*
* @description Simple test methods to run through all public methods contained in 
* both the Client Inventory and Client Discovery Questionnaire
*/
@isTest
private class TestClientApplications {

    static testMethod void Test_ClientBudget() {
        // Implement test code
        User u = [Select Id From User Where UserType='CspLitePortal' and Profile.Name = 'CCM Prospect Portal' and isactive=true Limit 1];
        System.runAs(u) {
            ApexPages.StandardController sc = new ApexPages.StandardController(new Client_Budget__c());     
            ClientBudgetCtrl cd = new ClientBudgetCtrl(sc); 

            cd.onPageLoad();
            cd.quickSaveItems();
        }
    }
    
    //static testMethod void Test_ClientInventoryItemTrigger() {
        //insert new Client_Inventory_Item__c(Type__c = 'Picklist Value');
    //}
    
    static testMethod void Test_ClientDiscovery() {
        // Implement test code
        User u = [Select Id From User Where UserType='CspLitePortal' and Profile.Name = 'CCM Prospect Portal' and isactive=true Limit 1];
        System.runAs(u) {
            ApexPages.StandardController sc = new ApexPages.StandardController(new Discover_Questionnaire__c());        
            ClientDiscoveryCtrl cd = new ClientDiscoveryCtrl(sc);   

            cd.onPageLoad();
            cd.saveGoalItems();
            cd.addGoalItem();
            cd.quickSaveItems();
            cd.saveAndExit();
            cd.autoSave();
            cd.updateLastSaved();
            cd.page2();
            cd.page3();
            cd.page4();
            cd.page5();
            cd.priorPage();
            cd.nextPage();

            Test.startTest();
                cd.completeApplication();
            Test.stopTest();                        
        }
    }

    static testMethod void Test_ClientInventory() {
        // Implement test code
        User u = [Select Id From User Where UserType='CspLitePortal' and Profile.Name = 'CCM Prospect Portal' and isactive=true Limit 1];
        System.runAs(u) {       
            ApexPages.StandardController sc = new ApexPages.StandardController(new Client_Inventory__c());      
            ClientInventoryCtrl ci = new ClientInventoryCtrl(sc);   
            ci.onPageLoad();
            ci.priorPage();
            ci.nextPage();
            ci.page1();
            ci.page2();
            ci.page3();
            ci.page4();
            ci.page5();
            ci.page6();
            ci.saveAllItems();
            ci.saveAndExit();
            ci.autoSave();
            ci.updateLastSaved();
            ci.quickSaveItems();

            ci.cancelEditInventory();

            ci.upload01();
            ci.upload02();
            ci.upload03();
            ci.upload04();
            ci.upload05();
            ci.upload06();
            ci.upload07();
            ci.upload08();
            ci.upload09();
            ci.upload10();
            ci.upload11();
            ci.upload12();
            ci.upload13();
            ci.upload14();

            ci.saveIncomeItems();
            ci.addIncomeItems();
            ci.saveNetWorthItems();
            ci.addNetWorthItems();
            ci.saveDebtItems();
            ci.addDebtItems();
            ci.saveDependentItems();
            ci.addDependentItems();

            Test.startTest();
                ci.completeApplication();
            Test.stopTest();
        }   
    }   


    static testMethod void Test_ClientInventory_Create() {
        Account a = new Account(Name='Test');
        insert a;
        Contact ctc = new Contact(LastName='Test',AccountId=a.Id);
        insert ctc;

        a = [select FinServ__PrimaryContact__c From Account Where Id = :a.Id];
        a.FinServ__PrimaryContact__c = ctc.Id;
        update a;

        Client_Inventory__c c = new Client_Inventory__c(Household__c=a.Id);
        insert c;

        List<Client_Inventory_Item__c> items = new List<Client_Inventory_Item__c>();
        for (Integer i=0;i<20;i++) {
            items.add(new Client_Inventory_Item__c(Client_Inventory__c=c.Id,Name='Test-'+i));
        }    
        insert items;
    }

    static testMethod void Test_ClientInventory_Attachment() {
        Account a = new Account(Name='Test');
        insert a;
        Contact ctc = new Contact(LastName='Test',AccountId=a.Id);
        insert ctc;

        a = [select FinServ__PrimaryContact__c From Account Where Id = :a.Id];
        a.FinServ__PrimaryContact__c = ctc.Id;
        update a;

        Client_Inventory__c c = new Client_Inventory__c(Household__c=a.Id);
        insert c;

        insert new Attachment(ParentId=c.Id,Name='Test',Body=Blob.valueOf('some text'));
    }    

    static testMethod void Test_ClientDiscovery_Create() {
        Account a = new Account(Name='Test');
        insert a;
        Contact ctc = new Contact(LastName='Test',AccountId=a.Id);
        insert ctc;

        a = [select FinServ__PrimaryContact__c From Account Where Id = :a.Id];
        a.FinServ__PrimaryContact__c = ctc.Id;
        update a;

        Client_Budget__c c = new Client_Budget__c(Household__c=a.Id);
        insert c;

    }    

    static testMethod void Test_ClientBudget_Create() {
        Account a = new Account(Name='Test');
        insert a;
        Contact ctc = new Contact(LastName='Test',AccountId=a.Id);
        insert ctc;

        a = [select FinServ__PrimaryContact__c From Account Where Id = :a.Id];
        a.FinServ__PrimaryContact__c = ctc.Id;
        update a;

        Discover_Questionnaire__c c = new Discover_Questionnaire__c(Household__c=a.Id);
        insert c;
    } 

    static testMethod void Test_ClientInventoryHelper() {
        Client_Inventory__c ci = new Client_Inventory__c();
        insert ci;
        
        List<Attachment> attachments = ClientInventoryHelper.getAttachments(ci.Id);
        System.assert(attachments.isEmpty());
    
        List<ContentDocumentLink> documents = ClientInventoryHelper.getDocuments(ci.Id);
        System.assert(documents.isEmpty());
    }    
    
}