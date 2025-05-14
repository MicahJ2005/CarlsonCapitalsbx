@isTest
public class NetDocumentsServiceTest {
    
    @testSetup static void setupTest(){
		Account household = new Account(name='Test Household ABC', FinServ__Status__c = 'Client', Type = 'Integrated Wealth Management', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId());
		insert household;	
        
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');
        settings.RefreshToken__c = 'abc123';
        settings.AccessToken__c = 'abc123';
        settings.TokenExpiration__c = Datetime.now().addMinutes(-100);
        settings.RefreshTokenExpiration__c = Datetime.now().addMinutes(-50);
        upsert settings;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'TITLE';
        cv.VersionData = Blob.valueOf('TEST');
        cv.PathOnClient = 'meeting summary.pdf';
        insert cv;

    }
    
    static testMethod void returnAccessTokenTest() {
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');

        Test.startTest();
        String value = NetDocumentsService.returnAccessToken(settings);
        Test.stopTest();

        System.assert(value != null);
    }

    static testMethod void returnRefreshTokenTest() {
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');

        Test.startTest();
        String value = NetDocumentsService.returnRefreshToken(settings);
        Test.stopTest();

        System.assert(value != null);
    }

    static testMethod void hasUpdatedAccessTokenTest() {
        HttpCalloutMockService mock = new HttpCalloutMockService();
		mock.isSuccessResponse = True;
        Test.setMock(HttpCalloutMock.class, mock);
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');

        Test.startTest();
        Boolean value = NetDocumentsService.hasUpdatedAccessToken(true, settings);
        Test.stopTest();

        System.assert(value == true);
    }

    static testMethod void assembleMultiPartRequestTest() {
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');
        Account hh = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];

        Test.startTest();
        HttpRequest value = NetDocumentsService.assembleMultiPartRequest(Blob.valueOf('TEST'), 'meeting summary', 'pdf', 'Document_Group__c', hh.Id, 'Test Household ABC', true, settings);
        Test.stopTest();

        System.assert(value != null);
    }

    static testMethod void upsertSettingsFutureTest() {

        Test.startTest();
        NetDocumentsService.upsertSettingsFuture('0056g0000047DGUAA2','TEST','TEST', '100', '100'); 
        Test.stopTest();

        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');
        System.assertEquals('TEST', settings.RefreshToken__c);
    }

    static testMethod void sendAuthenticationSummaryEmailTest() {
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        NetDocumentsService.sendAuthenticationSummaryEmail('BODY',u); 
        Test.stopTest();
    }

    /*    static testMethod void netDocumentsBatchTest() {
        HttpCalloutMockService mock = new HttpCalloutMockService();
		mock.isSuccessResponse = True;
        Test.setMock(HttpCalloutMock.class, mock);
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
        Account hh = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];

        Test.startTest();
        ContentDocument cd = [SELECT Id FROM ContentDocument];
        NetDocumentsBatch ndb = new NetDocumentsBatch(cd.Id,u.Id,hh.Id,'');
        Database.executeBatch(ndb,1);
        Test.stopTest();
    } */

}