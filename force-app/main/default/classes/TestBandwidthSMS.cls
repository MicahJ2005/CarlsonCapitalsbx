@isTest 
private class TestBandwidthSMS {

    static testMethod void SendSMSCtrlTest() {
        SendSMSCtrl tmp = new SendSMSCtrl();
        System.assert(tmp.contactId == '');
        System.assert(tmp.mobile == '');
        System.assert(tmp.twofactor == '');
        
        Contact c = new Contact(mobilephone = '5555555555', Two_Factor_Phone__c = '6666666666', lastname = 'testcontact');
        insert c;
        PageReference pageRef = new PageReference('/apex/SendSMSPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(c.Id));
        SendSMSCtrl tmp2 = new SendSMSCtrl();
        System.assert(tmp2.contactId == String.valueOf(c.Id));
        System.assert(tmp2.mobile == '5555555555');
        System.assert(tmp2.twofactor == '6666666666');
        
        System.assert(SendSMSCtrl.getProfile() != '');
        
    }
    
    static testMethod void GetNumTest() {
        Test.setMock(HttpCalloutMock.class, new TestBandwidthMockGen());
        System.assert(SendSMSCtrl.getFromNums().containsKey('error') == false);
    }
    
    static testMethod void SendSMSTest() {
        Contact c = new Contact(mobilephone = '5555555555', Two_Factor_Phone__c = '6666666666', lastname = 'testcontact');
        insert c;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestBandwidthMockGen());
        System.assert(SendSMSCtrl.sendSMS('5555555555', '5555555555', 'this is a message', String.valueOf(c.Id)) == 'Created');
        Test.stopTest();
    }
    
    static testMethod void BandwidthSMSPostMobile() {
        Contact c = new Contact(mobilephone = '5555555555', Two_Factor_Phone__c = '6666666666', lastname = 'testcontact');
        insert c;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new TestBandwidthMockGen());
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"time":"2019-12-26T21:05:40.039Z","type":"message-received","to":"+15074030103","description":"Incoming message received","message":{"id":"1577394339927yajxztmkhj7s2p34","owner":"+15074030103","applicationId":"6c4d3651-8740-48fe-80e9-d42f35b84587","time":"2019-12-26T21:05:39.927Z","segmentCount":1,"direction":"in","to":["+15074030103"],"from":"+15555555555","text":"Test"}}');
        RestContext.request = req;
        System.assertEquals('mobile phone found in Salesforce, adding task',BandwidthSMSRestCtrl.doPost());

        Test.stopTest();
    }
    
    static testMethod void BandwidthSMSPostNotFound() {
        Contact c = new Contact(mobilephone = '5555555555', Two_Factor_Phone__c = '6666666666', lastname = 'testcontact');
        insert c;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new TestBandwidthMockGen());
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"time":"2019-12-26T21:05:40.039Z","type":"message-received","to":"+15074030103","description":"Incoming message received","message":{"id":"1577394339927yajxztmkhj7s2p34","owner":"+15074030103","applicationId":"6c4d3651-8740-48fe-80e9-d42f35b84587","time":"2019-12-26T21:05:39.927Z","segmentCount":1,"direction":"in","to":["+15074030103"],"from":"+15555555554","text":"Test"}}');
        RestContext.request = req;
        System.assertEquals('number not found in Salesforce, adding general task',BandwidthSMSRestCtrl.doPost());
        
        Test.stopTest();
    }
    
    static testMethod void BandwidthSMSPostTwoFactor() {
        Contact c = new Contact(mobilephone = '5555555555', Two_Factor_Phone__c = '6666666666', lastname = 'testcontact');
        insert c;
        
        BandwidthSMS__c settings = BandwidthSMS__c.getOrgDefaults();
        settings.Default_Forward_Number__c = '5555555555';
        upsert settings;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new TestBandwidthMockGen());
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"time":"2019-12-26T21:05:40.039Z","type":"message-received","to":"+16666666666","description":"Incoming message received","message":{"id":"1577394339927yajxztmkhj7s2p34","owner":"+15074030103","applicationId":"6c4d3651-8740-48fe-80e9-d42f35b84587","time":"2019-12-26T21:05:39.927Z","segmentCount":1,"direction":"in","to":["+16666666666"],"from":"+15555555555","text":"Test"}}');
        RestContext.request = req;
        //System.assertequals('Client message status: Created | Client followup message status: Created', BandwidthSMSRestCtrl.doPost());
        System.assertequals('Client message status: Created |', BandwidthSMSRestCtrl.doPost());
        
        Test.stopTest();
    }
    
    /*static testMethod void BandwidthSMSPostCall() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new TestBandwidthMockGen());
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{  "eventType": "answer",  "from": "+15555555555",  "to": "+15074037157",  "callId": "123456789",  "callState": "active"}');
        RestContext.request = req;
        System.assert(BandwidthSMSRestCtrl.doPost() == 'Call transfer status status: Created');
        
        Test.stopTest();
    }*/
    
    static testMethod void BandwidthSMSEmail() {
        Test.startTest();
        
        BandwidthSMSRestCtrl.BandwidthMessage bm = new BandwidthSMSRestCtrl.BandwidthMessage();
        bm.message = new BandwidthSMSRestCtrl.SubMessage();
        bm.message.zfrom = '+15555555555';
        bm.message.text = 'Running the test class for the Bandwidth SMS Integration';
        
        //Map<String, Object> m = new Map<String, Object>();
        //m.put('from','+15555555555');
        //m.put('text','Running the test class for the Bandwidth SMS Integration');
        
        System.assert(BandwidthSMSRestCtrl.sendEmail(bm) == 'true');
        
        Test.stopTest();
        
    }
}