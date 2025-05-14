@isTest (SeeAllData=true)
public class TestMeetingSummary {
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

        List<Document_Group__c> docGroups = new List<Document_Group__c>{};
        Document_Group__c docGroup = new Document_Group__c(Household__c = household.Id);
        docGroups.add(docGroup);
        insert docGroups;
        
		List<FinServ__FinancialAccount__c> financialAccounts = new List<FinServ__FinancialAccount__c>();
		Id recordTypeId = Schema.sObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByName().get('Investment Account').getRecordTypeId();
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test IRA 0', FinServ__FinancialAccountType__c = 'IRA', FinServ__FinancialAccountNumber__c = '1222-3444', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Nonqualified', FinServ__Balance__c = 10000, Include_on_Net_Worth__c = true));
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test Brokerage 0', FinServ__FinancialAccountType__c = 'Brokerage', FinServ__FinancialAccountNumber__c = '1222-3445', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Qualified', FinServ__Balance__c = 10000, Include_on_Net_Worth__c = true));
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test ACP 0', FinServ__FinancialAccountType__c = 'ACP', FinServ__FinancialAccountNumber__c = '1222-3446', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Qualified', FinServ__Balance__c = 10000, Include_on_Net_Worth__c = true));
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test DAF 0', FinServ__FinancialAccountType__c = 'DAF', FinServ__FinancialAccountNumber__c = '1222-3448', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Qualified', FinServ__Balance__c = 10000, Include_on_Net_Worth__c = true));
		financialAccounts.add(new FinServ__FinancialAccount__c(Name = 'Test Individual Life 0', FinServ__FinancialAccountType__c = 'Individual Life', FinServ__FinancialAccountNumber__c = '1222-3447', RecordTypeId = recordTypeId, FinServ__PrimaryOwner__c = po.Id, FinServ__Household__c = household.Id, FinServ__TaxStatus__c = 'Qualified', FinServ__Balance__c = 10000, Include_on_Net_Worth__c = true));
		insert financialAccounts;

		for (FinServ__FinancialAccount__c fa : financialAccounts) { 
			fa.FinServ__Household__c = household.Id;
		}
		update financialAccounts;
       
    }
        
    static testMethod void errorHandlingTest() {
        
        Test.StartTest();
        //Test error handling
		Test.setCurrentPage(Page.MeetingSummary);
        MeetingSummaryController mscError = new MeetingSummaryController();
        Test.StopTest();
        System.assert(mscError.householdId == null);
    } 
        
    static testMethod void controllerTest() {
        setup();
        Account hh = [SELECT Id FROM Account WHERE Name = 'Test Household ABC'];
        //Financial_Account__c testTaxAcc = [SELECT Id FROM Financial_Account__c WHERE Account_Type__c = 'Individual'];
        //Financial_Account__c testRothAcc = [SELECT Id FROM Financial_Account__c WHERE Account_Type__c = 'Roth IRA'];
        //Financial_Account__c testACPAcc = [SELECT Id FROM Financial_Account__c WHERE Account_Type__c = 'ACP Charitable Gift Fund'];
		//Financial_Account__c testDAFAcc = [SELECT Id FROM Financial_Account__c WHERE Account_Type__c = 'Schwab DAF'];
		//Financial_Account__c testOtherCharitAcc = [SELECT Id FROM Financial_Account__c WHERE Account_Type__c = 'Other Charitable Gift Fund'];
        //List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Randy and Brandy Moss'];
        List<FinServ__FinancialAccount__c> fas = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__Household__c = :hh.Id];
        //Account hh = accounts[0];
        
        Test.StartTest();
        
        //Test when no errors
        Test.setCurrentPage(Page.MeetingSummary);
        //ApexPages.currentPage().getParameters().put('id', hh.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(hh);
        MeetingSummaryController msc = new MeetingSummaryController(sc);
        msc.selectedRowIndex = 1;
        msc.DelTask(); //should delete the first row since the count variable in the controller is set to 1 to start
        system.assert(msc.lstInner.size() == 0);
        msc.AddTask();
        system.assert(msc.lstInner.size() == 1); //Task
        msc.AddTask();
        system.assert(msc.lstInner.size() == 2); //Admin
        msc.AddTask();
        system.assert(msc.lstInner.size() == 3); //Trade
        msc.AddTask();
        system.assert(msc.lstInner.size() == 4); //MM
        msc.AddTask();
        system.assert(msc.lstInner.size() == 5); //Charit ACP
        msc.AddTask();
        system.assert(msc.lstInner.size() == 6); //Charit DAF
        msc.AddTask();
        system.assert(msc.lstInner.size() == 7); //Charit Other
        msc.AddTask();
        system.assert(msc.lstInner.size() == 8); //Tax Task
        /*msc.AddTask();
        system.assert(msc.lstInner.size() == 6); //Contrib*/
        if (msc.lstInner.get(0) != NULL){
            msc.lstInner[0].myTaskVar.Subject = 'Test Subject';
            msc.lstInner[0].myTaskVar.Description = 'Test Description';
            msc.lstInner[0].myTaskVar.OwnerId = UserInfo.getUserId(); //'005i0000000h0uGAAQ';
            msc.lstInner[0].myTaskVar.ActivityDate = date.today();
            if (msc.lstInner.get(1) != NULL){
                msc.lstInner[1].myTaskVarType = 'Admin Task';
                msc.lstInner[1].myTaskVar.Subject = 'Test Subject2';
                msc.lstInner[1].myTaskVar.Description = 'Test Description2';
                msc.lstInner[1].myTaskVar.ActivityDate = date.today();
            }
            if (msc.lstInner.get(2) != NULL){
                msc.lstInner[2].myTaskVarType = 'Trade';
                msc.lstInner[2].myTaskVar.Subject = 'Test Trade Subject';
                msc.lstInner[2].myTaskVar.Description = 'Test Trade Description';
                msc.lstInner[2].myTaskVar.ActivityDate = date.today();
                msc.lstInner[2].myTradeVar.Amount__c = 10000;
                msc.lstInner[2].myTradeVar.FinServ__FinancialAccount__c = fas[0].Id; //testTaxAcc.Id;
            }
            if (msc.lstInner.get(3) != NULL){
                msc.lstInner[3].myTaskVarType = 'Money Movement';
                msc.lstInner[3].myTaskVar.Subject = 'Test MM Subject';
                msc.lstInner[3].myTaskVar.Description = 'Test MM Description';
                msc.lstInner[3].myTaskVar.ActivityDate = date.today();
                msc.lstInner[3].myTradeVar.Amount__c = 6500;
                msc.lstInner[3].myTradeVar.FinServ__FinancialAccount__c = fas[0].Id; //testTaxAcc.Id;
                msc.lstInner[3].myBPVar.To_Account__c = fas[0].Id; //testRothAcc.Id;
                msc.lstInner[3].myBPVar.Contribution_Year__c = 'Current Tax Year';
            }
            if (msc.lstInner.get(4) != NULL){
                msc.lstInner[4].myTaskVarType = 'Charitable Contribution';
                msc.lstInner[4].myTaskVar.Subject = 'Test Charit Subject';
                msc.lstInner[4].myTaskVar.Description = 'Test Charit Description';
                msc.lstInner[4].myTaskVar.ActivityDate = date.today();
                msc.lstInner[4].myTradeVar.Amount__c = 10000;
                msc.lstInner[4].myTradeVar.FinServ__FinancialAccount__c = fas[0].Id; //testTaxAcc.Id;
                msc.lstInner[4].myBPVar.To_Account__c = fas[2].Id; //testACPAcc.Id;
                msc.lstInner[4].myBPVar.ACP_Form_Delivery_to_Client__c = 'Email';
                msc.lstInner[4].myBPVar.ACP_Allocation_Instructions__c = 'Invest';
                msc.lstInner[4].charityType = 'ACP Charitable Contribution';
                msc.lstInner[4].myBPVar.ACP_Charity_Type__c = 'ACP Charitable Contribution';
            }
            if (msc.lstInner.get(5) != NULL){
                msc.lstInner[5].myTaskVarType = 'Charitable Contribution';
                msc.lstInner[5].myTaskVar.Subject = 'Test Charit Subject';
                msc.lstInner[5].myTaskVar.Description = 'Test Charit Description';
                msc.lstInner[5].myTaskVar.ActivityDate = date.today();
                msc.lstInner[5].myTradeVar.Amount__c = 10000;
                msc.lstInner[5].myTradeVar.FinServ__FinancialAccount__c = fas[0].Id; //testTaxAcc.Id;
                msc.lstInner[5].myBPVar.To_Account__c = fas[3].Id; //testDAFAcc.Id;
                msc.lstInner[5].myBPVar.ACP_Form_Delivery_to_Client__c = 'Email';
                msc.lstInner[5].myBPVar.ACP_Allocation_Instructions__c = 'Invest';
                msc.lstInner[5].charityType = 'DAF Charitable Contribution';
                msc.lstInner[5].myBPVar.ACP_Charity_Type__c = 'DAF Charitable Contribution';
            }
            if (msc.lstInner.get(6) != NULL){
                msc.lstInner[6].myTaskVarType = 'Charitable Contribution';
                msc.lstInner[6].myTaskVar.Subject = 'Test Charit Subject';
                msc.lstInner[6].myTaskVar.Description = 'Test Charit Description';
                msc.lstInner[6].myTaskVar.ActivityDate = date.today();
                msc.lstInner[6].myTradeVar.Amount__c = 10000;
                msc.lstInner[6].myTradeVar.FinServ__FinancialAccount__c = fas[0].Id; //testTaxAcc.Id;
                msc.lstInner[6].myBPVar.To_Account__c = fas[0].Id; //testOtherCharitAcc.Id;
                msc.lstInner[6].myBPVar.ACP_Form_Delivery_to_Client__c = 'Email';
                msc.lstInner[6].myBPVar.ACP_Allocation_Instructions__c = 'Invest';
                msc.lstInner[6].charityType = 'Other Charitable Contribution';
                msc.lstInner[6].myBPVar.ACP_Charity_Type__c = 'Other Charitable Contribution';
            }
            if (msc.lstInner.get(7) != NULL){
                msc.lstInner[7].myTaskVarType = 'Tax Task';
                msc.lstInner[7].myTaskVar.Subject = 'Test Subject3';
                msc.lstInner[7].myTaskVar.Description = 'Test Description3';
                msc.lstInner[7].myTaskVar.ActivityDate = date.today();
            }
            system.assert(msc.lstNotes[1].keyContent == 'Net Worth');
            system.assert(msc.lstNotes[4].parsedNotes[0] == 'Retirement projections');
            msc.selectedNoteIndex = 1;
            msc.AddNote();
            msc.lstNotes[1].parsedNotes[2] = 'Test';
            msc.selectedRowIndex = 2;
            msc.IndentNote();
            msc.IndentNote();
            msc.UndentNote();
            msc.AddNote();
            msc.AddNoteSection();
            system.assert(msc.lstNotes[12].keyContent == '');
            system.assert(msc.lstNotes[12].parsedNotes[0] == '');
            msc.lstNotes[12].parsedNotes[0] = 'Test';
            msc.selectedRowIndex = 0;
            msc.selectedNoteIndex = 12;
            msc.DoubleClickNote();
            msc.lstNotes[12].parsedNotes[0] = '';
            msc.DoubleClickNote();
            msc.DoubleClickNote();
            system.assert(msc.lstNotes[12].parsedNotes.isEmpty());
            msc.selectedRowIndex = 0;
            msc.selectedNoteIndex = 1;
            msc.DoubleClickNote();
            msc.DoubleClickNote();
            msc.draggedSection = '0thDrag';
            msc.droppedSection = '1thDrag';
            msc.MoveNote();
            msc.draggedSection = '0tdDrag0';
            msc.EnterAddNote();
            msc.TabIndentNote();
            msc.droppedSection = '0tdDrag1';
            msc.MoveNote();
            msc.categoryRenderer();
            msc.addNoteSection();
            msc.dateVal = '1/4/2017';
            msc.setDateVal();
            msc.save();
            msc.portalSave = true; //not currently testing the portal saving feature
            //msc.docGroups.add(docGroup);
            msc.page();
            msc.getItems();
            msc.getNoteKeys();
            msc.getMindMap();
            //msc.getClassification();
            msc.getTaskNumbers();
            msc.resetNotes();
            msc.getCharitTypes();
        }
        if (msc.household.FinServ__PrimaryContact__c != NULL){
            Boolean taskOne = false;
            Boolean taskTwo = false;
            Boolean taskThree = false;
	        List<Task> taskList = [SELECT Id, Subject, Description, OwnerId, ActivityDate FROM Task WHERE OwnerId = :hh.Id];
            for (Task t : taskList){
                if (t.Subject == 'Test Subject'){
                    taskOne = true;
                    system.assertEquals('Test Description', t.Description);
                    //system.assertEquals('005i0000000h0uGAAQ', t.OwnerId);
                    system.assertEquals(Date.today(), t.ActivityDate);
                } else if (t.Subject == 'Test Subject2') {
                    taskTwo = true;
                    system.assertEquals('Test Description2', t.Description);
                    //system.assertEquals('005i0000000h0uGAAQ', t.OwnerId);
                    system.assertEquals(Date.today(), t.ActivityDate);
                } else if (t.Subject == 'Test Subject3') {
                    taskThree = true;
                    system.assertEquals('Test Description3', t.Description);
                    //system.assertEquals('005i0000000h0uGAAQ', t.OwnerId);
                    system.assertEquals(Date.today(), t.ActivityDate);
                } else {
                    system.assertEquals(true, false); //Found more tasks than intended, throw error
                }
            }
            
            Case myTrade = [SELECT Id, Subject, Description, OwnerId, FSTR__Due_Date__c, Amount__c FROM Case WHERE Subject = 'Test Trade Subject'];
        	system.assertEquals('Test Trade Subject', myTrade.Subject);
            system.assertEquals('Test Trade Description', myTrade.Description);
            //system.assertEquals('005i0000000h0uGAAQ', myTrade.OwnerId);
            system.assertEquals(Date.today(), myTrade.FSTR__Due_Date__c);
            system.assertEquals(10000, myTrade.Amount__c);
        }


        Test.StopTest();
        System.assert(!msc.saveErrors);
    }
}