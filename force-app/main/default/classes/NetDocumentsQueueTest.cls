@isTest
public class NetDocumentsQueueTest {
    
    @testSetup static void setupTest(){
        List<Account> accList = new List<Account>();
        Account a = new Account(Name = 'Test1', AccountNumber = 'test123');
        Account a2 = new Account(Name = 'Test2', AccountNumber = 'test123');
        accList.add(a);
        accList.add(a2);
        insert accList;
        
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');
        settings.RefreshToken__c = 'abc123';
        settings.TokenExpiration__c = Datetime.now().addMinutes(-100);
        settings.RefreshTokenExpiration__c = Datetime.now().addMinutes(-50);
        upsert settings;
    }
    
    @isTest static void NetDocumentsQueueExecuteMethodFail() {
        HttpCalloutMockService mock = new HttpCalloutMockService();
		mock.isSuccessResponse = True;
        Test.setMock(HttpCalloutMock.class, mock);
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE AccountNumber = 'test123']);
        Test.startTest();
        System.enqueueJob(new NetDocumentsQueue(new List<Id>(accountMap.keySet())));
        Test.stopTest();
    }
    
    @isTest static void NetDocumentsQueueExecuteMethodRefresh() {
        HttpCalloutMockService mock = new HttpCalloutMockService();
		mock.isSuccessResponse = True;
        Test.setMock(HttpCalloutMock.class, mock);
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');
        settings.RefreshTokenExpiration__c = Datetime.now().addMinutes(50);
        upsert settings;
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE AccountNumber = 'test123']);
        Test.startTest();
        System.enqueueJob(new NetDocumentsQueue(new List<Id>(accountMap.keySet())));
        Test.stopTest();
    }
    
    @isTest static void NetDocumentsQueueSuccess() {
        HttpCalloutMockService mock = new HttpCalloutMockService();
		mock.isSuccessResponse = True;
        Test.setMock(HttpCalloutMock.class, mock);
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance('0056g0000047DGUAA2');
        settings.TokenExpiration__c = Datetime.now().addMinutes(10);
        upsert settings;
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE AccountNumber = 'test123']);
        Test.startTest();
        NetDocumentsQueue.makeCallouts(new List<Id>(accountMap.keySet()));
        Test.stopTest();
    }
    
    @isTest static void NetDocumentsQueueFailure() {
        HttpCalloutMockService mock = new HttpCalloutMockService();
		mock.isSuccessResponse = False;
        Test.setMock(HttpCalloutMock.class, mock);
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE AccountNumber = 'test123']);
        Test.startTest();
        NetDocumentsQueue.makeCallouts(new List<Id>(accountMap.keySet()));
        Test.stopTest();
    }
}