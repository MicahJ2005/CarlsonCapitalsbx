@isTest
private class TestGrantRequestControllers {
  
    static testMethod void testGrantRequestEditContactController() { 
        FSTR__Business_Process__c newBP = new FSTR__Business_Process__c();
        insert newBP;
        ApexPages.currentPage().getParameters().put('grantid', newBP.id);
        
        GrantRequestEditContactController gre = new GrantRequestEditContactController();
        gre.SaveRecord();
        System.assertEquals(true, gre.submitted);
    
    }
    
    static testMethod void testGrantRequestsController() { 
        Account a = new Account (name='Test Account');
        insert a;
        ApexPages.currentPage().getParameters().put('hid', a.id);
        
        GrantRequestsController gre = new GrantRequestsController();
        gre.ShowAll();
        System.assertEquals(0, gre.faCount);
        
        FSTR__Business_Process__c newBP = new FSTR__Business_Process__c();
        insert newBP;
        ApexPages.StandardController con = new ApexPages.StandardController(newBP);
        GrantRequestsController gre2 = new GrantRequestsController(con);
    
    }
    
    static testMethod void testNewGrantRequestController() { 
        Account a = new Account (name='Test Account');
        insert a;
        ApexPages.currentPage().getParameters().put('hid', a.id);
        
        NewGrantRequestController gre = new NewGrantRequestController();
        gre.CharOrgLookupPopulated();        
      System.assertEquals(null, gre.charOrg.Name);
        gre.cancel();
        gre.SaveRecord(); //should generate errors
        
        gre.CharOrg.Name = 'Test Char Org';
        gre.CharOrg.Address_Line_1__c = 'A Line 1';
        gre.CharOrg.City__c = 'Test City';
        gre.CharOrg.State__c = 'MN';
        gre.CharOrg.Zip_Code__c = '12345';
        gre.thisBP.Proposed_Grant_Amount__c = 1000;
        gre.thisBP.Acknowledgement_Option__c = 'Anonymous donation';
        gre.thisBP.Grant_Certification__c = true;
        
        gre.SaveRecord();
        gre.SaveandNew();
        
        ApexPages.currentPage().getParameters().put('cloneid', gre.thisBP.id);
        
        NewGrantRequestController gre2 = new NewGrantRequestController();
        gre2.CharOrgLookupPopulated();
        
    }
    
}