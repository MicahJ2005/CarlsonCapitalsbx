@isTest
private class testCommunityContactUsController {

    static testMethod void testCommunityContactUs() {
        account a = new account(name='Test Household');
        insert a; 
        
        ApexPages.currentPage().getParameters().put('hid', a.id);
        
        CommunityContactUsController ccc = new CommunityContactUsController();
        
        ccc.thisBP.notes__c = 'Here are some notes';
        ccc.SaveRecord();
        
        System.assertNotEquals(ccc.thisTask.id, null);
        System.assert(ccc.submitted);
    }
}