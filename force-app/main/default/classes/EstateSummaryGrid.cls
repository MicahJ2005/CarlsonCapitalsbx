public with sharing class EstateSummaryGrid {
	public String categoryName {get;set;}
	public List<ReportAsset> reportAssets {get;set;}
	public Boolean isTotalRow {get;set;}
	public Boolean isBlankRow {get;set;}

	public Double jointTotal {get;private set;}
	public Double client1Total {get;private set;}
	public Double client2Total {get;private set;}
	public Double otherTotal {get;private set;}
	public Double totalValue;
	public Integer section {get;private set;}

	// CONSTRUCTORS

	// list constructor - assembles totals from category list
	public EstateSummaryGrid(String catName,List<ReportAsset> reportAssets) {
		initialize();

		this.categoryName = catName;
		this.reportAssets = new List<ReportAsset>();
		// assemble totals from list
		for (ReportAsset r : reportAssets) {
			System.debug('==============> r '+r);
			if (r.estateCategory!=null && r.netValue!=null && r.netValue!=0) {
				Double netVal = r.netValue;// catName.equalsIgnoreCase('liabilities') ? -Math.abs(r.netValue) : r.netValue;
				if (r.isEstateOwner1) {
					this.client1Total+=netVal;
				} else if (r.isEstateOwner2) {
					this.client2Total+=netVal;
				} else if (r.isJoint) {
					this.jointTotal+=netVal;
				} else if (r.isOther) { 
					this.otherTotal+=netVal;
				}
				this.reportAssets.add(r);
			} 
		}
	}

	public EstateSummaryGrid(String catName,Double c1,Double c2,Double jnt,Double other) {
		initialize();

		this.categoryName = catName;
		this.client1Total = c1;
		this.client2Total = c2;			
		this.jointTotal = jnt;
		this.otherTotal = other;
		this.isTotalRow = true;

	}	

	public EstateSummaryGrid() {
		initialize();

		this.isBlankRow = true;
	}				

	// PUBLIC METHODS
	public Double getJointTotal() {
		return categoryTotal('Joint');
	}

	public Double getOtherTotal() {
		return categoryTotal('Other');
	}		

	public Double getTotalValue() {
		return jointTotal+client1Total+client2Total+otherTotal;
	}

	// PRIVATE METHODS

	private void initialize() {
		this.categoryName = '';		
		this.client1Total = 0;
		this.client2Total = 0;			
		this.jointTotal = 0;
		this.otherTotal = 0;
		this.section = 1;
		this.isTotalRow = false;
		this.isBlankRow = false;				
	}

	private Double categoryTotal(String category) {
		Double d = 0;
		for (ReportAsset ra : reportAssets) {
			if (ra.estateCategory.equalsIgnoreCase(category)) {
				d+=ra.netValue;
			}
		}
		return d;			
	}


}