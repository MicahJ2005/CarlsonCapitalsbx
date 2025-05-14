/**
 * @description       : 
 * @author            : Michael Lloyd (Demand Chain)
 * @group             : 
 * @last modified on  : 10-11-2022
 * @last modified by  : Michael Lloyd (Demand Chain)
**/
@isTest  (SeeAllData=true)
private class TestNetWorth {
    //@testSetup
    public static void setup() {
		Account household = new Account(name='Test Household ABC', FinServ__Status__c = 'Client', Type = 'Integrated Wealth Management', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId());
		insert household;	

		FinServ__UsePersonAccount__c personAccountConfig = new FinServ__UsePersonAccount__c();
		personAccountConfig.Name = 'Use Person Account';
		personAccountConfig.FinServ__Enable__c = true;
		//insert personAccountConfig;
		
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

		List<InsurancePolicy> policies = new List<InsurancePolicy>();
    	policies.add(new InsurancePolicy(Name = 'Test Policy 0', FinServ__Household__c = household.Id, RecordTypeId = Schema.sObjectType.InsurancePolicy.getRecordTypeInfosByName().get('Life Insurance').getRecordTypeId(), Include_on_Net_Worth__c = true, NameInsuredId = po.Id, Status = 'In Force', Policy_Owner__c = 'Owner', On_Balance_Sheet__c = true));
    	policies.add(new InsurancePolicy(Name = 'Test Pipeline Policy 0', FinServ__Household__c = household.Id, RecordTypeId = Schema.sObjectType.InsurancePolicy.getRecordTypeInfosByName().get('Pipeline').getRecordTypeId(), NameInsuredId = po.Id));
		insert policies;

		List<FinServ__FinancialAccount__c> financialAccounts = new List<FinServ__FinancialAccount__c>();
		Id recordTypeId = Schema.sObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByName().get('Investment Account').getRecordTypeId();
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test IRA 0', FinServ__FinancialAccountType__c = 'IRA', FinServ__FinancialAccountNumber__c = '1222-3444', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Nonqualified', FinServ__Balance__c = 10000, Include_on_Net_Worth__c = true));
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test Brokerage 0', FinServ__FinancialAccountType__c = 'Brokerage', FinServ__FinancialAccountNumber__c = '1222-3445', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Qualified', FinServ__Balance__c = 20000, Include_on_Net_Worth__c = true));
		insert financialAccounts;

		List<FinServ__AssetsAndLiabilities__c> assets = new List<FinServ__AssetsAndLiabilities__c>();
		assets.add(new FinServ__AssetsAndLiabilities__c(Name = 'Asset 0', FinServ__AssetsAndLiabilitiesType__c = 'Cash', FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, Taxable__c = false, Total_Assets__c = 10000, Include_on_Net_Worth__c = true, RecordTypeId = Schema.SObjectType.FinServ__AssetsAndLiabilities__c.getRecordTypeInfosByDeveloperName().get('NonfinancialAsset').getRecordTypeId()));
		insert assets;

		List<Beneficiary__c> beneficiaries = new List<Beneficiary__c>();
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Primary'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Contingent'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Tertiary'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Trustee'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Annuitant'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'POA'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Successor Trustee'));
		beneficiaries.add(new Beneficiary__c(Financial_Account_Orion__c = financialAccounts[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Final Beneficiary'));
		beneficiaries.add(new Beneficiary__c(Asset_Liability_Account__c = assets[0].Id, Household__c = household.Id, Contact__c = c.Id, Percentage__c = 10, Type__c = 'Primary'));
		insert beneficiaries;

		for (FinServ__FinancialAccount__c fa : financialAccounts) { 
			fa.FinServ__Household__c = household.Id;
		}
		update financialAccounts;

		for (InsurancePolicy p : policies) {
			p.FinServ__Household__c = household.Id;
		}
		update policies;
	}

	static testMethod void Test_UploadToBox() {
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
		Account household = accounts[0];

        Test.StartTest();

		Test.setMock(HttpCalloutMock.class, new MockBoxToolkitResponse());

		Test.setCurrentPage(Page.NetWorth);
		ApexPages.currentPage().getParameters().put('id',household.Id);
		NetWorthCtrl nw = new NetWorthCtrl();
		nw.uploadToBox = true;
		nw.maskAccountNumbers = true;
		nw.generatePDF();
		Test.StopTest();
	}

	static testMethod void Test_NetWorthPageForAccount() {
		//setup();
		//Account household = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];
		//List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Household0'];
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
		Account household = accounts[0];

        Test.StartTest();
		Test.setCurrentPage(Page.NetWorth);
		ApexPages.currentPage().getParameters().put('id',household.Id);
		NetWorthCtrl nw = new NetWorthCtrl();
		for (EstateSummaryGrid esg : nw.finalEstateLayout) {
			if (esg.reportAssets != null) {
				Double jt = esg.getJointTotal();
				Double ot = esg.getOtherTotal();
			}
		}
        Test.StopTest();

		System.assert(nw != null);
	}

	static testMethod void Test_NetWorthPageForPolicy() {
		//setup();
		//Account household = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];
		//List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Household0'];
		//List<InsurancePolicy> ips = [SELECT Id FROM InsurancePolicy WHERE FinServ__Household__c=:accounts[0].Id AND Name LIKE 'Test Policy%'];
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
		Account household = accounts[0];
		List<InsurancePolicy> ips = [SELECT Id FROM InsurancePolicy WHERE FinServ__Household__c=:household.Id];

        Test.StartTest();
		Test.setCurrentPage(Page.NetWorth);
		ApexPages.currentPage().getParameters().put('id',household.Id);
		ApexPages.currentPage().getParameters().put('itemId',ips[0].Id);
		NetWorthCtrl nw = new NetWorthCtrl();

		// edit objects
		nw.queryEditInsObj();
		nw.saveEditInsValues();	
        Test.StopTest();

		System.assert(nw != null);
		System.assert(nw.editIns != null);

	}

	static testMethod void Test_NetWorthPageForPolicyClosed() {
		//setup();
		//Account household = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];
		//List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Household0'];
		//List<InsurancePolicy> ips = [SELECT Id FROM InsurancePolicy WHERE FinServ__Household__c=:accounts[0].Id AND Name LIKE 'Test Policy%'];
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
		Account household = accounts[0];
		List<InsurancePolicy> ips = [SELECT Id FROM InsurancePolicy WHERE FinServ__Household__c=:household.Id];

        Test.StartTest();
		Test.setCurrentPage(Page.NetWorth);
		ApexPages.currentPage().getParameters().put('id',household.Id);
		ApexPages.currentPage().getParameters().put('itemId',ips[0].Id);
		NetWorthCtrl nw = new NetWorthCtrl();

		// edit objects
		nw.queryEditInsObj();
		nw.editIns.Status= 'Cancelled';
		nw.saveEditInsValues();	
        Test.StopTest();

		System.assert(nw != null);
		System.assert(nw.editIns != null);
		InsurancePolicy ip = [SELECT Id, Status, CancellationDate FROM InsurancePolicy WHERE Id = :ips[0].Id];
		System.assertEquals('Cancelled', ip.Status);

	}

	static testMethod void Test_NetWorthPageForFinancialAccount() {
		//setup();
		//Account household = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];
		//List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Household0'];
		//List<FinServ__FinancialAccount__c> fas = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c=:accounts[0].Id];
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
		Account household = accounts[0];
		List<FinServ__FinancialAccount__c> fas = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c=:household.Id];

        Test.StartTest();
		Test.setCurrentPage(Page.NetWorth);
		ApexPages.currentPage().getParameters().put('id',household.Id);
		ApexPages.currentPage().getParameters().put('itemId',fas[0].Id);
		NetWorthCtrl nw = new NetWorthCtrl();

		// edit objects
		nw.queryEditObj();
		nw.editFA.FinServ__Balance__c = 10001;
		nw.saveEditValues();
        Test.StopTest();

		System.assert(nw != null);
		//System.assert(nw.editFA != null);
		//FinServ__FinancialAccount__c fa = [SELECT Id, FinServ__Balance__c, As_of_Date__c FROM FinServ__FinancialAccount__c WHERE Id = :fas[0].Id];
		//System.assertEquals(10001, fa.FinServ__Balance__c);
		//System.assertEquals(Date.today(), fa.As_of_Date__c);
	}

	static testMethod void Test_NetWorthPageForFinancialAccountClose() {
		//setup();
		//Account household = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];
		//List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Household0'];
		//List<FinServ__FinancialAccount__c> fas = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c=:accounts[0].Id];
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
		Account household = accounts[0];
		List<FinServ__FinancialAccount__c> fas = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c=:household.Id];

        Test.StartTest();
		Test.setCurrentPage(Page.NetWorth);
		ApexPages.currentPage().getParameters().put('id',household.Id);
		ApexPages.currentPage().getParameters().put('itemId',fas[0].Id);
		NetWorthCtrl nw = new NetWorthCtrl();

		// edit objects
		nw.queryEditObj();
		nw.editFA.OASP_FSC__Active__c = false;
		nw.saveEditValues();
        Test.StopTest();

		System.assert(nw != null);
		//System.assert(nw.editFA != null);
		//FinServ__FinancialAccount__c fa = [SELECT Id, FinServ__Balance__c, As_of_Date__c, Account_Notes__c, FinServ__Household__c, FinServ__Household__r.Name, FinServ__PrimaryOwner__c, FinServ__JointOwner__c FROM FinServ__FinancialAccount__c WHERE Id = :fas[0].Id];
		//System.assert(fa.Account_Notes__c != null);
		//System.assertEquals('CCM Old Net Worth Accounts', fa.FinServ__Household__r.Name);
		//System.assert(fa.FinServ__PrimaryOwner__c == null);
		//System.assert(fa.FinServ__JointOwner__c == null);
	}
	
	static testMethod void Test_NetWorthUtilities() {
		// custodian-based classification
		System.assertEquals(NetWorthUtilities.categorizeAccount('ira','TIAA-CREF'),'Retirement');
		System.assertEquals(NetWorthUtilities.categorizeAccount('ira','BAAsomething'),'Retirement');
		// account type-based classification
		System.assertEquals(NetWorthUtilities.categorizeAccount('ira','Generic'),'Retirement');
		System.assertEquals(NetWorthUtilities.categorizeAccount('joint','Generic'),'Investment');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Schwab Savings Account','Generic'),'Bank');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Cash and Munis','Generic'),'Bank');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Estate Account','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Estate Trust','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Exempt GST  Share Trust','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('ACP Charitable Gift Fund','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Jackson National Life NQ','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Pac Life Annuity','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('TIAA - ATRA','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('TIAA - ATRA TPA','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('TIAA Lifetime Var Select(NQ)','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('TIAA Personal Annuity','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Nationwide VA','Generic'),'Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Nationwide VA CRT','Generic'),'Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('John Hancock UL','Generic'),'Insurance');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Note Receivable','Generic'),'Off-Balance Sheet');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Credit Shelter Trust','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Supplemental Needs Trust','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Trust - Scottrade','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Trust B','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Children Family Trust II','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('MHS Charitable Remainder Trust','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('MHS Gift Annuity','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('roth','Generic'),'Roth');
		System.assertEquals(NetWorthUtilities.categorizeAccount('401(k)','Generic'),'Retirement');
		System.assertEquals(NetWorthUtilities.categorizeAccount('403(b)','Generic'),'Retirement');
		System.assertEquals(NetWorthUtilities.categorizeAccount('corporate','Generic'),'Business');
		System.assertEquals(NetWorthUtilities.categorizeAccount('partnership','Generic'),'Business');
		System.assertEquals(NetWorthUtilities.categorizeAccount('business','Generic'),'Business');
		System.assertEquals(NetWorthUtilities.categorizeAccount('margin account','Generic'),'Liabilities');
		System.assertEquals(NetWorthUtilities.categorizeAccount('mortgage','Generic'),'Liabilities');
		System.assertEquals(NetWorthUtilities.categorizeAccount('liability','Generic'),'Liabilities');
		System.assertEquals(NetWorthUtilities.categorizeAccount('liabilities','Generic'),'Liabilities');
		System.assertEquals(NetWorthUtilities.categorizeAccount('cdbank','Generic'),'Investment');
		System.assertEquals(NetWorthUtilities.categorizeAccount('living trust','Generic'),'Investment');
		System.assertEquals(NetWorthUtilities.categorizeAccount('checking','Generic'),'Bank');
		System.assertEquals(NetWorthUtilities.categorizeAccount('bank','Generic'),'Bank');
		System.assertEquals(NetWorthUtilities.categorizeAccount('real estate','Generic'),'Real Estate');
		System.assertEquals(NetWorthUtilities.categorizeAccount('ILIT','Generic'),'Off-Balance Sheet');
		System.assertEquals(NetWorthUtilities.categorizeAccount('non?q','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('nonq','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('variable annuity','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('non?qualifiedannuity','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('annuitynon?qualified','Generic'),'Non-Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Vanguard Annuity','Generic'),'Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Lincoln Benefit','Generic'),'Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('annuity','Generic'),'Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('annuities','Generic'),'Qualified Annuity');
		System.assertEquals(NetWorthUtilities.categorizeAccount('variable life','Generic'),'Insurance');
		System.assertEquals(NetWorthUtilities.categorizeAccount('universal life','Generic'),'Insurance');
		System.assertEquals(NetWorthUtilities.categorizeAccount('insurance','Generic'),'Insurance');
		System.assertEquals(NetWorthUtilities.categorizeAccount('Charitable Remainder Trust','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('CRT','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('CTC','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('generation skipping','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('gst','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('irrev','Generic'),'Irrevocable Trust');
		System.assertEquals(NetWorthUtilities.categorizeAccount('529','Generic'),'Education Plan');
		System.assertEquals(NetWorthUtilities.categorizeAccount('education','Generic'),'Education Plan');
		System.assertEquals(NetWorthUtilities.categorizeAccount('ACP','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('DAF','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('donar advised','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('non-profit','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('charity','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('charitable','Generic'),'Charitable');
		System.assertEquals(NetWorthUtilities.categorizeAccount('taxable','Generic'),'Investment');
		System.assertEquals(NetWorthUtilities.categorizeAccount('investment','Generic'),'Investment');
		System.assertEquals(NetWorthUtilities.categorizeAccount('death','Generic'),'Insurance Death Benefits');
		System.assertEquals(NetWorthUtilities.categorizeAccount('property','Generic'),'Personal Property/Autos');
		System.assertEquals(NetWorthUtilities.categorizeAccount('auto','Generic'),'Personal Property/Autos');
		System.assertEquals(NetWorthUtilities.categorizeAccount('car','Generic'),'Personal Property/Autos');
		System.assertEquals(NetWorthUtilities.categorizeAccount('vehicle','Generic'),'Personal Property/Autos');
		System.assertEquals(NetWorthUtilities.categorizeAccount('off?balance','Generic'),'Off-Balance Sheet');
		System.assertEquals(NetWorthUtilities.categorizeAccount('offliabilities','Generic'),'Off Balance Liabilities');
		System.assertEquals(NetWorthUtilities.categorizeAccount('offliability','Generic'),'Off Balance Liabilities');
	}		

}