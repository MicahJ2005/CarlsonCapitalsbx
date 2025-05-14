@isTest (SeeAllData=true)
private class TestFinancialAccountEditController {
	
	private static void createFinancialAccounts(Integer toCreate, Account household) {
		FinServ__WealthAppConfig__c wealthAppConfig = new FinServ__WealthAppConfig__c();
		wealthAppConfig.FinServ__ReferrerScoreCalcEnabled__c = true;
		wealthAppConfig.FinServ__EnableGroupRecordRollups__c = true;
		wealthAppConfig.FinServ__EnableBusinessReferralsMade__c = true;
		wealthAppConfig.FinServ__EnableRollupSummary__c = true;
		wealthAppConfig.SetupOwnerId = UserInfo.getOrganizationId();
		//insert wealthAppConfig;

		FinServ__UsePersonAccount__c personAccountConfig = new FinServ__UsePersonAccount__c();
		personAccountConfig.Name = 'Use Person Account';
		personAccountConfig.FinServ__Enable__c = true;
		//insert personAccountConfig;
		
		List<FinServ__FinancialAccount__c> fas = new List<FinServ__FinancialAccount__c>();
		List<FinServ__AssetsAndLiabilities__c> assets = new List<FinServ__AssetsAndLiabilities__c>();
		Account po = new Account(FirstName='Primary', LastName='Owner', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId());
		insert po;	

		Contact c = [SELECT Id FROM Contact WHERE AccountId = :po.Id];
		Account pa = [SELECT PersonContactId FROM Account WHERE Id = :po.Id];

		AccountContactRelation relation = new AccountContactRelation(
			AccountId = household.Id,
			ContactId = pa.PersonContactId,
        	IsActive = true,
        	FinServ__PrimaryGroup__c = true,
        	FinServ__Primary__c = true,
        	Roles = 'Client',
        	FinServ__Rollups__c = 'Tasks;Events;Financial Accounts;Assets and Liabilities;Financial Goals;All;Referrals;Opportunities'
		);
		insert relation;

		for (Integer i=0;i<toCreate;i++) { 
			FinServ__FinancialAccount__c f = new FinServ__FinancialAccount__c(
				Name='FA-'+String.valueOf(i),
				FinServ__Household__c=household.Id,
				FinServ__PrimaryOwner__c = po.Id,
				FinServ__Status__c = 'Open',
				OASP_FSC__Active__c = true,
				RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('InvestmentAccount').getRecordTypeId()
			);
			fas.add(f);
			System.debug(f);
			FinServ__AssetsAndLiabilities__c a = new FinServ__AssetsAndLiabilities__c(
				Name='AL-'+String.valueOf(i),
				FinServ__Household__c = household.Id,
				FinServ__PrimaryOwner__c = po.Id,
				Closed__c = false
			);
			assets.add(a);
		}
		insert fas;
		insert assets;

		for (Integer i=0;i<toCreate;i++) { 
			fas[i].FinServ__Household__c=household.Id;
			assets[i].FinServ__Household__c = household.Id;
		}
		update fas;
		update assets;

	}

	@isTest static void Test_SuccessFinancialAccountEditController() {
		Account th = new Account(name='Test Household', FinServ__Status__c = 'Client', Type = 'Integrated Wealth Management', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId());
		insert th;	
		Integer numAccts = 2;
		createFinancialAccounts(numAccts,th);

		//Account th = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];

		Test.startTest();

			Test.setCurrentPage(Page.FinancialAccountEdit);	
        	ApexPages.StandardController sc = new ApexPages.StandardController(th);
			FinancialAccountEditController ext = new FinancialAccountEditController(sc);

			// ensure event lists are populated as expected (today is chosen automatically as the selected date)
			System.assertEquals(false, ext.finAccts.isEmpty(), 'Number of accounts expected did not populate in list');

			// change one financial account
			String startFieldVal = ext.finAccts[0].FinServ__Description__c;	

			// test changing the field value and canceling the change
			ext.finAccts[0].FinServ__Description__c = 'Test';
			ext.cancel();
			System.assertEquals(startFieldVal,ext.finAccts[0].FinServ__Description__c);

			// test changing the field value and saving the change
			ext.finAccts[0].FinServ__Description__c = 'Test';				
			ext.save();
			System.assertEquals('Test',ext.finAccts[0].FinServ__Description__c,'Test field value did not change as expected.');

		Test.stopTest();
	}

	static testMethod void Test_FailureNoFinancialAccounts() {
		Account th = new Account(name='Test Household', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId());
		insert th;	

		Test.startTest();

			Test.setCurrentPage(Page.FinancialAccountEdit);	
        	ApexPages.StandardController sc = new ApexPages.StandardController(th);
			FinancialAccountEditController ext = new FinancialAccountEditController(sc);

			// we should receive one error message (no financial accounts are associated with this household)
			System.assertEquals(0,ApexPages.getMessages().size(),'A household without financial accounts should not throw an error.');

		Test.stopTest();
	}		
	
}