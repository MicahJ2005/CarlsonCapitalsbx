public with sharing class MeetingSummaryController {
    //Task Vars
    public List<innerClass> lstInner{get;set;}
    public Integer taskCount = 0;
    public Boolean pageErrors {get;private set;} //pageErrors will prevent the page from loading
    public Boolean saveErrors {get;private set;} //saveErrors will prevent the page from creating tasks before all errors are fixed 
	public Account household {get;set;}
    public List<Document_Group__c> docGroups {get; set;}
    public List<Task> taskToCreate {get; set;}
    public List<Task> taskToNote {get; set;}
    public List<Case> tradeToNote {get; set;}
    public List<Login_Information__c> baaErrors {get; set;}
    public List<FinServ__FinancialAccount__c> acpErrors {get; set;}
    public List<String> statuses {get; set;}
    public List<Case> tradeToCreate {get; set;}
    public List<FSTR__Business_Process__c> processToCreate {get; set;}
    public Id householdId {get; set;}
    public String dateVal {get; set;}
    public Datetime newDateVal {get; set;}
    public String currentUser {get; set;}
    public List<Task> tasksCreated {get; set;}
    public List<FSTR__Business_Process__c> processCreated {get; set;}
    public List<Case> tradeCreated {get; set;}
	
    //Note Vars
    public List<NoteWrapper> lstNotes {get; set;}
    public Integer selectedRowIndex{get;set;}
    public Integer selectedNoteIndex{get;set;}
    public Integer noteCount = 0;
    public String stringInnerNotes {get; set;}
    public List<String> crmMapKeys {get; set;}
    public List<String> crmMapValues {get; set;}
    public List<String> crmMapKeysDup {get; set;}
    public List<String> crmMapValuesDup {get; set;}
    public List<Integer> lstCount {get; set;}
    public Boolean tempBool {get; set;} //Used to check if values exist during save 
    public Integer tempInt {get; set;} //Used to prevent issues with IPS review dates on rendering and also used to move note sections
    public String wordSave {get; set;}
    public Integer alreadySaved {get;set;}
    public String draggedSection {get; set;}
    public String droppedSection {get; set;}
    public String enterSection {get; set;}
    public String tabSection {get; set;}
    public List<List<Boolean>> assignedList{get; set;}
    
    //Variables to determine which fields to render
    public Boolean renderTask {get; set;}
    public Boolean renderTrade {get; set;}
    public Boolean renderMoneyMove {get; set;}
    public Boolean renderCharit {get; set;}
    public Boolean renderContrib {get; set;}
    public Set<String> activeCategories {get; set;}
    
    private static NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
    public Boolean authRequired {get;private set;}
    public Boolean authChecked {get; set;}
    public Boolean saveToNetDocs {get; set;}
    public Boolean portalSave {get; set;}
    public String pageRefPDF{get;set;}
    public PageReference ref{get;set;}

    public AccountTeamMember primaryAdvisor {get; set;}
    public AccountTeamMember secondaryAdvisor {get; set;}
    public String primaryName {get; set;}
    public String spouseName {get; set;}
    
    public List<SelectOption> getCharitTypes(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('ACP Charitable Contribution', 'ACP Charitable Contribution'));
        options.add(new SelectOption('DAF Charitable Contribution', 'DAF Charitable Contribution'));
        options.add(new SelectOption('Other Charitable Contribution', 'Other Charitable Contribution'));
        return options;
    }
    
    public List<SelectOption> getItems(){
        
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Task', 'Task'));
        options.add(new SelectOption('Admin Task', 'Admin Task'));
        options.add(new SelectOption('Tax Task', 'Tax Task'));
        options.add(new SelectOption('Trade', 'Trade'));
        options.add(new SelectOption('Money Movement', 'Money Movement'));
        options.add(new SelectOption('Charitable Contribution', 'Charitable Contribution'));
        return options;
    }
    
    public List<SelectOption> getNoteKeys(){
        
        List<SelectOption> keys = new List<SelectOption>();
        for (String key : CRMMapKeys){
            keys.add(new SelectOption(key, key));
        }
        return keys;
    }
    
    public List<SelectOption> getMindMap(){
        
        List<SelectOption> mindMapOptions = new List<SelectOption>();
        mindMapOptions.add(new SelectOption('', ''));
        mindMapOptions.add(new SelectOption('Circle of Care', 'Circle of Care'));
        mindMapOptions.add(new SelectOption('Investment Planning', 'Investment Planning'));
        mindMapOptions.add(new SelectOption('Tax Planning', 'Tax Planning'));
        mindMapOptions.add(new SelectOption('Retirement/Cash Flow', 'Retirement/Cash Flow'));
        mindMapOptions.add(new SelectOption('Estate Planning', 'Estate Planning'));
        mindMapOptions.add(new SelectOption('Insurance Planning', 'Insurance Planning'));
        return mindMapOptions;
    }
    
    public List<SelectOption> getTaskNumbers(){
        
        List<SelectOption> taskNumOptions = new List<SelectOption>();
        Integer taskNum = 0;
        while (taskNum <= taskCount){
        	taskNumOptions.add(new SelectOption(String.valueOf(taskNum), String.valueOf(taskNum)));
            taskNum++;
        }
        return taskNumOptions;
    }
    
    public PageReference actionMethods(){
        //TrackPageView tpv = new TrackPageView();
        //tpv.trackPageView();
        Page_View__c p = new Page_View__c();
        p.User__c = UserInfo.getUserId();
        if(Apexpages.currentPage().getUrl() != null) {
        	p.Page_Name__c = Apexpages.currentPage().getUrl().substringAfter('/apex/').substringBefore('?');            
        }
		p.Access_Time__c = DateTime.now();
        if(!Test.isRunningTest()) {
            insert p;
        }
        return null;
    }
    
    public MeetingSummaryController() {
        householdId = ApexPages.currentPage().getParameters().get('id');
        if (householdId == NULL) {
            pageErrors = True;
            system.debug('Must have a household ID for this page to generate');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must have a household ID for this page to generate'));
        } else {
            init();
        }
    }

    public MeetingSummaryController(ApexPages.StandardController stdController) {
        householdId = stdController.getRecord().Id;
        init();
    }

    public void init() {
        //Task section
        lstInner = new List<innerClass>();
        renderTask = True;
        renderTrade = False;
        renderMoneyMove = False;
    	renderCharit = False;
        renderContrib = False;
        activeCategories = new Set<String>();
        AddTask();
        tempBool = False;
        tempInt = 0;
        alreadySaved = 0;
        if (portalSave == NULL) {
	        portalSave = False;
        }
        if (saveToNetDocs == NULL) {
	        saveToNetDocs = False;
        }
        wordSave = 'pdf';
        dateVal = Datetime.now().format('MMMM d, yyyy');
        newDateVal = Datetime.now();
        currentUser = UserInfo.getName();

        //Note section
        lstNotes = new List<noteWrapper>();
        lstCount = new List<Integer>();
        statuses = new List<String>();
        selectedRowIndex = 0;
        selectedNoteIndex = 0;
        CRMMapValues = new List<String>();
        CRMMapKeys = new List<String>();
        CRMMapValuesDup = new List<String>();
        CRMMapKeysDup = new List<String>();
        
        Integer c = 0; //numbers main
        Integer d = 0; //lettering lowercase
        Integer e = 0; //numbers secondary
        Integer f = 0; //lettering uppercase
        String alpha = 'abcdefghijklmnopqrstuvwxyz';
        
        authRequired = False;
        authChecked = False;
        pageErrors = False;
        saveErrors = False;
        
        household = [SELECT Id, Name, FinServ__PrimaryContact__c, Meeting_Map_Values__c, Meeting_Map_Keys__c, IAA_Date__c, IPS_Review_Date__c, Alert_Message__c, FinServ__PrimaryContact__r.FirstName, Salutation, (SELECT Id, AccountId, Account.Name, Account.FirstName FROM AccountContactRelations WHERE Roles INCLUDES ('Spouse'))
                        FROM Account WHERE Id = :householdId];

        primaryName = household.FinServ__PrimaryContact__c != null ? household.FinServ__PrimaryContact__r.FirstName : '';
        spouseName = '';
        if (household.AccountContactRelations != null && !household.AccountContactRelations.isEmpty()) {
            spouseName = household.AccountContactRelations[0].Account.FirstName;
        }
                
        List<AccountTeamMember> members = [SELECT UserId, User.FirstName, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :householdId AND (TeamMemberRole = 'Primary Advisor' OR TeamMemberRole = 'Secondary Advisor')];
        for (AccountTeamMember m : members) {
            if (m.TeamMemberRole == 'Primary Advisor') {
                primaryAdvisor = m;
            }
            else if (m.TeamMemberRole == 'Secondary Advisor') {
                secondaryAdvisor = m;
            }
        }
        statuses.add('Completed');
        statuses.add('Canceled');
        taskToNote = [SELECT Subject, ActivityDate FROM Task WHERE AccountId = :householdId AND Status NOT IN :statuses];
        tradeToNote = [SELECT Subject, FSTR__Due_Date__c FROM Case WHERE AccountId = :householdId AND Status = 'Closed' AND RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Trade').getRecordTypeId()];
        baaErrors = [SELECT Last_Updated__c, Error_Message__c, Error_Days__c, Login__c, Password__c, Website__c  FROM Login_Information__c
                         WHERE Client__c = :householdId AND Open_Accounts__c > 0 AND Error_Code__c <> NULL];
        acpErrors = [SELECT FinServ__Balance__c FROM FinServ__FinancialAccount__c WHERE FinServ__FinancialAccountType__c = 'ACP Charitable Gift Fund' AND FinServ__Balance__c < 1000 AND FinServ__Balance__c > 1 AND FinServ__Household__c = :householdId];
        try {
            docGroups = [SELECT Id FROM Document_Group__c WHERE Household__c = :householdId AND Type__c = 'Other Shared Documents'];
        } catch(Exception docError){
            docGroups = NULL; //worth creating the docGroup here if they are already opted in?
        }
        if (household.Meeting_Map_Keys__c == null){
            if (currentUser == 'Matthew Rich'){
                CRMMapKeys.add('Background and Updates');
                CRMMapKeys.add('Net Worth');
                CRMMapKeys.add('Investment Performance and Allocation');
                CRMMapKeys.add('Cash Flow');
                CRMMapKeys.add('Employment/Retirement');
                CRMMapKeys.add('Tax Planning');
                CRMMapKeys.add('Insurance Planning');
                CRMMapKeys.add('Estate Planning');
                CRMMapKeys.add('Charitable Planning');
                CRMMapKeys.add('Education Planning');
                CRMMapKeys.add('Circle of Care');
                CRMMapKeys.add('Action Steps');
                household.Meeting_Map_Keys__c = JSON.serialize(crmMapKeys);
                CRMMapValues.add('Family;;Travel;;Health'); //Background and Updates
                CRMMapValues.add('Electronic balance sheet;;Update values where necessary;;Confirm beneficiaries are accurate and complete'); //Net Worth
                CRMMapValues.add('Last quarterly report;;Performance numbers;;Current position statement and allocation across accounts'); //Investment
                CRMMapValues.add('Major expenses;;Liquidity needs;;Social Security'); //Cash Flow
                CRMMapValues.add('Work update;;Retirement plans'); //Employment/Retirement
                CRMMapValues.add('Income tax projections;;Capital gains and losses summary;;Discuss impact of any legislative changes;;RMD discussion'); //Tax
                CRMMapValues.add('In-force policy management'); //Insurance
                CRMMapValues.add('Estate plan summary;;Review net value of estate and discuss any estate tax implications;;Ensure that asset titling and beneficiaries are consistent with current plan;;DPOA/Health care directive;;Ensure that all documents are current and on file'); //Estate
                CRMMapValues.add('Charitable fund balances;;Charitable cash flows;;Future plans'); //Charitable
                CRMMapValues.add('Fund balances;;Projections and future plans'); //Education
                CRMMapValues.add('Recap meeting and action steps below;;How are we doing?;;Meeting frequency'); //Circle of Care
                CRMMapValues.add(' '); //Action Steps
                household.Meeting_Map_Values__c = JSON.serialize(crmMapValues);
            } else {
                //Default Note Sections if nothing exists
                CRMMapKeys.add('Net Worth');
                CRMMapKeys.add('Background/Family');
                CRMMapKeys.add('Investment Planning');
                CRMMapKeys.add('Cash Flow/Retirement Planning');
                CRMMapKeys.add('Education Planning');
                CRMMapKeys.add('Tax Planning');
                CRMMapKeys.add('Charitable Planning');
                CRMMapKeys.add('Insurance Planning');
                CRMMapKeys.add('Estate Planning');
                CRMMapKeys.add('Trusts');
                CRMMapKeys.add('Circle of Care');
                household.Meeting_Map_Keys__c = JSON.serialize(crmMapKeys);
                CRMMapValues.add('Review Balance Sheet;;Update values where necessary'); //Net Worth
                CRMMapValues.add('Updates;;Travel plans'); //Background/Family
                CRMMapValues.add('Review last quarterly report;;Review Performance;;Current position statement and allocation across accounts'); //Investment
                CRMMapValues.add('Retirement projections;;Major expenses;;Liquidity needs'); //Cash Flow/Retirement
                CRMMapValues.add('Fund balances;;Projections'); //Education 
                CRMMapValues.add('Review of prior year return;;Income tax projections;;Realized gain/loss summary;;Legislation changes impact;;RMD discussion'); //Tax
                CRMMapValues.add('Charitable fund balances;;Charitable cash flows;;Future plans'); //Charitable
                CRMMapValues.add('In-force policy management'); //Insurance
                CRMMapValues.add('Estate plan executive summary;;Review net value of estate;;Revisit division of assets;;Review beneficiary designations;;Funding your revocable trusts;;Changes to consider?;;DPOA/Health care directive'); //Estate
                CRMMapValues.add('Crummy letters;;Income distributions;;Tax matters'); //Trusts
                CRMMapValues.add('Meeting Summary and Recap of action items - Documentation;;How are we doing?;;Schedule next meeting'); //Circle of Care
                household.Meeting_Map_Values__c = JSON.serialize(CRMMapValues);
            }
        } else {
            CRMMapKeys = (List<String>) JSON.deserialize(household.Meeting_Map_Keys__c, List<String>.class);
            CRMMapValues = (List<String>) JSON.deserialize(household.Meeting_Map_Values__c, List<String>.class);
        }
        
        //Prevents issues with IPS Review Date being null
        if (household.IPS_Review_Date__c == NULL){
            tempInt = 2015;
        } else {
           tempInt = household.IPS_Review_Date__c.year(); 
        }
        //Create Matthew's 'basics' section
        if (currentUser == 'Matthew Rich'){
            CRMMapKeys.add(0, 'Basics');
            String primaryAdvisorFirstName = primaryAdvisor != null ? primaryAdvisor.User.FirstName : '';
            String secondaryAdvisorFirstName = secondaryAdvisor != null ? secondaryAdvisor.User.FirstName : '';
            CRMMapValues.add(0, 'CCM: ' + primaryAdvisorFirstName + (secondaryAdvisorFirstName != NULL ? (' and ' + secondaryAdvisorFirstName) : ('')) + ';;Client: ' + household.Salutation + ';;Location: ');
        }
        //Creates automatic section
        if (household.IAA_Date__c == NULL || tempInt < 2016 || household.Alert_Message__c != NULL || taskToNote.size() > 0 || tradeToNote.size() > 0 || baaErrors.size() > 0 || acpErrors.size() > 0){
            CRMMapKeys.add(0, 'Team Requests');
            CRMMapValues.add(0, '');
            if (household.IAA_Date__c == NULL || tempInt < 2016){
            	CRMMapValues[0] = CRMMapValues[0] + ';;New management forms are required';
            }
            if (household.Alert_Message__c != NULL){
                CRMMapValues[0] = CRMMapValues[0] + ';;Account Alert: ' + household.Alert_Message__c;
            }
            /*
            if (household.Portal_Status__c == 'No response' || household.Portal_Status__c == 'Opt-Out'){
                CRMMapValues[0] = CRMMapValues[0] + ';;Portal response is: ' + household.Portal_Status__c;
            } */
            if (taskToNote.size() > 0){
                for (Integer a = 0; a < taskToNote.size(); a++){
                    CRMMapValues[0] = CRMMapValues[0] + ';;Open Task: ' + taskToNote[a].Subject;
                }
            }
            if (tradeToNote.size() > 0){
                for (Integer a = 0; a < tradeToNote.size(); a++){
                    CRMMapValues[0] = CRMMapValues[0] + ';;Open Trade: ' + tradeToNote[a].Subject;
                }
            }
            if (ACPErrors.size()>0){
            	CRMMapValues[0] = CRMMapValues[0] + ';;ACP Account Balance needs to be over $1,000 and is currently only ' + String.valueOf(ACPErrors[0].FinServ__Balance__c);
            }
            if (BAAErrors.size() > 0){
                for (Integer a = 0; a < BAAErrors.size(); a++){
                    CRMMapValues[0] = CRMMapValues[0] + ';;Outside Account Login Issues: ' + BAAErrors[a].Error_Message__c + '\nWebsite: ' + BAAErrors[a].Website__c
                        + '\nUsername: ' + BAAErrors[a].Login__c + '\nPassword: ' + BAAErrors[a].Password__c;
                }
            }
            CRMMapValues[0] = CRMMapValues[0].removeStart(';;');
        }

        if (CRMMapKeys.size() != CRMMapValues.size()){
            pageErrors = True;
            system.debug('There are a different number of notes than note sections');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are a different number of notes than note sections'));
        } else {
            for (Integer a=0; a<CRMMapKeys.size(); a++){
                noteWrapper objNoteWrapper = new noteWrapper(noteCount, CRMMapKeys[a], CRMMapValues[a]);
                lstNotes.add(objNoteWrapper);
                if (assignedList != NULL){
                    for (Boolean y : assignedList[a]){
                    	lstNotes[a].assignedToClient.add(y);
                    }
                }
                noteCount = noteCount + 1;
            }
        }       

        for (Integer n = 0; n<noteCount; n++){
            lstCount.add(n);
        }
        
        taskToCreate = new List<Task>();
        taskToNote = new List<Task>();
        tradeToCreate = new List<Case>();
        processToCreate = new List<FSTR__Business_Process__c>();
    }

    public class InnerClass {      
        public Integer recCount {get; set;}
        public Task myTaskVar {get; set;}
        public String myTaskVarType {get; set;}
        public Case myTradeVar {get; set;}
        public FSTR__Business_Process__c myBPVar {get; set;}
	    public Boolean fromAccDesc {get; set;}
    	public Boolean toAccDesc {get; set;}
        public String charityType{ get; set;}
        
        public InnerClass(Integer intCount)
        {
            recCount = intCount;
            myTaskVar = new Task();
            myTradeVar = new Case(RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Trade').getRecordTypeId());
            myBPVar = new FSTR__Business_Process__c();
            myTaskVarType = 'Task';
            fromAccDesc = False;
            toAccDesc = False;
            charityType = '';
        }
    }
    
    public class NoteWrapper {
        public Integer recCount {get; set;}
        public String noteContent {get; set;}
        public String noteContentCopy {get; set;}
        public String keyContent {get; set;}
        public List<String> parsedNotes {get; set;}
        public List<Integer> parsedNotesCount {get; set;}
        public String mindMapSection {get; set;}
        public String noteClassification {get; set;}
        public List<String> paddingAmount {get; set;}
        public List<String> numbering {get; set;}
        public List<Boolean> assignedToClient {get; set;}
        public List<Integer> taskLocation {get; set;}
        
        public NoteWrapper(Integer intCount, String myKeys, String myNotes)
        {
            recCount = intCount;
            noteContent = myNotes;
            noteContentCopy = myNotes;
            keyContent = myKeys;
            parsedNotes = new List<String>();
            parsedNotesCount = new List<Integer>();
            paddingAmount = new List<String>();
            numbering = new List<String>();
            assignedToClient = new List<Boolean>();
            taskLocation = new List<Integer>();
            
            Integer i = 0;
            String alpha = 'abcdefghijklmnopqrstuvwxyz';
            mindMapSection = '';
            noteClassification = '';
            String tempString = '';
            
            while (noteContentCopy != null && i < 200) {
                paddingAmount.add('22');
                assignedToClient.add(False);
                taskLocation.add(0);
                while (noteContentCopy.startsWith(';;')){
                    paddingAmount[i] = String.valueOf((Integer.valueOf(paddingAmount[i]) + 28));
                    noteContentCopy = noteContentCopy.removeStart(';;');
                }
                
                if (noteContentCopy.contains(';;')){
                	parsedNotes.add(noteContentCopy.left(noteContentCopy.indexOf(';;')));
                    noteContentCopy = noteContentCopy.removeStart(parsedNotes[i]);
                    noteContentCopy = noteContentCopy.removeStart(';;');
                } else {
                    parsedNotes.add(noteContentCopy);
                    noteContentCopy = null;
                }
                i++;
            }
            List<Integer> numberingList = new List<Integer>();
            Integer largestIndent = 0;
            for (Integer h = 0; h < parsedNotes.size(); h++){
                if (largestIndent < ((Integer.valueOf(paddingAmount[h])-22)/28)){
                    largestIndent = ((Integer.valueOf(paddingAmount[h])-22)/28);
                }
            }
            largestIndent++;
            if (largestIndent < parsedNotes.size()){
                largestIndent = parsedNotes.size();
            }
            for (Integer i2 = 0; i2 < largestIndent; i2++){
                numberingList.add(0);
            }
            for (Integer j = 0; j < largestIndent; j++){
                numberingList.add(0);
            }
            for (Integer k = 0; k < parsedNotes.size(); k++){
                Integer currentIndentIndex = (Integer.valueOf(paddingAmount[k]) - 22)/28;
                if (Math.mod(currentIndentIndex, 2) == 0 || currentIndentIndex == 0){
                    numbering.add((String.valueOf(numberingList[currentIndentIndex]+1) + '. '));
                } else if (Math.mod((currentIndentIndex - 1), 4) == 0 || currentIndentIndex == 1){
                    numbering.add((alpha.substring(numberingList[currentIndentIndex], numberingList[currentIndentIndex]+1) + '. '));
                } else {
                    numbering.add((alpha.toUpperCase().substring(numberingList[currentIndentIndex], numberingList[currentIndentIndex]+1) + '. '));
                }
                numberingList[currentIndentIndex] = numberingList[currentIndentIndex] + 1;
                currentIndentIndex++;
                for (Integer j = currentIndentIndex; j < parsedNotes.size(); j++){
                    numberingList[j] = 0;
                }
            }

            for (Integer i2 = 0; i2 < parsedNotes.size(); i2++){
            	parsedNotesCount.add(i2);
            }
        }
    }
    
    public PageReference resetNotes(){
        household.Meeting_Map_Keys__c = NULL;
        household.Meeting_Map_Values__c = NULL;
        update household;
        ref = new pageReference('/apex/MeetingSummary?id=' + householdId);
        ref.setRedirect(true);
        return ref;
    }
    
    public void categoryRenderer()
    {
     	renderTask = False;
        renderTrade = False;
        renderMoneyMove = False;
    	renderCharit = False;
        renderContrib = False;
        
        activeCategories.clear();

        for (innerClass o : lstInner){
            activeCategories.add(o.myTaskVarType);
        }

        if (!activeCategories.isEmpty()){
            if (activeCategories.contains('Task') || activeCategories.contains('Admin Task') || activeCategories.contains('Tax Task')){
                renderTask = True;
            }
            if (activeCategories.contains('Trade')){
             	renderTrade = True;   
            }
            if (activeCategories.contains('Money Movement')){
             	renderMoneyMove = True;   
            }
            if (activeCategories.contains('Charitable Contribution')){
             	renderCharit = True;   
            }
            /*if (activeCategories.contains('IRA Contribution or Conversion')){
             	renderContrib = True;   
            }*/
        }
    }
    
    public void addTask()
    {  
        taskCount = taskCount+1;
        innerClass objInnerClass = new innerClass(taskCount);
        lstInner.add(objInnerClass);
        categoryRenderer();
    }
    
    public void addNote()
    {  
        lstNotes[selectedNoteIndex].parsedNotes.add('');
        lstNotes[selectedNoteIndex].paddingAmount.add('22');
        lstNotes[selectedNoteIndex].assignedToClient.add(False);
        lstNotes[selectedNoteIndex].taskLocation.add(0);
        alreadySaved = 0;
        RecalcNotes(selectedNoteIndex);
    }
    
    public void enterAddNote()
    {
        Integer noteVar = Integer.valueOf(draggedSection.left(Integer.valueOf(draggedSection.indexOf('Drag'))-2));
        Integer noteRowVar = Integer.valueOf(draggedSection.right(draggedSection.length() - (Integer.valueOf(draggedSection.indexOf('Drag'))+4)));
        Integer pad = Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]);
    	
        if ((noteRowVar + 1) == lstNotes[noteVar].paddingAmount.size()){
            lstNotes[noteVar].parsedNotes.add('');
            lstNotes[noteVar].paddingAmount.add(String.valueOf(pad));
            lstNotes[noteVar].assignedToClient.add(False);
            lstNotes[noteVar].taskLocation.add(0);
        } else {
            lstNotes[noteVar].parsedNotes.add((noteRowVar + 1), '');
            lstNotes[noteVar].paddingAmount.add((noteRowVar + 1), String.valueOf(pad));
            lstNotes[noteVar].assignedToClient.add((noteRowVar + 1), False);
            lstNotes[noteVar].taskLocation.add((noteRowVar + 1), 0);
        }
        alreadySaved = 0;
        RecalcNotes(noteVar);
	}
    
    public void deleteNote(Integer section, Integer note){
        lstNotes[section].paddingAmount.remove(note);
        lstNotes[section].parsedNotes.remove(note);
        lstNotes[section].assignedToClient.remove(note);
        lstNotes[section].taskLocation.remove(note);
        alreadySaved = 0;
    }
    
    public void recalcNotes(Integer section){
        lstNotes[section].parsedNotesCount.clear();
        for (Integer i = 0; i < lstNotes[section].parsedNotes.size(); i++){
            lstNotes[section].parsedNotesCount.add(i);
        }
    }
    
    public void addNoteSection()
    {  
        noteWrapper objNoteWrapper = new noteWrapper(noteCount, '', '');
        lstNotes.add(objNoteWrapper);
        noteCount = noteCount+1;
        
        lstCount.clear();
        for (Integer n = 0; n<noteCount; n++){
            lstCount.add(n);
        }
        alreadySaved = 0;
    }
    
    public void DelTask() {
        lstInner.remove(selectedRowIndex-1);
        for (innerClass o : lstInner){
            if (o.recCount > selectedRowIndex){
              o.recCount = o.recCount - 1;  
            }
        }
        taskCount = taskCount - 1;
        categoryRenderer();
    }
        
    public void undentNote() {
        Integer noteRowVar = selectedRowIndex;
        Integer noteVar = selectedNoteIndex;
        Integer countIndent = Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]);
        
        //Deletes the note and all child notes if it is already fully undented
        if (lstNotes[noteVar].paddingAmount[noteRowVar] == '22'){
            deleteNote(noteVar, noteRowVar);
            if (noteRowVar != lstNotes[noteVar].paddingAmount.size()){
                while (Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]) > countIndent){
                    deleteNote(noteVar, noteRowVar);
					if (noteRowVar == lstNotes[noteVar].paddingAmount.size()){
                        break;
                    }
                }
            }
            recalcNotes(noteVar);
        } else {
            //If space to spare, undent this note and child notes
            lstNotes[noteVar].paddingAmount[noteRowVar] = String.valueOf(Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]) - 28);
            noteRowVar++;
            if (noteRowVar != lstNotes[noteVar].paddingAmount.size()){
                while (Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]) > countIndent){
                    lstNotes[noteVar].paddingAmount[noteRowVar] = String.valueOf(Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]) - 28);
                    noteRowVar++;
                    if (noteRowVar == lstNotes[noteVar].paddingAmount.size()){
                        break;
                    }
            	}
            }
        }
        alreadySaved = 0;
    }
    
    //Deletes if no text, adds a subcategory if there is text
    public void doubleClickNote() {
        Integer noteRowVar = selectedRowIndex;
        Integer noteVar = selectedNoteIndex;
        Integer i = 0;
        //Deletes ONLY this note if the note field is blank. All child notes are left untouched
        if (String.isBlank(lstNotes[noteVar].parsedNotes[noteRowVar])){
            deleteNote(noteVar, noteRowVar);
        } else {
            Integer pad = Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar]) + 28;
            //Adds a subcategory if the note field IS NOT blank. All child notes are moved down, but left untouched
            if (lstNotes[noteVar].paddingAmount.size() != (noteRowVar + 1)){
                while (noteRowVar < lstNotes[noteVar].paddingAmount.size() && (pad <= Integer.valueOf(lstNotes[noteVar].paddingAmount[noteRowVar+1]))){
                    noteRowVar++;
                    if ((noteRowVar + 1) == lstNotes[noteVar].paddingAmount.size()){
                        lstNotes[noteVar].parsedNotes.add('');
                        lstNotes[noteVar].paddingAmount.add(String.valueOf(pad));
                        lstNotes[noteVar].assignedToClient.add(False);
                        lstNotes[noteVar].taskLocation.add(0);
                        i = 1;
                        break;
                    }
                }
                if (i==0){
                    lstNotes[noteVar].parsedNotes.add((noteRowVar + 1), '');
                    lstNotes[noteVar].paddingAmount.add((noteRowVar + 1), String.valueOf(pad));
                    lstNotes[noteVar].assignedToClient.add((noteRowVar + 1), False);
                    lstNotes[noteVar].taskLocation.add((noteRowVar + 1), 0);
                }
            } else {
            	lstNotes[noteVar].parsedNotes.add('');
                lstNotes[noteVar].paddingAmount.add(String.valueOf(pad));
                lstNotes[noteVar].assignedToClient.add(False);
                lstNotes[noteVar].taskLocation.add(0);
            }
        }
        RecalcNotes(noteVar);
        alreadySaved = 0;
    }
    
    public void setDateVal() {
        try{
            Date myDate = Date.parse(dateVal);
            Datetime dt = datetime.newInstance(myDate.year(), myDate.month(),myDate.day());
            dateVal = dt.format('MMMM d, yyyy');
        } catch (Exception e){
            Datetime dt = datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
            dateVal = dt.format('MMMM d, yyyy');
        }
    }
	
    public void moveNote() {
        //if the user dropped in a droppable object (the dragged section is always draggable or would not contain 'Drag' in the id)
        if (droppedSection.contains('Drag')){
            if (draggedSection.contains('thDrag')){
                Integer startSection = Integer.valueOf(draggedSection.removeEnd('thDrag'));
                Integer endSection = Integer.valueOf(droppedSection.left(Integer.valueOf(droppedSection.indexOf('Drag'))-2)) + 1; //thDrag and tdDrag
                if (lstNotes.size() != endSection){
	                lstNotes.add(endSection, lstNotes[startSection]);
                } else {
                    lstNotes.add(lstNotes[startSection]);
                }
                if (startSection >= endSection){
                    startSection++;
                }
                lstNotes.remove(startSection);
            }
            if (draggedSection.contains('tdDrag')){
                Integer startSection = Integer.valueOf(draggedSection.left(Integer.valueOf(draggedSection.indexOf('Drag'))-2));
                Integer startNote = Integer.valueOf(draggedSection.right(draggedSection.length() - (Integer.valueOf(draggedSection.indexOf('Drag'))+4)));
                Integer endSection = Integer.valueOf(droppedSection.left(Integer.valueOf(droppedSection.indexOf('Drag'))-2));
                Integer endNote;
                //move the note below the note it is dropped on if it is dropped on a note else to the first position if dropped on a section header
                if (droppedSection.contains('tdDrag')){
                    endNote = Integer.valueOf(droppedSection.right((droppedSection.length()) - (Integer.valueOf(droppedSection.indexOf('Drag'))+4))) + 1;
                } else if (droppedSection.contains('thDrag')){
                    endNote = 0;
                }
                if (lstNotes[endSection].parsedNotes.size() > endNote){ //if (lstNotes[endSection].parsedNotes.size() > endNote+1){ Was here initially, 
                    //but resulted in moving the moved note to the bottom instead of second to bottom
                    lstNotes[endSection].parsedNotes.add(endNote, lstNotes[startSection].parsedNotes[startNote]);
                    lstNotes[endSection].paddingAmount.add(endNote, lstNotes[startSection].paddingAmount[startNote]);
                    lstNotes[endSection].assignedToClient.add(endNote, lstNotes[startSection].assignedToClient[startNote]);
                    lstNotes[endSection].taskLocation.add(endNote, lstNotes[startSection].taskLocation[startNote]);
                } else {
					lstNotes[endSection].parsedNotes.add(lstNotes[startSection].parsedNotes[startNote]);
                    lstNotes[endSection].paddingAmount.add(lstNotes[startSection].paddingAmount[startNote]);
                    lstNotes[endSection].assignedToClient.add(lstNotes[startSection].assignedToClient[startNote]);
                    lstNotes[endSection].taskLocation.add(lstNotes[startSection].taskLocation[startNote]);                    
                }
                if (startSection == endSection && startNote >= endNote){
                    startNote++;
                }
                lstNotes[startSection].parsedNotes.remove(startNote);
                lstNotes[startSection].paddingAmount.remove(startNote);
                lstNotes[startSection].assignedToClient.remove(startNote);
                lstNotes[startSection].taskLocation.remove(startNote);  
                recalcNotes(startSection);
            	recalcNotes(endSection);
            }
            alreadySaved = 0;
        }
    }
    
    public void indentNote() {
    	lstNotes[selectedNoteIndex].paddingAmount[selectedRowIndex] = String.valueOf(Integer.valueOf(lstNotes[selectedNoteIndex].paddingAmount[selectedRowIndex]) + 28);
        alreadySaved = 0;
    }
    
    public void tabIndentNote() {
        selectedNoteIndex = Integer.valueOf(draggedSection.left(Integer.valueOf(draggedSection.indexOf('Drag'))-2));
        selectedRowIndex = Integer.valueOf(draggedSection.right(draggedSection.length() - (Integer.valueOf(draggedSection.indexOf('Drag'))+4)));
    	lstNotes[selectedNoteIndex].paddingAmount[selectedRowIndex] = String.valueOf(Integer.valueOf(lstNotes[selectedNoteIndex].paddingAmount[selectedRowIndex]) + 28);
        alreadySaved = 0;
    }
    
    public void save() {
        /*
        if (householdId != ApexPages.currentPage().getParameters().get('id')){
            pageErrors = true;
            system.debug('Current ID variable does not match the page ID variable. The user must have opened a second meeting summary during use');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The household of this meeting summary is no longer the active household. This is caused by opening a second meeting summary before finishing the first.'));
        } else{
        */
            if (!test.isRunningTest() && authChecked == false){
                if (!NetDocumentsService.hasUpdatedAccessToken(true,settings)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'There is no current access to NetDocuments. Please reauthenticate below if you want to save automatically to NetDocuments.'));
                    authRequired = true;
                } else {
                    authChecked = true;
                    authRequired = false;
                }
            } else {
                authRequired = false;
            }
            crmMapKeys.clear();
            crmMapValues.clear();
            for (Integer a=0; a<lstNotes.size(); a++){
                tempBool = False;
                for (Integer blanks = 0; blanks < lstNotes[a].parsedNotes.size(); blanks++){
                    if (lstNotes[a].parsedNotes[blanks] != '' || lstNotes[a].taskLocation[blanks] != 0){
                        tempBool = True;
                        break;
                    }
                }
                if (lstNotes[a].keyContent != '' && tempBool == True){
                    crmMapKeys.add(lstNotes[a].keyContent);
                    lstNotes[a].numbering.clear();
                    stringInnerNotes = '';
                    List<Integer> numberingList = new List<Integer>();
                    Integer largestIndent = 0;
                    for (Integer i = 0; i < lstNotes[a].parsedNotes.size(); i++){
                        if (largestIndent < ((Integer.valueOf(lstNotes[a].paddingAmount[i])-22)/28)){
                            largestIndent = ((Integer.valueOf(lstNotes[a].paddingAmount[i])-22)/28);
                        }
                    }
                    largestIndent++;
                    if (largestIndent < lstNotes[a].parsedNotes.size()){
                        largestIndent = lstNotes[a].parsedNotes.size();
                    }
                    for (Integer i = 0; i < largestIndent; i++){
                        numberingList.add(0);
                    }
                    System.debug(numberingList);
                    String alpha = 'abcdefghijklmnopqrstuvwxyz';
                    for(Integer b = 0; b < lstNotes[a].parsedNotes.size(); b++){
                        if (lstNotes[a].parsedNotes[b] != '' || lstNotes[a].taskLocation[b] != 0) {
                            if (lstNotes[a].parsedNotes[b] != '' && lstNotes[a].taskLocation[b] == 0){ //added the && when moving the page function to a separate button. May need to remove and find other solution if errors occur
                                stringInnerNotes = stringInnerNotes + ';;'.repeat((Integer.valueOf(lstNotes[a].paddingAmount[b])-22)/28) + ';;';
                                stringInnerNotes = stringInnerNotes + lstNotes[a].parsedNotes[b];
                            } else {
                                for (Integer z = 0; z < lstInner.size(); z++){
                                    if (lstInner[z].recCount == lstNotes[a].taskLocation[b]){
                                        if (lstInner[z].myTaskVar.Subject <> '' && lstInner[z].myTaskVar.Subject <> NULL) {
	                                        lstNotes[a].parsedNotes[b] = lstInner[z].myTaskVar.Subject;
                                        } else {
                                            //lstNotes[a].parsedNotes[b] = 'ERROR';
                                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please add a subject to the task section and it will flow through to the notes.'));
                                        }
                                    }
                                }
                            }
                            Integer currentIndentIndex = (Integer.valueOf(lstNotes[a].paddingAmount[b]) - 22)/28;
                            if (Math.mod(currentIndentIndex, 2) == 0 || currentIndentIndex == 0){
                                lstNotes[a].numbering.add((String.valueOf(numberingList[currentIndentIndex]+1) + '. '));
                            } else if (Math.mod((currentIndentIndex - 1), 4) == 0 || currentIndentIndex == 1){
                                lstNotes[a].numbering.add((alpha.substring(numberingList[currentIndentIndex], numberingList[currentIndentIndex]+1) + '. '));
                            } else {
                                lstNotes[a].numbering.add((alpha.toUpperCase().substring(numberingList[currentIndentIndex], numberingList[currentIndentIndex]+1) + '. '));
                            }
                            numberingList[currentIndentIndex] = numberingList[currentIndentIndex] + 1;
                            currentIndentIndex++;
                            for (Integer i = currentIndentIndex; i < lstNotes[a].parsedNotes.size(); i++){
                                numberingList[i] = 0;
                            }
                        } else {
                            deleteNote(a, b);
                            recalcNotes(a);
                            b--;
                        }
                    }
                    stringInnerNotes = stringInnerNotes.removeStart(';;');
                    CRMMapValues.add(stringInnerNotes);
                } else {
                    if (lstNotes[a].keyContent == 'Action Steps' && currentUser == 'Matthew Rich'){
                        //do nothing
                    } else {
                        lstNotes.remove(a);
                        noteCount--;
                        a--;
                        lstCount.clear();
                        for (Integer n = 0; n<noteCount; n++){
                            lstCount.add(n);
                        }
                    }
                }
            }
        
        	CRMMapKeysDup = CRMMapKeys;
        	CRMMapValuesDup = CRMMapValues;

            for (Integer b = 0; b < CRMMapKeysDup.size(); b++){
                if (CRMMapKeysDup[b] == 'Team Requests' || CRMMapKeysDup[b] == 'Basics'){
                    CRMMapKeysDup.remove(b);
                    CRMMapValuesDup.remove(b);
                    b--;
                }
            }

            if (household.Meeting_Map_Keys__c <> JSON.serializePretty(CRMMapKeysDup) || household.Meeting_Map_Values__c <> JSON.serializePretty(CRMMapValuesDup)){
            	household.Meeting_Map_Keys__c = JSON.serializePretty(CRMMapKeysDup);
	            household.Meeting_Map_Values__c = JSON.serializePretty(CRMMapValuesDup);
                update household;
            }
        
        	alreadySaved = 1;
            for (Apexpages.Message msg : ApexPages.getMessages()){
                if (msg.getSeverity() == ApexPages.Severity.ERROR){
                    alreadySaved = 0;
                    system.debug(msg.getSummary());
                }
            }
        //}
    }
    
    public pageReference page(){
        saveErrors = False;
        if (lstInner.size() > 0){
            for (Integer a = 0; a < lstInner.size(); a++){
                if (lstInner[a].myTaskVar.Subject == NULL){
                    lstInner.remove(a);
                } else {
                    if ((lstInner[a].myTaskVarType == 'Task' || lstInner[a].myTaskVarType == 'Admin Task' || lstInner[a].myTaskVarType == 'Tax Task') && saveErrors == False){
                        try{
                            Task ta = new Task();
                            ta.Subject = lstInner[a].myTaskVar.Subject;
                            ta.Status = 'Open';
                            ta.Description = lstInner[a].myTaskVar.Description;
                            ta.Refers_To_Name__c = household.Name;
                            ta.Refers_To_Id__c = household.Id;
                            ta.WhatId = household.Id;
                            ta.ActivityDate = lstInner[a].myTaskVar.ActivityDate;
                            ta.Start_Date__c = lstInner[a].myTaskVar.ActivityDate.addDays(-7);
                            ta.isreminderset = true;
                            ta.reminderdatetime = lstInner[a].myTaskVar.ActivityDate.addDays(-7);
                            taskToCreate.add(ta);
                            if (lstInner[a].myTaskVarType == 'Task'){
                                if (lstInner[a].myTaskVar.OwnerId == '005i0000000iMb0AAE'){
                                    saveErrors = True;
                                    system.debug('Please do not assign tasks to CRM Admin. Use the admin task type instead.');
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please do not assign tasks to CRM Admin. Use the admin task type instead.'));
                                	tradeToCreate.clear();
                                    taskToCreate.clear();
                                    processToCreate.clear();
                                } else {
	                                ta.OwnerId = lstInner[a].myTaskVar.OwnerId;
                                }
                            } else if (lstInner[a].myTaskVarType == 'Admin Task'){
                                ta.Queue__c = 'Admin';
                                //ta.OwnerId = '005i0000000h0uGAAQ'; //ID for In Queue
                            } else if (lstInner[a].myTaskVarType == 'Tax Task') {
                                ta.Queue__c = 'Tax';
                                //ta.OwnerId = '005i0000000h0uGAAQ'; //ID for In Queue
                            }
                        } catch(Exception eTasks) {
                            saveErrors = True;
                            taskToCreate.clear();
                            system.debug('Exception occurred during task creation: ' + eTasks);
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not add the task(s). Please review for accuracy'));
                        }
                    } else if (lstInner[a].myTaskVarType == 'Trade' && saveErrors == False){
                        try{
                        	Case tr = new Case(RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Trade').getRecordTypeId());
                            tr.Subject = lstInner[a].myTaskVar.Subject;
                            tr.Description = lstInner[a].myTaskVar.Description;
                            //tr.OwnerId = '005i0000000h0uGAAQ'; //ID for In Queue.
                            tr.FinServ__FinancialAccount__c = lstInner[a].myBPVar.From_Account__c;
                            tr.AccountId = household.Id; //household
                            tr.Amount__c = lstInner[a].myTradeVar.Amount__c;
                            tr.Origin = 'In Person';
                            tr.Status= 'Open';
                            tr.FSTR__Due_Date__c = lstInner[a].myTaskVar.ActivityDate;
                            tradeToCreate.add(tr);
                        } catch(Exception eTrades) {
                            saveErrors = True;
                            tradeToCreate.clear();
                            taskToCreate.clear();
                            system.debug('Exception occurred during trade creation: ' + eTrades);
                            ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Could not add the trade(s). Please review for accuracy'));
                        }
                    } else if (lstInner[a].myTaskVarType == 'Money Movement' && saveErrors == False){
                        try{
                            FSTR__Business_Process__c bp = new FSTR__Business_Process__c();
                            bp.FSTR__Subject__c = lstInner[a].myTaskVar.Subject;
                            bp.Notes__c = lstInner[a].myTaskVar.Description;
                            bp.Request_Method__c = 'In Person';
                            if (lstInner[a].myBPVar.From_Account__c != NULL){
                                bp.From_Account__c = lstInner[a].myBPVar.From_Account__c;
                            } else {
                                bp.From_Account_Description__c = lstInner[a].myBPVar.From_Account_Description__c;
                            }
                            if (lstInner[a].myBPVar.To_Account__c != NULL){
                                bp.To_Account__c = lstInner[a].myBPVar.To_Account__c;
                            } else {
                                bp.To_Account_Description__c = lstInner[a].myBPVar.To_Account_Description__c;
                            }
                            bp.MMove_Trades_Pending__c = lstInner[a].myBPVar.MMove_Trades_Pending__c;
                            bp.Amount__c = lstInner[a].myTradeVar.Amount__c;
                            bp.FSTR__Due_Date__c = lstInner[a].myTaskVar.ActivityDate;
                            //bp.RecordTypeId = '012i0000000X7heAAC'; //ID for Money Movement types
                            bp.OwnerId = UserInfo.getUserId();
                            bp.FSTR__Status__c = 'Open';
                            bp.FSTR__Client__c = household.FinServ__PrimaryContact__c;
                            bp.FSTR__Business_Account__c = household.Id;
                            bp.QCD__c = lstInner[a].myBPVar.QCD__c;
                            bp.Contribution_Year__c = lstInner[a].myBPVar.Contribution_Year__c;
                            bp.Date_for_Review__c = lstInner[a].myBPVar.Date_for_Review__c;
                            bp.Client_is_aware__c = 'Yes';
                            processToCreate.add(bp);
                        } catch(Exception eMMs) {
                            saveErrors = true;
                            tradeToCreate.clear();
                            taskToCreate.clear();
                            processToCreate.clear();
                            system.debug('Exception occurred during money movement creation: ' + eMMs);
                            ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Could not add the money movement(s). Please review for accuracy'));
                        }
                        //add logic to find 2 lists of all required fields and all fields displayed and figure out if the length of all displayed is equal to the length of all displayed after adding all required???
                    } else if (lstInner[a].myTaskVarType == 'Charitable Contribution' && saveErrors == False){
                        try{
                            FSTR__Business_Process__c bp = new FSTR__Business_Process__c();
                            bp.FSTR__Subject__c = lstInner[a].myTaskVar.Subject;
                            bp.Notes__c = lstInner[a].myTaskVar.Description;
                            bp.From_Account__c = lstInner[a].myBPVar.From_Account__c;
                            bp.Amount__c = lstInner[a].myTradeVar.Amount__c;
                            bp.FSTR__Due_Date__c = lstInner[a].myTaskVar.ActivityDate;
                            if (lstInner[a].charityType == 'ACP Charitable Contribution'){
                                //bp.RecordTypeId = '012i0000001O2lCAAS';
                                bp.ACP_Charity_Type__c = 'American Center for Philanthropy';
                                bp.ACP_to_ACP_Account__c = lstInner[a].myBPVar.To_Account__c;
                                bp.ACP_Allocation_Instructions__c = lstInner[a].myBPVar.ACP_Allocation_Instructions__c;
                            } else if (lstInner[a].charityType == 'DAF Charitable Contribution'){
                                //bp.RecordTypeId = '012i0000001O2k6AAC';
                                bp.ACP_Charity_Type__c = 'Schwab Donor Advised Fund';
                                bp.ACP_to_ACP_Account__c = lstInner[a].myBPVar.To_Account__c;
                                bp.ACP_Allocation_Instructions__c = lstInner[a].myBPVar.ACP_Allocation_Instructions__c;
                            } else {
                                //bp.RecordTypeId = '012i0000001O2kBAAS';
                                bp.ACP_Charity_Type__c = 'Other';
                                bp.To_Account_Description__c = lstInner[a].myBPVar.To_Account_Description__c;
                            }
                            bp.OwnerId = UserInfo.getUserId();
                            bp.FSTR__Status__c = 'Open';
                            bp.FSTR__Client__c = household.FinServ__PrimaryContact__c;
                            bp.FSTR__Business_Account__c = household.Id;
                            bp.Client_is_aware__c = 'Yes';
                            bp.ACP_Form_Delivery_to_Client__c = lstInner[a].myBPVar.ACP_Form_Delivery_to_Client__c;
                            bp.ACP_Lot_Date__c = 'Lowest Cost Shares';
                            processToCreate.add(bp);
                        } catch(Exception eCharit) {
                            saveErrors = True;
                            tradeToCreate.clear();
                            taskToCreate.clear();
                            processToCreate.clear();
                            system.debug('Exception occurred during charitable contribution creation: ' + eCharit);
                            ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Could not add the charitable contribution(s). Please review for accuracy'));
                        }
                    } 
                }
            }
            Savepoint sp = Database.setSavepoint();
            try{
                if(!taskToCreate.isEmpty() && saveErrors == False){
                    System.debug(taskToCreate);
                    insert taskToCreate;
                }
                if(!tradeToCreate.isEmpty() && saveErrors == False){
	                insert tradeToCreate;
                }
                if(!processToCreate.isEmpty() && saveErrors == False){
	                insert processToCreate;
                }
            } catch (Exception eInsert){
                if (taskToCreate != NULL && taskToCreate.size() <> 0){
                    taskToCreate.clear();
                }
                if (tradeToCreate != NULL && tradeToCreate.size() <> 0){
                    tradeToCreate.clear();
                }
                if (processToCreate != NULL && processToCreate.size() <> 0){
                    processToCreate.clear();
                }
                saveErrors = True;
                system.debug(eInsert);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One of the tasks/trades/BPs contained an error. Please review for accuracy and try again'));
            	Database.rollback( sp );
            }
            
        }
        
        //Hopefully prevents a save and rerender if there are errors. Prevents loss of entered data or trades being entered before the PDF can be output
        if (saveErrors == False){
            assignedList = new List<List<Boolean>>();
            for (Integer a=0; a<lstNotes.size(); a++){
                assignedList.add(lstNotes[a].assignedToClient);
            }
            ref = new PageReference('/apex/MeetingSummaryPDF?id=' + householdId);
            Blob contentData;
            if (Test.isRunningTest()){
                contentData = Blob.valueOf('pdfBody');
            } else {
                try{
                    contentData = ref.getContent();
                    pageRefPDF = 'data:application/pdf;base64,' + EncodingUtil.base64Encode(contentData);
                } catch (VisualforceException e){
                    contentData = Blob.valueOf('Error');
                    System.debug('Exception when converting to a PDF: ' + e);
                }
            }
    
            if (portalSave == True || saveToNetDocs == True){
                String name = String.valueOf(dateVal) + ' Meeting Summary';
                ContentVersion cv = new ContentVersion();
                cv.Title = name;
                cv.VersionData = contentData;
                cv.PathOnClient = name + '.pdf';
                insert cv;
                if (saveToNetDocs == True){
                    //ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
                    //NetDocumentsBatch ndb = new NetDocumentsBatch(cd.Id,String.valueOf(UserInfo.getUserId()),householdId,'');
                    //Database.executeBatch(ndb,1);
                }
                    
                if (portalSave == True){
                    if (docGroups.size() == 0){
                        Document_Group__C docGroup = new Document_Group__c();
                        docGroup.Household__c = householdId;
                        docGroup.Name = 'Other Shared Documents';
                        docGroup.Type__c = 'Other Shared Documents';
                        docGroups.add(docGroup);
                        insert docGroups;
                    }
                    
                    FeedItem fi = new FeedItem();
                    fi.ParentId = docGroups[0].Id;
                    //fi.Visibility = 'AllUsers';
                    fi.Title = name;
                    fi.Body = 'Meeting Summary';
                    insert fi;
                    
                    FeedAttachment fa = new FeedAttachment();
                    fa.FeedEntityId = fi.Id;
                    fa.RecordId = cv.Id;
                    fa.Title = name;
                    fa.Type = 'Content';
                    insert fa;
                }
            }
    
            if (wordSave == 'pdf'){
                return ref;
            } else {
                alreadySaved = 0;
                return new PageReference('/apex/MeetingSummaryWord?id=' + householdId);
            }
            
        } else {
            return null;
        }
    }
    
    public PageReference redirect(){
        Datetime recentCreation = Datetime.now().addSeconds(-300);
        tasksCreated = [SELECT Id, Subject, Description, OwnerId, ActivityDate FROM Task WHERE AccountId = :householdId AND CreatedById = :UserInfo.getUserId() AND CreatedDate > :recentCreation];
        processCreated = [SELECT Id, FSTR__Subject__c, Notes__c, OwnerId FROM FSTR__Business_Process__c WHERE FSTR__Business_Account__c = :householdId AND CreatedById = :UserInfo.getUserId() AND CreatedDate > :recentCreation];
        tradeCreated = [SELECT Id, Subject, Description, FSTR__Due_Date__c, Amount__c FROM Case  WHERE AccountId = :householdId AND CreatedById = :UserInfo.getUserId() AND CreatedDate > :recentCreation AND RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Trade').getRecordTypeId()];
        return new PageReference('/apex/MeetingSummaryTasks?id=' + householdId);
    }

}