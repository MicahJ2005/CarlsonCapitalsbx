/**
 * @description       : 
 * @author            : Michael Lloyd (Demand Chain)
 * @group             : 
 * @last modified on  : 12-22-2023
 * @last modified by  : Michael Lloyd (Demand Chain)
**/
public with sharing class NetWorthCtrl {
    // household, contact information
    public Account household {get;set;}
    public Account deleteHousehold {get; set;}
    public String primaryName {get;private set;}
    public String spouseName {get;private set;}     
    // misc.
    public Boolean disableGeneratePDFButton {
        get {return buttonClicked;}
    }
    public Boolean maskAccountNumbers {get; set;}
    public Boolean uploadToBox {get; set;}
    public String asOfDate {get;private set;}   
    public String objId {get;private set;}
    public Boolean pageErrors {get;private set;}
    private boolean buttonClicked = false;

    // Estate Summary - sections
    public List<EstateSummaryGrid> finalEstateLayout {get;private set;}
    // Net Worth - sections
    public Map<String,List<ReportAsset>> liquidAssets {get;private set;}
    public Map<String,List<ReportAsset>> otherAssets {get;private set;}
    public Map<String,List<ReportAsset>> outsideAssets {get;private set;}
    public Map<String,List<ReportAsset>> deathBenefits {get;private set;}

    public List<String> categorySortMap {get;private set;}
    // total rows
    public Map<String,Double> totalRowMap {get;private set;}
    public String totalRowMapString {get;private set;}
    //TODO edit records popups
    public FinServ__FinancialAccount__c editFA {get; set;} // Financial_Account__c editFA {get;set;}
    public FinServ__AssetsAndLiabilities__c editAsset {get; set;} 
    public double tempVal {get; set;}
    public InsurancePolicy editIns {get; set;} // Insurance_Policy__c editIns {get;set;}
    public double tempVal2 {get; set;}

    public String editObjectId {get;set;}
    public String liquidAssetCategoryString {get;set;}
    public String otherAssetsCategoryString {get;set;}
    public String outsideAssetsCategoryString {get;set;}
    // PRIVATE 
    public List<FinServ__FinancialAccount__c> accounts {get;private set;} // List<Financial_Account__c> accounts {get;private set;}
    public List<FinServ__AssetsAndLiabilities__c> assets {get;private set;} 
    public List<InsurancePolicy> insurance {get;private set;} //List<Insurance_Policy__c> insurance {get;private set;}
    public List<Beneficiary__c> beneficiaries {get;private set;} // List<FPT__fpt_Beneficiary__c> beneficiaries {get;private set;}
    private List<InsurancePolicy> insuranceDeathBenefits; // List<Insurance_Policy__c> insuranceDeathBenefits;

    // record type reference
    public Map<String,String> rtMap {get;private set;}
    public Map<String,String> assetRTMap {get;private set;}
    public Map<String,String> insRTMap {get;private set;}
    private Map<String,List<Beneficiary__c>> bMap; // Map<String,List<FPT__fpt_Beneficiary__c>> bMap;//for tmp    
    private Map<String,Beneficiary__c> primaryBeneficiaryMap;     //Map<String,FPT__fpt_Beneficiary__c> primaryBeneficiaryMap;    

    // notes (for insurance, on and off BS - i.e. cash balance, death benefit)
    private Map<String,String> bfNoteMap;
    private Map<String,String> onInsNoteMap;
    private Map<String,String> offInsNoteMap;    

    // for queries
    private String pipelineId;

    public Account householdRebalancing {get; set;}


    public NetWorthCtrl() {
        
        objId = ApexPages.currentPage().getParameters().get('id');      
        initialize();
    }

    private void initialize() {
        initializeParams(); 
        try {
            //System.debug('initializing...'+objId);
            //System.debug('editFA...'+editFA);
            //System.debug('editIns...'+editIns);
            // TODO Figure out this if statement
            //if (objId!=null && [Select count() From Financial_Account__c Where Household_Business__c=:objId and Account_Owner_1__c=null and Account_Closed__c=false]==0) {
            if (objId != null) { // Temp
                    // map of record types for FAs and insurance policies
                    assembleRecordTypeMaps();

                    // household information
                    queryHHInfo();

                    // query base lists for financial account, insurance, beneficiary records
                    queryRecords();
                    
                    // create lookups for beneficiaries
                    assembleBeneficiaryLookups();

                    // assemble notes according to specs
                    assembleFinAcctNotes();
                    assembleInsuranceNotes();

                    // populate wrapper classes for FA and Insurance information 
                    assembleInsuranceDetails();
                    setDisplayMapsByCategory();

                    // populate Estate Summary page grid using ReportAsset data
                    populateEstateSummaryGrid();

                    System.debug('updated note map...'+bfNoteMap);
                    // TODO estate page
                    //assembleTotalMaps();
            } else {
                pageErrors = true;              
                System.debug('===========> All financial accounts do not have an Owner 1 field set.');              
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'All financial accounts must have the Account Owner 1 field set.'));
            }
        } catch (Exception e) {
            pageErrors = true;
            System.debug('===========> '+e.getMessage()+'; '+e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+'; '+e.getStackTraceString()));
        }       
    }   

    public PageReference captureButtonClick() {
        buttonClicked = true;
        return null;
     }

    public PageReference generatePDF() {
        //instantiate PDF with appropriate params for masking/showing account numbers
        String showAccountNums = maskAccountNumbers ? 'false' : 'true';
        PageReference pr = Page.NetWorthPDF;
        pr.getParameters().put('Id', objId);
        pr.getParameters().put('showAccountNumbers', showAccountNums);
        pr.setRedirect(true);
        //if Upload To Box checkbox is checked, upload to box
        
        String boxError = '';
        
        if (uploadToBox) {
            boxError = uploadToBox(maskAccountNumbers, objId);
        }

        if (!String.isEmpty(boxError)) {
            pageErrors = true;
            System.debug('Box Error: ' + boxError);              
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, boxError));
            return null;
        }
        
        //redirect to PDF
        return pr;
    }

    //@Future(callout=true) 
    public static String uploadToBox(Boolean maskAccountNumbers, Id objId) {
        String boxError = '';
        
        box.ToolKit toolkit = new box.ToolKit();

        String folderId = Test.isRunningTest() ? sendTestBoxCallout('getFolderIdByRecordId').getBody() : toolkit.getFolderIdByRecordId(objId);
        String endpoint = 'https://api.box.com/2.0/folders/' + folderId + '/items';

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(endpoint);
        request.setHeader('content-type', 'application/json');

        HttpResponse response = Test.isRunningTest() ? sendTestBoxCallout('sendRequestForFolderItems') : toolkit.sendRequest(request);

        Map<String, Object> folderItems = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        String subfolderId = '';
        List<Object> entries = (List<Object>)folderItems.get('entries');
        for (Object entryObj : entries) {
            Map<String, Object> entryMap = (Map<String, Object>)entryObj;
            if(entryMap.get('type') == 'folder' && entryMap.get('name') == 'Client Documentation') {
                subfolderId = (String)entryMap.get('id');
            }
        }

        String showAccountNums = maskAccountNumbers ? 'false' : 'true';
        PageReference pr = Page.NetWorthPDF;
        pr.getParameters().put('Id', objId);
        pr.getParameters().put('showAccountNumbers', showAccountNums);
        pr.setRedirect(true);

        String householdNameUnderscores = '';
        if (maskAccountNumbers) {
            String householdName = [SELECT Name From Account WHERE Id = :objId]?.Name;
            householdNameUnderscores = '_' + householdName + '_';
        }

        String fileName = 'Net Worth' + householdNameUnderscores + Datetime.now().format('yyyy-MM-dd hh:mm') + '.pdf';

        Attachment attach = new Attachment();
        Blob b;
        b = Test.isRunningTest() ? blob.valueOf('Unit.Test') : pr.getContent();
        attach.Body = b;
        attach.Name = fileName;
        attach.IsPrivate = false;
        attach.ParentId = objId;
        String fileId = Test.isRunningTest() ? sendTestBoxCallout('createFileFromAttachment').getBody() : toolkit.createFileFromAttachment(attach, null, subfolderId, null);
        
        boxError = toolkit.mostRecentError;         
        
        toolkit.commitChanges();

        return boxError;
    }

    public static HttpResponse sendTestBoxCallout(String endpoint) {
        HttpRequest testReq = new HttpRequest();
        testReq.setEndpoint(endpoint);
        Http http = new Http();
        HttpResponse testResp = http.send(testReq);
        return testResp;
    }

    public PageReference queryEditObj() {
        //System.debug('===========> queryEditObj');
        String itemId = Apexpages.currentPage().getParameters().get('itemId');
        //System.debug('===========> itemId '+itemId);

        editFA = [Select RecordTypeId, Net_Worth_Classification__c, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.FirstName,
                        FinServ__JointOwner__c, FinServ__JointOwner__r.FirstName, FinServ__Ownership__c, FinServ__FinancialAccountType__c, 
                        FinServ__FinancialAccountNumber__c, FinServ__Balance__c, OASP_FSC__Custodian__c, OASP_FSC__Active__c,
                        Include_on_Net_Worth__c, Cost_Basis__c, as_of_date__c, Account_Notes__c, Net_Worth_Account_Display_Name__c, 
                        FinServ__TaxStatus__c, Trust_Administration__c
                    From FinServ__FinancialAccount__c
                    Where Id = :itemId 
                        Limit 1];
        //tempVal saves value prior to save so we can see if the user changed the value. If so, the as of date updates, otherwise it stays the same
        tempVal =  editFa.FinServ__Balance__c;

        return null;                                        
    }

    public PageReference queryEditAssetObj() {
        //System.debug('===========> queryEditObj');
        String itemId = Apexpages.currentPage().getParameters().get('itemId');
        //System.debug('===========> itemId '+itemId);

        editAsset = [SELECT Account_Notes__c, Account_Type__c, FinServ__Amount__c, As_of_Date__c, Name, Closed__c, Description__c, FinServ__Household__c,
                Include_on_Net_Worth__c, FinServ__JointOwner__c, Net_Worth_Account_Display_Name__c, FinServ__PrimaryOwner__c, Taxable__c, 
                Total_Assets__c, Trust__c, FinServ__AssetsAndLiabilitiesType__c, FinServ__JointOwner__r.FirstName, FinServ__PrimaryOwner__r.FirstName
            FROM FinServ__AssetsAndLiabilities__c
                    Where Id = :itemId 
                        Limit 1];

        return null;                                        
    }

    public PageReference queryEditInsObj() {
        //System.debug('===========> queryEditObj');
        String itemId = Apexpages.currentPage().getParameters().get('itemId');
        //System.debug('===========> queryEditInsObj - itemId '+itemId);

        editIns = [Select RecordTypeId, Policy_Owner__c, Trustee__c, PolicyType, Name,
        CashSurrenderValue, Carrier__c, Include_on_Net_Worth__c, Values_As_Of__c, Net_Worth_Notes__c,
                        On_Balance_Sheet__c, Death_Benefit__c, Insurance_Type_Auto__c, Beneficiaries__c,
                        Cost_Basis__c, EffectiveDate, PremiumAmount, NameInsuredId, NameInsured.Name, NameInsured.FirstName, IsActive, Status, CancellationDate 
                    From InsurancePolicy 
                    Where Id = :itemId 
                        Limit 1];   

        //tempVal saves value prior to save so we can see if the user changed the value. If so, the as of date updates, otherwise it stays the same
        //tempVal2 need two temp vars for Death Benefit and Cash Value checks. NOT CURRENTLY USED
        //tempVal =  editIns.Death_Benefit__c;
        //tempVal2 =  editIns.Cash_Surrender_Value__c;

        return null;
    }   

    public PageReference saveEditValues() {
        //System.debug('========================> Saving Edited FA Record!'+editFA);
        if (tempVal != editFA.FinServ__Balance__c){
            editFA.As_of_Date__c = date.today();
        }
        if (editFA.OASP_FSC__Active__c == false) {
            editFA.Account_Notes__c = editFA.Account_Notes__c + ', ' + household.Name + ', ' + objId + ', ' + editFa.FinServ__PrimaryOwner__c + ', ' + editFA.FinServ__JointOwner__c;
            //editFA.FinServ__Household__c = deleteHousehold.Id;
            //editFA.FinServ__PrimaryOwner__c = NULL;
            //editFA.FinServ__JointOwner__c = NULL;
        }
        update editFA;
        return refreshPage();
    }

    public PageReference saveEditAssetValues() {
        update editAsset;
        return refreshPage();
    }

    public PageReference saveEditInsValues() {
        //System.debug('========================> Saving Edited Insurance Record!'+editIns);
        // per Mike: policy status change to “Terminated – Net Worth” and change the termination date field to one day before whenever it is marked
        if (editIns.IsActive == false) {
            editIns.Status = 'Terminated – Net Worth';
            editIns.CancellationDate = System.today().addDays(-1);          
        }
        update editIns;
        return refreshPage();
    }   

    private PageReference refreshPage() {
        //initialize();
        //return null;
        // rerender issue - not refreshing the entire page
        return new PageReference('/apex/NetWorth?id='+objId).setRedirect(true);     
    }

    private void initializeParams() {
        liquidAssetCategoryString = '';
        pageErrors = false;
        categorySortMap = NetWorthUtilities.getAllCategoryList();
        asOfDate = System.today().month()+'/'+System.today().day()+'/'+System.today().year();           
        editFA = new FinServ__FinancialAccount__c();
        editIns = new InsurancePolicy();
        bfNoteMap = new Map<String,String>();
        liquidAssets = new Map<String,List<ReportAsset>>();
        otherAssets = new Map<String,List<ReportAsset>>();
        outsideAssets = new Map<String,List<ReportAsset>>();            
        deathBenefits = new Map<String,List<ReportAsset>>();        
        primaryBeneficiaryMap = new Map<String,Beneficiary__c>();  
        bMap = new Map<String,List<Beneficiary__c>>(); 
    }

    private void queryHHInfo() {
        household = [
            Select Name, FinServ__PrimaryContact__r.FirstName, (SELECT Id, AccountId, Account.Name, Account.FirstName, ContactId, Contact.FirstName, Roles FROM AccountContactRelations WHERE Roles INCLUDES ('Spouse', 'Client') AND FinServ__PrimaryGroup__c = true) From Account Where Id = :objId
        ];
        primaryName = '';
        spouseName = '';
        if (household.AccountContactRelations != null && !household.AccountContactRelations.isEmpty()) {
            for (AccountContactRelation acr : household.AccountContactRelations) {
                if (acr.Roles == 'Client') {
                    primaryName = acr.Contact.FirstName;
                }
                else if (acr.Roles == 'Spouse') {
                    spouseName = acr.Contact.FirstName;
                }
            }
        }
        //deleteHousehold = [SELECT Id FROM Account WHERE Name = 'CCM Old Net Worth Accounts'];
    }

    private void queryRecords() {
        // all related financial accounts
        accounts = [Select Name, RecordTypeId, Net_Worth_Classification__c, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.FirstName,
                FinServ__JointOwner__c, FinServ__JointOwner__r.FirstName, FinServ__Ownership__c, FinServ__FinancialAccountType__c, FinServ__FinancialAccountNumber__c,
                OASP_FSC__Custodian__c, OASP_FSC__Custodian__r.Name, OASP_FSC__Active__c, Include_on_Net_Worth__c, FinServ__Balance__c, 
                As_of_Date__c, Account_Notes__c, Cost_Basis__c, FinServ__TaxStatus__c, Net_Worth_Account_Display_Name__c, Trust_Administration__c
            From FinServ__FinancialAccount__c 
            Where FinServ__Household__c=:objId and Include_on_Net_Worth__c = true and OASP_FSC__Active__c = true
            ORDER BY FinServ__PrimaryOwner__r.FirstName];

        assets = [SELECT Account_Notes__c, Account_Number__c, Account_Type__c, FinServ__Amount__c, As_of_Date__c, Name, Closed__c, Description__c, FinServ__Household__c,
                Include_on_Net_Worth__c, FinServ__JointOwner__c, Net_Worth_Account_Display_Name__c, FinServ__PrimaryOwner__c, Taxable__c, 
                Total_Assets__c, Trust__c, FinServ__AssetsAndLiabilitiesType__c, FinServ__JointOwner__r.FirstName, FinServ__PrimaryOwner__r.FirstName,
                RecordTypeId, RecordType.Name, FinServ__Ownership__c
            FROM FinServ__AssetsAndLiabilities__c
            WHERE FinServ__Household__c=:objId and Include_on_Net_Worth__c = true and Closed__c = false];
        
        // beneficiaries
        beneficiaries = [Select Name, Household__c,Financial_Account_Orion__c,Percentage__c,Type__c,Contact__c,Contact__r.FirstName,ContactText__c 
                            From Beneficiary__c 
                            Where Financial_Account_Orion__c in :accounts OR Asset_Liability_Account__c IN :assets];

        // insurance policies
        insurance = [Select RecordTypeId, Policy_Owner__c, Trustee__c, Trust_Owned__c, PolicyType, Name,
                CashSurrenderValue, Carrier__c, Include_on_Net_Worth__c, Values_As_Of__c, Net_Worth_Notes__c,
                On_Balance_Sheet__c, Death_Benefit__c, Insurance_Type_Auto__c, Beneficiaries__c,
                Cost_Basis__c, EffectiveDate, PremiumAmount, NameInsuredId, NameInsured.Name, NameInsured.FirstName 
            From InsurancePolicy 
            Where FinServ__Household__c=:objId and Include_on_Net_Worth__c=true and Status='In Force']; 

        householdRebalancing = [
            SELECT 
                Id, Name, OASP_FSC__Realized_G_L_YTD__c, Client_Inception_Date__c, Model__c,
                //(SELECT Id, Name, Rebalance_Date__c, Submission_Type__c, Submission__c, Reviewed__c, Reviewed_Tick__c, Traded__c, Traded_Tick__c, Trade__c, Trade__r.CaseNumber FROM Rebalances__r WHERE Rebalance_Date__c = LAST_N_DAYS:365 ORDER BY Rebalance_Date__c DESC)
                (SELECT Id, FSTR__Due_Date__c, Subject FROM FinServ__HouseholdCases__r WHERE (RecordType.DeveloperName = 'Eclipse_Trades' OR RecordType.DeveloperName ='iRebal_Trade') AND FSTR__Due_Date__c = LAST_N_DAYS:365 ORDER BY FSTR__Due_Date__c DESC)

            FROM 
                Account 
            WHERE 
                Id = :objId
        ];
    }

    public String capitalizeFirstLetters(String title) {
        List<String> capitalizedWords = new List<String>();
            for (String word : title.split(' ')) {
                capitalizedWords.add(word.toLowerCase().capitalize());
            }
            return String.join(capitalizedWords, ' ');
    }

    private void setDisplayMapsByCategory() {
    
        Set<String> liquidCategories = new Set<String>{'Retirement',
                                                        'Roth',
                                                        'Bank',
                                                        'Investment',
                                                        'Qualified Annuity',
                                                        'Non-Qualified Annuity',
                                                        'Health Savings'};
        Set<String> otherCategories = new Set<String>{'Insurance',
                                                        'Real Estate',
                                                        'Personal Property/Autos',
                                                        'Notes Receivable',
                                                        'Business/Partnerships',
                                                        'Liabilities'};     

        for (FinServ__FinancialAccount__c f : accounts) {
            // exclude closed accounts
            //if (!f.Account_Closed__c) {
                String category = (f.Net_Worth_Classification__c!=null && f.Net_Worth_Classification__c!='Other') ? f.Net_Worth_Classification__c : NetWorthUtilities.categorizeAccount(f.FinServ__FinancialAccountType__c,f.OASP_FSC__Custodian__c);
                                
                ReportAsset ra = new ReportAsset(f,rtMap,bfNoteMap,primaryBeneficiaryMap,household, primaryName, spouseName);
                if (f.Net_Worth_Account_Display_Name__c != null) {
                    ra.itemName = f.Net_Worth_Account_Display_Name__c;
                }
                //organize into separate lists based on above
                String sectionCategory = NetWorthUtilities.onBalanceSectionMap(category);  
                if (sectionCategory!=null) {
                    //System.debug('======================> category => '+category);
                    //System.debug('======================> sectionCategory => '+sectionCategory);
                    //System.debug('======================> ReportAsset => '+ra);
                    if (liquidCategories.contains(category)) {
                        if (liquidAssets.containsKey(sectionCategory)) {
                            liquidAssets.get(sectionCategory).add(ra);
                        } else {
                            liquidAssets.put(sectionCategory,new List<ReportAsset>{ra});
                        }               
                    } else if (otherCategories.contains(category)) {
                        if (otherAssets.containsKey(sectionCategory)) {
                            otherAssets.get(sectionCategory).add(ra);
                        } else {
                            otherAssets.put(sectionCategory,new List<ReportAsset>{ra});
                        }                       
                    } else {
                        if (outsideAssets.containsKey(sectionCategory)) {
                            outsideAssets.get(sectionCategory).add(ra);
                        } else {
                            outsideAssets.put(sectionCategory,new List<ReportAsset>{ra});
                        }                       
                    }
                }
            //}
        }

        for (FinServ__AssetsAndLiabilities__c f : assets) {
            // exclude closed accounts
            //if (!f.Account_Closed__c) {
                String category = f.FinServ__AssetsAndLiabilitiesType__c;
                                
                ReportAsset ra = new ReportAsset(f,rtMap,bfNoteMap,primaryBeneficiaryMap,household, primaryName, spouseName);
                if (f.Net_Worth_Account_Display_Name__c != null) {
                    ra.itemName = f.Net_Worth_Account_Display_Name__c;
                }
                //organize into separate lists based on above
                String sectionCategory = NetWorthUtilities.onBalanceSectionMap(category);   
                if (sectionCategory!=null) {
                    //System.debug('======================> category => '+category);
                    //System.debug('======================> sectionCategory => '+sectionCategory);
                    //System.debug('======================> ReportAsset => '+ra);
                    if (liquidCategories.contains(category)) {
                        if (liquidAssets.containsKey(sectionCategory)) {
                            liquidAssets.get(sectionCategory).add(ra);
                        } else {
                            liquidAssets.put(sectionCategory,new List<ReportAsset>{ra});
                        }               
                    } else if (otherCategories.contains(category)) {
                        if (otherAssets.containsKey(sectionCategory)) {
                            otherAssets.get(sectionCategory).add(ra);
                        } else {
                            otherAssets.put(sectionCategory,new List<ReportAsset>{ra});
                        }                       
                    } else {
                        if (outsideAssets.containsKey(sectionCategory)) {
                            outsideAssets.get(sectionCategory).add(ra);
                        } else {
                            outsideAssets.put(sectionCategory,new List<ReportAsset>{ra});
                        }                       
                    }
                }
            //}
        }       

        totalRowMap = new Map<String,Double>();

        // add total rows
        Double clientTotal = 0;
        Double insuranceCashValue = 0;
        for (String s : liquidAssets.keySet()) {
            Double catTotal = 0;
            for (ReportAsset r : liquidAssets.get(s)) {
                catTotal+=r.netValue!=null ? r.netValue : 0;
            }
            clientTotal+=catTotal;
            String thisCat = 'Total '+capitalizeFirstLetters(s);
            categorySortMap.add(thisCat);
            liquidAssets.get(s).add(new ReportAsset(thisCat,catTotal));
        }
        //liquidAssets = sortSection(liquidAssets);
        // add total row to map (for amount lookup) and to key itself to ensure it's displayed
        String totalRowKey = 'Total Liquid Assets';
        totalRowMap.put(totalRowKey,clientTotal);
        liquidAssets.put(totalRowKey,new List<ReportAsset>());
        
        for (String s : otherAssets.keySet()) {
            Double catTotal = 0;
            for (ReportAsset r : otherAssets.get(s)) {
                //System.debug('===================> reportasset 242 '+r);
                catTotal+=r.netValue!=null ? r.netValue : 0;
            }
            String categoryName = capitalizeFirstLetters(s);
            // add all but insurance cash value to total (2015-10-26)
            if (categoryName.equalsIgnoreCase('insurance cash value')) {
                insuranceCashValue+=catTotal;
            }
            clientTotal+=catTotal;
            String thisCat = 'Total '+categoryName;
            categorySortMap.add(thisCat);           
            otherAssets.get(s).add(new ReportAsset(thisCat,catTotal));
        }
        //otherAssets = sortSection(otherAssets);
        totalRowKey = 'Total Net Worth';
        totalRowMap.put(totalRowKey,clientTotal);
        otherAssets.put(totalRowKey,new List<ReportAsset>());
        
        for (String s : deathBenefits.keySet()) {
            Double catTotal = 0;
            for (ReportAsset r : deathBenefits.get(s)) {
                catTotal+=r.netValue!=null ? r.netValue : 0;
            }
            clientTotal+=catTotal;
            deathBenefits.get(s).add(new ReportAsset('Total '+capitalizeFirstLetters(s),catTotal));
        }
        //deathBenefits = sortSection(deathBenefits);
        totalRowKey = 'Total Estate';//per Mike remove this total 2015-11-03 added back 11-05
        // remove insurance cash value from total estate
        totalRowMap.put(totalRowKey,clientTotal-insuranceCashValue);//per Mike remove this total 2015-11-03 added back 11-05
        deathBenefits.put(totalRowKey,new List<ReportAsset>());     //per Mike remove this total 2015-11-03 added back 11-05
        
        for (String s : outsideAssets.keySet()) {
            Double catTotal = 0;
            for (ReportAsset r : outsideAssets.get(s)) {
                catTotal+=r.netValue!=null ? r.netValue : 0;
            }
            clientTotal+=catTotal;
            String thisCat = 'Total '+capitalizeFirstLetters(s);
            categorySortMap.add(thisCat);                   
            outsideAssets.get(s).add(new ReportAsset(thisCat,catTotal));
        }   
        //outsideAssets = sortSection(outsideAssets);

        //per Mike 2015-11-03 the equation should exclude insurance cash values
        //per Mike 2015-11-03 Total Net Worth – Insurance Cash Value + Insurance Death Benefits + Outside Estate items.     
        totalRowKey = 'Grand Total Estate + Outside Estate';
        totalRowMap.put(totalRowKey,clientTotal-insuranceCashValue); 
        outsideAssets.put(totalRowKey,new List<ReportAsset>());

        // one financial account data has been added
        // assemble insurance policy details
        totalRowMapString = '';
        for (String s : totalRowMap.keySet()) { totalRowMapString+=';'+s; }

        // to display on screen correctly
        liquidAssetCategoryString='';
        for (String s : liquidAssets.keySet()) { liquidAssetCategoryString+=';'+s; }        
        otherAssetsCategoryString='';
        for (String s : otherAssets.keySet()) { otherAssetsCategoryString+=';'+s; }         
        outsideAssetsCategoryString='';
        for (String s : outsideAssets.keySet()) { outsideAssetsCategoryString+=';'+s; }     

        categorySortMap.addAll(totalRowMap.keySet());
        //System.debug('===================> liquidAssetCategoryString: '+liquidAssetCategoryString);
        //System.debug('===================> otherAssetsCategoryString: '+otherAssetsCategoryString);
        //System.debug('===================> outsideAssetsCategoryString: '+outsideAssetsCategoryString);
    }

    private void populateEstateSummaryGrid() {
        // populate estate summary grid
        List<EstateSummaryGrid> estateSummary = new List<EstateSummaryGrid>();

        for (String s : liquidAssets.keySet()) {
            estateSummary.add(new EstateSummaryGrid(s.toLowerCase().capitalize(),liquidAssets.get(s)));
        }
        for (String s : otherAssets.keySet()) {
            // cash value is not shown anywhere on the Estate Summary
            if (!s.toLowerCase().equalsIgnoreCase('insurance cash value')) {
                estateSummary.add(new EstateSummaryGrid(capitalizeFirstLetters(s),otherAssets.get(s)));
            }
        }
        for (String s : deathBenefits.keySet()) {
            //System.debug('===================> deathBenefits: '+deathBenefits.get(s));
            estateSummary.add(new EstateSummaryGrid(capitalizeFirstLetters(s),deathBenefits.get(s)));
        }
        // per Mike "we actually shouldn’t have any outside of the estate items on the estate summary page"
        // 2015-11-03 confirmed 11-05
        //for (String s : outsideAssets.keySet()) {
        //  estateSummary.add(new EstateSummaryGrid(s.toLowerCase().capitalize(),outsideAssets.get(s)));
        //}     

        // loop through estate summary list
        Map<Integer,List<EstateSummaryGrid>> gridLayout = new Map<Integer,List<EstateSummaryGrid>>{
            1=>new List<EstateSummaryGrid>(),
            2=>new List<EstateSummaryGrid>(),
            3=>new List<EstateSummaryGrid>(),
            4=>new List<EstateSummaryGrid>()
        };

        //System.debug('======================> estateSummary: '+estateSummary);        

        for (EstateSummaryGrid e : estateSummary) {
            if (e.categoryName!=null && NetWorthUtilities.estateSections(e.categoryName.toUpperCase())!=null) {
                Integer sectionNum = NetWorthUtilities.estateSections(e.categoryName.toUpperCase());
                //System.debug('e.categoryName '+e.categoryName+', sectionNum '+sectionNum);
                if (gridLayout.containsKey(sectionNum)) {
                    gridLayout.get(sectionNum).add(e);
                } else {
                    gridLayout.put(sectionNum,new List<EstateSummaryGrid>{e});
                }
            }
        }
        //System.debug('======================> gridLayout: '+gridLayout);

        // ESTATE TOTALS
        finalEstateLayout = new List<EstateSummaryGrid>();
        Double totalEstate1 = 0;
        Double totalEstate2 = 0;
        Double totalEstate3 = 0;
        Double totalEstate4 = 0;    
        for (Integer i : gridLayout.keySet()) {
            Double client1Total = 0;
            Double client2Total = 0;            
            Double jointTotal = 0;
            Double otherTotal = 0;
            for (EstateSummaryGrid e : gridLayout.get(i)) {
                client1Total += e.client1Total;
                client2Total += e.client2Total;         
                jointTotal += e.jointTotal;
                otherTotal += e.otherTotal;
                finalEstateLayout.add(e);
            }
            // aggregate total by section 
            totalEstate1+=client1Total;
            totalEstate2+=client2Total;
            totalEstate3+=jointTotal;
            totalEstate4+=otherTotal;

            // if part of estate add sub-totals
            if (i!=4 && (client1Total!=0 || client2Total!=0 || jointTotal!=0 || otherTotal!=0)) { // && (client1Total!=0 || client2Total!=0 || jointTotal!=0 || otherTotal!=0)
                finalEstateLayout.add(new EstateSummaryGrid('Sub-Total',client1Total,client2Total,jointTotal,otherTotal));
                // add trailing blank row
                finalEstateLayout.add(new EstateSummaryGrid());             
            }
            
            if (i==3 && (totalEstate1!=0 || totalEstate2!=0 || totalEstate3!=0 || totalEstate4!=0)) {
                // add estate totals
                finalEstateLayout.add(new EstateSummaryGrid('Total Estate',totalEstate1,totalEstate2,totalEstate3,totalEstate4));
                // add trailing blank row
                finalEstateLayout.add(new EstateSummaryGrid());         
            }

            // final totals for outside of estate and grand total estate
            if (i==4) {
                // add estate totals - per Mike remove 'Total Outside Estate' 2015-11-03
                //if (client1Total!=0 || client2Total!=0 || jointTotal!=0 || otherTotal!=0) {
                //  finalEstateLayout.add(new EstateSummaryGrid('Total Outside Estate',client1Total,client2Total,jointTotal,otherTotal));
                //  // add trailing blank row
                //  finalEstateLayout.add(new EstateSummaryGrid()); 
                //}
                // grand total
                if (totalEstate1!=0 || totalEstate2!=0 || totalEstate3!=0 || totalEstate4!=0) {
                    finalEstateLayout.add(new EstateSummaryGrid('Grand Total Estate',totalEstate1,totalEstate2,totalEstate3,totalEstate4));
                }
            }
        }


        // OUTSIDE ESTATE TOTALS
        // collect sub-totals by related categories
        // create new list IN ORDER with sub-totals for each category
    }

    private void assembleInsuranceDetails() {
        // categorize insurance here - handle value display on page
        // totals map will need to aggregate based on type
        insuranceDeathBenefits= new List<InsurancePolicy>();
        //Map<String,Map<String,Double>> onEstateTotalsMap = new Map<String,Map<String,Double>>();
        //Map<String,Map<String,Double>> offEstateTotalsMap = new Map<String,Map<String,Double>>();
        Set<Id> deathBenefitPolicyIds = new Set<Id>();//avoids double-counting death benefits
        for (InsurancePolicy i : insurance) {
            Double insValue = 0;
            Boolean isEstateIncluded = true;
            Boolean onBalanceSheet = i.On_Balance_Sheet__c;
            
            if (i.Insurance_Type_Auto__c=='Long Term Care' || i.Insurance_Type_Auto__c=='Disability Income') {
                isEstateIncluded = false;
                onBalanceSheet = true; //always on-balance sheet
            } else if (i.Insurance_Type_Auto__c=='Annuity' || i.Insurance_Type_Auto__c=='Life Insurance') {
                insValue = i.CashSurrenderValue;
                if (i.Death_Benefit__c!=null && i.Death_Benefit__c>0) {
                    insuranceDeathBenefits.add(i);
                }
                if (i.Insurance_Type_Auto__c=='Annuity') {
                    onBalanceSheet = false;
                }
            }

            // if in trust - not on balance sheet
            // Removed on 9/20/16 by Mike at Tony's request because we don't want policies held by a revocable trust off balance sheet. Only irrevocable trust policies are off balance sheet
            // Will require better checking of insurance policy setup to make sure things are accurate
            //if (i.Trust_Owned__c!=null) {
            //  onBalanceSheet = false;
            //}

            //insuranceAmountMap.put()

            // add to on- and off- lists
            String category = 'INSURANCE CASH VALUE';
            ReportAsset ra = new ReportAsset(i,onBalanceSheet,insRTMap,onInsNoteMap,offInsNoteMap,primaryName,spouseName);
            if (onBalanceSheet) {
                if (otherAssets.containsKey(category)) {
                    otherAssets.get(category).add(ra);
                } else {
                    otherAssets.put(category,new List<ReportAsset>{ra});
                }
                if (i.Death_Benefit__c!=null && i.Death_Benefit__c>0 && !deathBenefitPolicyIds.contains(i.Id) && i.Insurance_Type_Auto__c!='Disability Income') {
                    ReportAsset newRA = new ReportAsset(i,false,insRTMap,onInsNoteMap,offInsNoteMap,primaryName,spouseName);
                    category = 'INSURANCE DEATH BENEFITS';
                    // set death benefits as the amount for this on-balance sheet section
                    if (deathBenefits.containsKey(category)) {
                        deathBenefits.get(category).add(newRA);
                    } else {
                        deathBenefits.put(category,new List<ReportAsset>{newRA});
                    }
                    deathBenefitPolicyIds.add(i.Id);                
                }   
            }
        }   

        // add death benefits (separate list)
        String dbCategory = 'INSURANCE DEATH BENEFITS';
        for (InsurancePolicy i : insuranceDeathBenefits) {
            ReportAsset ra = new ReportAsset(i,false,insRTMap,onInsNoteMap,offInsNoteMap,primaryName,spouseName);
            if (i.Death_Benefit__c!=null && i.Death_Benefit__c>0 && !deathBenefitPolicyIds.contains(i.Id)) {
                if (outsideAssets.containsKey(dbCategory)) {
                    outsideAssets.get(dbCategory).add(ra);
                } else {
                    outsideAssets.put(dbCategory,new List<ReportAsset>{ra});
                }
                deathBenefitPolicyIds.add(i.Id);                
            }
        }               
    }   



    /* NOTES FIELDS */

    // notes for financial accounts, on or off balance sheet
    private void assembleFinAcctNotes() {
        system.debug('IN ASSEMBLE FINANCIAL NOTES');
        system.debug('bMap: ' + bMap);
        for (FinServ__FinancialAccount__c acct : accounts) {
            System.debug('Current Financial Account: ' + acct.Name);
            String retTxt = '';
            if (bMap!=null && bMap.containsKey(acct.Id)) {
                // new values for each account
                String primary;
                String contingent;
                String tertiary;
                String trustee;
                String annuitant;
                String poa; 
                String successor;
                String finalBene;

                // assemble a list by beneficiary type
                for (Beneficiary__c f : bMap.get(acct.Id)) {
                    system.debug('CURRENT BENEFICIARY: ' + f.Name);
                    String mathStr = (f.Percentage__c!=null && (Integer.valueOf(f.Percentage__c)-f.Percentage__c)==0) ? String.valueOf(Math.round(f.Percentage__c)) : String.valueOf(f.Percentage__c);
                    String bfInfo = (f.Contact__c!=null ? f.Contact__r.FirstName : f.ContactText__c)+' - '+mathStr+'%';

                    // add to specific section by 'type'
                    if (f.Type__c.equalsIgnoreCase('primary')) {
                        primary = assembleString(primary,bfInfo,'Primary');
                    } else if (f.Type__c.equalsIgnoreCase('contingent')) {
                        contingent = assembleString(contingent,bfInfo,'Contingent');
                    } else if (f.Type__c.equalsIgnoreCase('tertiary')) {
                        tertiary = assembleString(tertiary,bfInfo,'Tertiary');
                    } else if (f.Type__c.equalsIgnoreCase('trustee')) {
                        trustee = assembleString(trustee,bfInfo,'Trustee');
                    } else if (f.Type__c.equalsIgnoreCase('annuitant')) {
                        annuitant = assembleString(annuitant,bfInfo,'Annuitant');
                    } else if (f.Type__c.equalsIgnoreCase('poa')) {
                        poa = assembleString(poa,bfInfo,'POA');
                    } else if (f.Type__c.equalsIgnoreCase('successor trustee')) {
                        successor = assembleString(poa,bfInfo,'Successor Trustee');
                    } else if (f.Type__c.equalsIgnoreCase('final beneficiary')) {
                        finalBene = assembleString(poa,bfInfo,'Final Beneficiary');
                    }
                }

                // create notes field in pre-set order

                if (primary!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=primary+'\n';
                }
                if (contingent!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=contingent+'\n';
                }
                if (tertiary!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=tertiary+'\n';
                }
                if (trustee!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=trustee+'\n';
                }
                if (annuitant!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=annuitant+'\n';
                }
                if (poa!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=poa+'\n';           
                }
                if (successor!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=successor+'\n';         
                }
                if (finalBene!=null) {
                    if (retTxt!='') retTxt+='/ ';
                    retTxt+=finalBene+'\n';         
                }
            }

            // add to existing beneficiary notes
            if (acct.Account_Notes__c!=null) {
                if (retTxt!='') retTxt+='/ \n';
                retTxt+=acct.Account_Notes__c;
            }

            // add the assembled beneficiary/notes field to map
            bfNoteMap.put(acct.Id,retTxt);              
        }
    }


    // insurance notes - displayed based on the insurance policy
    private void assembleInsuranceNotes() {
        onInsNoteMap = new Map<String,String>();
        offInsNoteMap = new Map<String,String>();
        for (InsurancePolicy i : insurance) {
            // create notes field in pre-set order
            String onRetTxt = '';
            String offRetTxt = '';

            if (i.Insurance_Type_Auto__c=='Life Insurance' || i.Insurance_Type_Auto__c=='Annuity') {
                if (i.Death_Benefit__c!=null && i.Death_Benefit__c>0) {
                    onRetTxt = 'Death Benefit: $'+i.Death_Benefit__c.format()+'\n'; //|| 'Cash Value: '+i.Cash_Value__c;
                }
                if (i.CashSurrenderValue != null && i.CashSurrenderValue > 0) {
                    offRetTxt = 'Cash Value: $'+i.CashSurrenderValue.format()+'\n';
                }                               
            } 

            if (i.PremiumAmount != null && i.PremiumAmount > 0) {
                String premiumTxt = 'Annualized Premium: $'+i.PremiumAmount.format()+'\n';
                onRetTxt+=premiumTxt;
                offRetTxt+=premiumTxt;
            }           

            // add notes
            if (i.Net_Worth_Notes__c!=null) {
                if (onRetTxt!='') onRetTxt+='/\n';
                onRetTxt+=i.Net_Worth_Notes__c;
                if (offRetTxt!='') offRetTxt+='/\n';
                offRetTxt+=i.Net_Worth_Notes__c;                              
            }
            
            // add notes to each map - available for use in page (1 on-BS, 1 off-BS)
            onInsNoteMap.put(i.Id,onRetTxt);    
            // add the assembled beneficiary/notes field to map
            offInsNoteMap.put(i.Id,offRetTxt);              
        }
    }


    private void assembleBeneficiaryLookups() {
        for (Beneficiary__c b : beneficiaries) {
            if (b.Type__c=='Primary') {
                primaryBeneficiaryMap.put(b.Financial_Account_Orion__c,b);
            }
            if (bMap.containsKey(b.Financial_Account_Orion__c)) {
                bMap.get(b.Financial_Account_Orion__c).add(b);
            } else {
                bMap.put(b.Financial_Account_Orion__c,new List< Beneficiary__c>{b});
            }
        }           
    }

    private void assembleRecordTypeMaps() {
        // financial accounts
        List<RecordType> rts = [Select Name From RecordType Where sObjectType='FinServ__FinancialAccount__c'];
        List<RecordType> arts = [Select Name From RecordType Where sObjectType='FinServ__AssetsAndLiabilities__c'];
        List<RecordType> insRTs = [Select Name From RecordType Where sObjectType='InsurancePolicy'];
        
        rtMap = new Map<String,String>();
        for (RecordType r : rts) {
            rtMap.put(r.Id,r.Name);
        }

        assetRTMap = new Map<String,String>();
        for (RecordType r : arts) {
            assetRTMap.put(r.Id,r.Name);
        }

        // insurance 
        insRTMap = new Map<String,String>();
        for (RecordType r : insRTs) {
            if (r.Name=='Pipeline') {
                pipelineId = r.Id;
            } else {
                insRTMap.put(r.Id,r.Name);
            }
        }       
    }   


    /* UTLITY METHODS */

    //private String getName

    // assembles Type string according to CCM specs
    private String assembleString(String txt,String newInfo,String typeString) {
        if (txt!=null) {
            txt+='; ';
        } else {
            txt=typeString+': ';
        }
        return txt+=newInfo;
    }

}