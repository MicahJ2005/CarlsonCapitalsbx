@isTest
public with sharing class NewGrantRequestController2Test {
    @isTest
    public static void NewGrantRequestController2Test() {
        Account ac = new Account(Name = 'Test Account');   
        insert ac; 
        PageReference testPage = Page.grantrequests; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(ac.Id));
        
        ApexPages.StandardController sc = new  ApexPages.StandardController(ac);     
        NewGrantRequestController2 ext = new NewGrantRequestController2(sc);         
            
        System.debug(ext.redirectToNewPortalPage()); 
        List<Account> al = [Select Name from Account where Name LIKE '%Test%' LIMIT 1];
        System.assertEquals(1, al.size());
    
    }
}