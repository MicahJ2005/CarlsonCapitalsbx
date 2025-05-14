@isTest
private class TestNetDocumentsIntegration {

	@testSetup static void setup() {
		// create household
		Account a = new Account(Name='randy hh');
		insert a;
		Contact con = new Contact(LastName='test last name',AccountId=a.Id);
		insert con;
		a = [Select Id, Name, FinServ__PrimaryContact__c From Account Where id = :a.Id Limit 1];
		a.FinServ__PrimaryContact__c = con.Id;
		update a;
		// add document group related to HH
		//Document_Group__c dg = new Document_Group__c(Name='quarterly',household__c=a.Id);
		//insert dg;

		// add client inventory related to HH
		client_inventory__c ci = new Client_Inventory__c(name=a.Name,household__c=a.id);
		insert ci;


		// add attachments to client inventory
		List<sObject> attachments = new List<sObject>();
		for (Integer i=0;i<10;i++) {
			attachments.add(new Attachment(body=Blob.valueOf('testmethodstaticvoid'),name='somefile'+i+'.pdf',parentId=ci.Id));
		}
		insert attachments;

		//// add chatter files to document group
		// Not possible at 2017-01? 
		// Error: System.DmlException: Insert failed. First exception on row 0; first error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, Content cannot be inserted as a child of record a1c29000000AwAh.: [FirstPublishLocationId]
		//attachments = new List<sObject>();
		//for (Integer i=0;i<10;i++) {
		//	attachments.add(new ContentVersion(title='Testing #'+i,versiondata=Blob.valueOf('testmethodstaticvoid'),PathOnClient='somefile'+i+'.pdf',FirstPublishLocationId=dg.Id));
		//}
		//insert attachments;		
	}

	testMethod static void Test_OAuth_Initial_Success() {	
		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = true;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.setCurrentPage(Page.NetDocumentsAuth);
		ApexPages.currentPage().getParameters().put('parentId',[select id from client_inventory__c limit 1].Id);
		NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
		ndcc.obtainAuthCode();
	}

	testMethod static void Test_OAuth_ResponseFromNetDocs_Success() {	
		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = true;
		Test.setMock(HttpCalloutMock.class, cms);	

		Test.startTest();
			Test.setCurrentPage(Page.NetDocumentsAuth);
			ApexPages.currentPage().getParameters().put('code','dummycode');
			NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
			ndcc.obtainAuthCode();
		Test.stopTest();
	}

	testMethod static void Test_OAuth_Initial_Failure() {	
		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = false;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.setCurrentPage(Page.NetDocumentsAuth);
		ApexPages.currentPage().getParameters().put('parentId',[select id from client_inventory__c limit 1].Id);
		NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
		ndcc.obtainAuthCode();
	}

	testMethod static void Test_OAuth_ResponseFromNetDocs_Failure() {	
		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = false;
		Test.setMock(HttpCalloutMock.class, cms);	

		Test.startTest();
			Test.setCurrentPage(Page.NetDocumentsAuth);
			ApexPages.currentPage().getParameters().put('code','dummycode');
			NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
			ndcc.obtainAuthCode();
		Test.stopTest();
	}	

	testMethod static void Test_OAuth_PostDocuments_Success() {	
		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = true;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.setCurrentPage(Page.NetDocumentsPost);
		ApexPages.currentPage().getParameters().put('parentId',[select id from client_inventory__c limit 1].Id);
		NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
		ndcc.postDocuments();
	}


	testMethod static void Test_OAuth_PostDocuments_Failure() {	
		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = false;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.setCurrentPage(Page.NetDocumentsPost);
		ApexPages.currentPage().getParameters().put('parentId',[select id from client_inventory__c limit 1].Id);
		NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
		ndcc.postDocuments();
	}

	testMethod static void Test_OAuth_PostDocumentsBatch_Success() {	
		NetDocumentsSettings__c nds = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
		nds.AccessToken__c='test';
		nds.RefreshToken__c='testrefresh';
		upsert nds;

		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = true;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.startTest();
			NetDocumentsBatch ndb = new NetDocumentsBatch([select id from client_inventory__c limit 1].Id,String.valueOf(UserInfo.getUserId()),true);
			Database.executeBatch(ndb);    	
		Test.stopTest();
	}	

	testMethod static void Test_OAuth_PostDocumentsBatch_Failure() {	
		NetDocumentsSettings__c nds = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
		nds.AccessToken__c='test';
		nds.RefreshToken__c='testrefresh';
		upsert nds;

		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = false;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.startTest();
			NetDocumentsBatch ndb = new NetDocumentsBatch([select id from client_inventory__c limit 1].Id,String.valueOf(UserInfo.getUserId()),true);
			Database.executeBatch(ndb);    	
		Test.stopTest();
	}

	testMethod static void Test_OAuth_CheckUpdatedAccessToken_Success() {	
		NetDocumentsSettings__c nds = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
		nds.AccessToken__c='test';
		nds.RefreshToken__c='testrefresh';
		upsert nds;

		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = true;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.startTest();
			NetDocumentsService.hasUpdatedAccessToken(false,nds);
		Test.stopTest();
	}

	testMethod static void Test_OAuth_CheckUpdatedAccessTokenMultiField_Success() {	
		NetDocumentsSettings__c nds = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
		nds.AccessToken__c='rmOPW3e6ZAlte4whkeNxHM7OTY7tHKPBQI7QSMT7AbXXohj4g+fhkFYLecTJoQVkxbUo5htOE+/IRYo+QzWeCO6pdrJhwoY+Wn5uODtYleGrw2QXLFElN/g3WLufOsJwJeGZi7esKew9oxF6Mb3dIaMAujwB7JB+/LXccfRtxFBmjO/77s6zljhBk7ZtMf27PbHLlyGvTFwyVcAOIIJ0AXml8HJDyCDVXlR8QXhb1MoGcSACyyZcKGOO4nMYTES';
		nds.AccessToken2__c='T';
		nds.RefreshToken__c='testrefresh';
		upsert nds;

		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = true;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.startTest();
			NetDocumentsService.hasUpdatedAccessToken(false,nds);
		Test.stopTest();
	}

	testMethod static void Test_OAuth_CheckUpdatedAccessToken_Failure() {	
		NetDocumentsSettings__c nds = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
		nds.AccessToken__c='test';
		nds.RefreshToken__c='testrefresh';
		upsert nds;

		HttpCalloutMockService cms = new HttpCalloutMockService();
		cms.isSuccessResponse = false;
		Test.setMock(HttpCalloutMock.class, cms);		

		Test.startTest();
			NetDocumentsService.hasUpdatedAccessToken(false,nds);
		Test.stopTest();
	}
}