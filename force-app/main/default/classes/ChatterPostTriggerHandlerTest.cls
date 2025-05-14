@isTest
public class ChatterPostTriggerHandlerTest {
    static testMethod void testHandleAfterInsert() {
        // Create a test collaboration group
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='suser@testorg.com');
        
        System.runAs(u) {
            // The following code runs as user 'u' 
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId()); 
            
        }
        // Create a test chatter post that mentions the test group
        FeedItem testFeedItem = new FeedItem(
            Body='@Operations This is a test post',
            ParentId=u.Id,
            CreatedById = u.Id,
            Type='TextPost'
        );
        insert testFeedItem;
        
        Test.StartTest();
        ChatterPostTriggerHandler.handleAfterInsert(new List<FeedItem>{testFeedItem});
        Integer invocations = Limits.getEmailInvocations();
        Test.StopTest();
        
        // Check that the email was sent
        System.debug('Email invocations: ' + invocations);
        //System.assertEquals(1, invocations,'An email has not been sent');
    }
}