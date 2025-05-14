public with sharing class ReportAsset {
    public FinServ__FinancialAccount__c finAcct {get; set;} //public Financial_Account__c finAcct {get;set;}
    public FinServ__AssetsAndLiabilities__c asset {get; set;}
	public InsurancePolicy insurance {get; set;} //public Insurance_Policy__c insurance {get;set;}

	public String itemId {get;set;}
	public Boolean isFinAcct {get;set;}
	public Boolean isAdvisorEntered;
	public Boolean isPCAccount {get;set;}
	public Boolean isTrust {get;set;}
	public String sectionCategory {get;set;}
	public String itemOwner {get;set;}
	public String estateCategory {get;set;}
    public Date itemDate {get; set;}

	public String owner1 {get;set;}
	public String owner2 {get;set;}
	public String itemName {get;set;}
	public String accountNumber {get;set;}
	public Double netValue {get;set;}
	public String itemNotes {get;set;}
	//public String RecordTypeName {get;set;}

	// estate grid column
	public Boolean isEstateOwner1 {get;set;}
	public Boolean isEstateOwner2 {get;set;}
	public Boolean isJoint {get;set;}		
	public Boolean isOther;

	public ReportAsset(FinServ__FinancialAccount__c a, Map<String,String> rtMap, Map<String,String> bfNoteMap, Map<String, Beneficiary__c> primaryBMap, Account household, String primaryName, String spouseName) {
		initialize();
		
        this.itemDate = a.As_of_Date__c;
        if (this.itemDate == NULL) {
        	this.itemDate = date.today();
        }
		this.itemId = a.Id;
		this.finAcct = a;
		this.isFinAcct = true;
		this.isPCAccount = true;
		this.isAdvisorEntered = false;		
		this.itemNotes = bfNoteMap.get(a.Id);
		this.itemOwner = a.FinServ__PrimaryOwner__r.FirstName; //a.Account_Owner_1__r.FirstName+(a.Account_Owner_2__c!=null ? ' & '+a.Account_Owner_2__r.FirstName : '');
		if (a.FinServ__JointOwner__c != null) this.itemOwner = a.FinServ__PrimaryOwner__r.FirstName + ' & ' + a.FinServ__JointOwner__r.FirstName;
		this.assembleFinAcctName(a,primaryBMap);
		this.accountNumber = a.FinServ__FinancialAccountNumber__c; //a.Account_Number__c;
        this.isTrust = a.FinServ__Ownership__c == 'Trust'; //a.Trust_Administration__c; // a.Trust__c;
		this.netValue = a.Net_Worth_Classification__c!=null && a.Net_Worth_Classification__c.equalsIgnoreCase('liabilities') ? -Math.abs(a.FinServ__Balance__c) : a.FinServ__Balance__c;
		setFinAcctEstateCategory(a,household, primaryName, spouseName);
    }
    
	public ReportAsset(FinServ__AssetsAndLiabilities__c a, Map<String,String> rtMap, Map<String,String> bfNoteMap, Map<String, Beneficiary__c> primaryBMap, Account household, String primaryName, String spouseName) {
		initialize();

        this.itemDate = a.As_of_Date__c;
        if (this.itemDate == NULL) {
        	this.itemDate = date.today();
        }
		this.itemId = a.Id;
		this.asset = a;
		this.isFinAcct = true;
		this.isPCAccount = false;
		this.isAdvisorEntered = false;		
		this.itemNotes = a.Account_Notes__c;
		this.itemOwner = a.FinServ__PrimaryOwner__r.FirstName; //a.Account_Owner_1__r.FirstName+(a.Account_Owner_2__c!=null ? ' & '+a.Account_Owner_2__r.FirstName : '');
		if (a.FinServ__JointOwner__c != null) this.itemOwner = a.FinServ__PrimaryOwner__r.FirstName + ' & ' + a.FinServ__JointOwner__r.FirstName;
		this.assembleFinAcctName(a,primaryBMap);
		this.accountNumber = a.Account_Number__c;
        this.isTrust = a.FinServ__Ownership__c == 'Trust'; // a.Trust__c;
		this.netValue = a.Total_Assets__c;
		if (a.RecordType.Name == 'Liability' && this.netValue != null) {
			this.netValue = -Math.abs(this.netValue);
		}
		setFinAcctEstateCategory(a,household, primaryName, spouseName);
    }

	public ReportAsset(InsurancePolicy a, Boolean onBS, Map<String,String> rtMap, Map<String,String> onMap, Map<String,String> offMap, String primaryName, String spouseName) {
		initialize();
        
        this.itemDate = date.today();
		this.itemId = a.Id;
		this.isFinAcct = false;
		this.isPCAccount = false;
		this.isTrust = a.Trust_Owned__c!=null;
        this.insurance = a;
        this.itemName = (a.Carrier__c!=null ? a.Carrier__c+' ' : '')+ a.PolicyType;
		this.itemOwner = a.NameInsured.Name;
        this.accountNumber = a.Name;
		this.netValue = onBS ? a.CashSurrenderValue : a.Death_Benefit__c;
		this.itemNotes = onBS ? onMap.get(a.Id) : offMap.get(a.Id);
		setInsuranceEstateCategory(a,primaryName,spouseName);
	}

	public ReportAsset(String totalTitle, Double val) {
		this.itemDate = Date.today();
        this.itemOwner = totalTitle;
		this.netValue = val;
	}

	public Boolean getIsAdvisorEntered() {
		return false;
	}

	// PRIVATE METHODS	
	private void initialize() {
		this.isEstateOwner1 = false;
		this.isEstateOwner2 = false;	
		this.isOther = false;
		this.isJoint = false;
		this.netValue = 0;		
	}

	private void assembleFinAcctName(FinServ__FinancialAccount__c acct, Map<String, Beneficiary__c> primaryBMap) {
        this.itemName = acct.FinServ__FinancialAccountType__c; //acct.Account_Type__c;
		if (acct.OASP_FSC__Custodian__r.Name == 'Schwab') {
			this.itemName='Schwab '+this.itemName;
		}
		if (primaryBMap != null && acct.Net_Worth_Classification__c!=null && acct.Net_Worth_Classification__c.equalsIgnoreCase('Education')) {
			if (primaryBMap.containsKey(acct.id)) { 
				if (primaryBMap.get(acct.id).Contact__c!=null) { 
					this.itemName+=' ('+primaryBMap.get(acct.id).Contact__r.FirstName+')';
				} else if (primaryBMap.get(acct.id).ContactText__c!=null) {
					this.itemName+=' ('+primaryBMap.get(acct.id).ContactText__c+')';
				}
			}
		}
	}

	// SET CATEGORIES FOR USE WITH EstateSummaryGrid
	private void setFinAcctEstateCategory(FinServ__FinancialAccount__c f, Account household, String primaryName, String spouseName) {
        String category = 'Other';
		if (f.FinServ__PrimaryOwner__c != null) {
			if (f.FinServ__JointOwner__c != null) {
				category = 'Joint';
				this.isJoint = true;
			}
			else {
				this.isEstateOwner1 = f.FinServ__PrimaryOwner__c != null && primaryName!=null && f.FinServ__PrimaryOwner__r.FirstName==primaryName;
				this.isEstateOwner2 = f.FinServ__PrimaryOwner__c != null && spouseName!=null && f.FinServ__PrimaryOwner__r.FirstName==spouseName;
				category = f.FinServ__PrimaryOwner__r.FirstName;
			}
		}
		this.estateCategory = category;	
	}

	private void assembleFinAcctName(FinServ__AssetsAndLiabilities__c acct, Map<String, Beneficiary__c> primaryBMap) {
        this.itemName = acct.Name; //acct.Account_Type__c;
		//if (acct.OASP_FSC__Custodian__r.Name == 'Schwab') {
		//	this.itemName='Schwab '+this.itemName;
		//}
		/*
		if (primaryBMap != null && acct.FinServ__AssetsAndLiabilitiesType__c!=null && acct.FinServ__AssetsAndLiabilitiesType__c.equalsIgnoreCase('Education')) {
			if (primaryBMap.containsKey(acct.id)) { 
				if (primaryBMap.get(acct.id).Contact__c!=null) { 
					this.itemName+=' ('+primaryBMap.get(acct.id).Contact__r.FirstName+')';
				} else if (primaryBMap.get(acct.id).ContactText__c!=null) {
					this.itemName+=' ('+primaryBMap.get(acct.id).ContactText__c+')';
				}
			}
		}*/
	}

	// SET CATEGORIES FOR USE WITH EstateSummaryGrid
	private void setFinAcctEstateCategory(FinServ__AssetsAndLiabilities__c f, Account household, String primaryName, String spouseName) {
        String category = 'Other';
		if (f.FinServ__PrimaryOwner__c != null) {
			if (f.FinServ__JointOwner__c != null) {
				category = 'Joint';
				this.isJoint = true;
			}
			else {
				this.isEstateOwner1 = f.FinServ__PrimaryOwner__c != null && primaryName!=null && f.FinServ__PrimaryOwner__r.FirstName==primaryName;
				this.isEstateOwner2 = f.FinServ__PrimaryOwner__c != null && spouseName!=null && f.FinServ__PrimaryOwner__r.FirstName==spouseName;
				category = f.FinServ__PrimaryOwner__r.FirstName;
			}
		}
		this.estateCategory = category;			
	}

	private void setInsuranceEstateCategory(InsurancePolicy f, String primaryName, String spouseName) {
		String category = 'Other';
		System.debug('insurance policy categorizing by owner '+f);
		if (f.Policy_Owner__c!=null) {
			if (f.On_Balance_Sheet__c) {
				if (f.Policy_Owner__c.contains('&') || f.Policy_Owner__c.contains(' and ')) {
					category = 'Joint';
					this.isJoint = true;
				} else if (f.NameInsured != null && f.Policy_Owner__c != null) {
					category = setCategory(primaryName,spouseName,f.Policy_Owner__c);
				} 
			} else {
				category = setCategory(primaryName,spouseName,f.Policy_Owner__c);
			}
		}
		this.estateCategory = category;			
	}		

	private String setCategory(String primaryName,String spouseName,String policyOwner) {
		String cat = 'Other';
		String ownerFirstName = policyOwner.split(' ').get(0);//collect firstname
		if (ownerFirstName==primaryName || ownerFirstName==spouseName) {
			this.isEstateOwner1 = ownerFirstName==primaryName;
			this.isEstateOwner2 = ownerFirstName==spouseName;					
			cat = ownerFirstName;
		}

		return cat;		
	}

	// is other, if not in the other categories
	public Boolean getIsOther() {
		return (!this.isEstateOwner1 && !this.isEstateOwner2 && !this.isJoint);
	}	

}