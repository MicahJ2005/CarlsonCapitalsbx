@isTest
public class HttpCalloutMockService implements HttpCalloutMock {

    protected Integer code;
    protected String status;
    protected String body;
    protected Map<String, String> responseHeaders;

    // default to true - may be set to return errors in test method
    public Boolean isSuccessResponse = true;
    public Boolean chainedSuccessResponse = true;

    public HttpCalloutMockService() {}

    //public HttpCalloutMockService(Integer code, String status, String body, Map<String, String> responseHeaders) {
    //    this.code = code;
    //    this.status = status;
    //    this.body = body;
    //    this.responseHeaders = responseHeaders;
    //}

    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        //for (String key : this.responseHeaders.keySet()) {
        //    res.setHeader(key, this.responseHeaders.get(key));
        //}
        String reqEndpoint = req.getEndpoint();
        String reqMethod = req.getMethod();
        if (reqEndpoint.containsIgnoreCase('https://api.vault.netvoyage.com')) {
            if (reqEndpoint.containsIgnoreCase('/v1/Document')) { // DOCUMENT UPLOAD
                if (isSuccessResponse) {
                    res.setStatusCode(200);
                    res.setBody(getUploadSuccessTestResponse());
                } else {
                    res.setBody(getUploadErrorTestResponse());
                }
            } else if (reqEndpoint.containsIgnoreCase('/v1/OAuth')) { // OAUTH TOKEN
                if (isSuccessResponse) {
                    res.setStatusCode(200);
                    res.setBody(getTokenSuccessTestResponse());
                } else {
                    res.setBody(getTokenErrorTestResponse());
                }
            } else if (reqEndpoint.containsIgnoreCase('/v1/attributes/CA-7II96TKH/1/')) { //Updates Name at NetDocs when changed in Salesforce
                if (isSuccessResponse) {
                    res.setStatusCode(200);
                    res.setBody(getNetDocsNameChangeSuccess());
                } else {
                    res.setBody(genericFailure());
                }
            }
        } else if (reqEndpoint.containsIgnoreCase('intuit.com')) {
            if (reqEndpoint.containsIgnoreCase('/oauth2/v1')) { // OAUTH TOKEN
                if (isSuccessResponse) {
                    res.setStatusCode(200);
                    res.setBody(getTokenSuccessTestResponse());
                } else {
                    res.setBody(getTokenErrorTestResponse());
                }
            } else if (reqEndpoint.containsIgnoreCase('/reports/ProfitAndLoss')){ // OAUTH2 TOKEN
                if (isSuccessResponse){
                    res.setStatusCode(200);
                    res.setBody(getPnLResponse());
                } else {
                    res.setBody(getTokenErrorTestResponse());
                }
            }
        } else if (reqEndpoint.containsIgnoreCase('api.smartsheet.com')) {
            if (reqEndpoint.containsIgnoreCase('/columns?') && reqMethod == 'GET') { //Returns columns for the selected smartsheet 
                if (isSuccessResponse) {
                    res.setStatusCode(200);
                    res.setBody(getSmartSheetColumns());
                } else {
                    res.setBody(getTokenErrorTestResponse());
                }
            } else if (reqEndpoint.endsWithIgnoreCase('/rows') && reqMethod == 'POST'){ // Saving a new row to the smartsheet
                if (isSuccessResponse){
                    res.setStatusCode(200);
                    res.setBody(genericSuccess());
                } else {
                    res.setBody(getTokenErrorTestResponse());
                }
            }
        } else if (reqEndpoint.containsIgnoreCase('https://api.orionadvisor.com')){
            if (reqEndpoint.containsIgnoreCase('/Security/Token')){
                //Authentication with Orion - both initial and refresh (nothing done with the body, so using generic response only)
                if (isSuccessResponse){
                    res.setStatusCode(200);
                    res.setBody(getLongTokenSuccessTestResponse()); //Store refresh and access tokens
                } else {
                    res.setBody(getTokenErrorTestResponse());
                }
            } else if (reqEndpoint.containsIgnoreCase('Portfolio/Representatives/Verbose')){
                //Creating a new Orion Rep (POST) and updating those Reps to sync to Salesforce (PUT).
                if (reqMethod == 'POST'){
                    if (isSuccessResponse){
                        res.setStatusCode(200);
                        res.setBody(getNewRepresentativeTestResponse()); //Use the POST response to add IDs to the PUT request
                    } else {
                        res.setBody(getTokenErrorTestResponse());
                    }
                } else if (reqMethod == 'PUT'){
                    if (isSuccessResponse && chainedSuccessResponse){
                        res.setStatusCode(200);
                        res.setBody(genericSuccess()); //Nothing done with the response body
                    } else {
                        res.setBody(getTokenErrorTestResponse());
                    }
                }
            } 
        }
        //res.setStatusCode(this.code);
        //res.setStatus(this.status);
        return res;
    }
    
    private static String getNewRepresentativeTestResponse(){
        return '{"id":1,"name":"Test Advisor","portfolio":' +
        '{"brokerDealerId":1,"wholesalerId":null,"payeeId":65,"payoutOverride":null,"riaId":null,"wholesaler401KId":null,"planAdministratorId":null,"createdDate":"2018-07-17T15:18:38.003-05:00","copyToRep":false,"isRIA":false,"riaName":null,"royalTCode":null,"hasADV":false,"hasU4":false,"isActive":true,"isDstDwnld":false,"branchID":"005i0000000imh0AAA","oldRep_ID":null,"number":"005i0000000imh0AAAtest",'+
            '"impDate":null,"createdBy":"ccmapi","editedDate":"2018-07-17T15:18:38.003-05:00","editedBy":"ccmapi","startDate":"2018-07-17","repStatus":"Active/No Issues","firmName":"","actgLedgerNum":null,"isDefault":null,"importKey":null,"raAmount":null,"raDate":null,"isRAActive":null,"repRestrict":null,"name":"Test Advisor","salutation":null,"address1":null,"address2":null,"address3":null,"zip":null,'+
            '"homePhone":null,"homePhoneExt":null,"fax":null,"faxExt":null,"pager":null,"pagerExt":null,"mobilePhone":null,"businessPhone":null,"businessPhoneExt":null,"otherPhone":null,"otherPhoneExt":null,"reportName":null,"company":null,"jobTitle":null,"ssN_TaxID":null,"gender":null,"dob":null,"webAddress":null,"lastName":"Advisor","firstName":"Test","id":0,"city":null,"state":null,"email":null,'+
            '"repNasds":[],"repOnHolds":[]},"notes":null,"documents":null,"billRepresentativePlatforms":null,"reportImage":null,"userDefinedFields":null,"entityOptions":null}';
    }

    private static String getUploadSuccessTestResponse() {
        return '{'+
        '"customAttributes":[{"id":2,"value":"Client Documentation"},{"description":"Randy Moss Family","id":1,"value":"001i000000CjNgeAAF"},{"id":5,"value":"Photos"}],'+
        '"location":{"account":"CA-7II96TKH","cabinet":"NG-25V3O2A5"},'+
        '"misc":{"approved":false,"archived":false,"deleted":false,"echo":true,"external":false,"favorite":false,"signed":false},'+
        '"permissions":[{"administer":false,"cabDefault":false,"edit":true,"noAccess":false,"share":true,"view":true}],'+
        '"standardAttributes":{"created":"/Date(1411651258000)/","createdBy":"Tim Jackson","createdByGuid":"","envId":":Q15:e:u:f:q:~140925092058549.nev","extension":"jpg",'+
        '"id":"4847-8812-3422","modified":"/Date(1411651259000)/","modifiedBy":"Tim Jackson","modifiedByGuid":"VAULT-tim@carlsoncap.com","name":"Moss-Randy2","officialVer":1,"size":23,"syncMod":3599215354,"url":"https://vault.netvoyage.com/Q15/e/u/f/q/~140925092058549.nev","versions":1}'+
        '}';
    }

    private static String getUploadErrorTestResponse() {
        return '{"created":"/Date(1484049141974)/",'+
        '"createdBy":"CRM Admin",'+
        '"createdByGuid":"VAULT-IYG30ZS2",'+
        '"envId":":Q6:u:l:9:1:~170110065221974.nev",'+
        '"errors":["Profile error on field 1. Client requires a value.. ","Profile error on field 2. Doc Type requires a value.. "],'+
        '"extension":"pdf","id":"4826-8871-9424",'+
        '"modified":"/Date(1484049142662)/",'+
        '"modifiedBy":"CRM Admin",'+
        '"modifiedByGuid":"VAULT-IYG30ZS2",'+
        '"name":"NetDocuments REST API",'+
        '"officialVer":1,'+
        '"size":294,'+
        '"syncMod":7725019570,'+
        '"url":"https://vault.netvoyage.com/Q6/u/l/9/1/~170110065221974.nev",'+
        '"versions":1}';
    }   
    
    private static String getPnLResponse(){
        return '{"Header":{"Time":"2018-04-09T10:44:30-07:00","ReportName":"ProfitAndLoss","ReportBasis":"Accrual","StartPeriod":"2017-01-01","EndPeriod":"2017-12-31",' +
            '"SummarizeColumnsBy":"Total","Currency":"USD","Option":[{"Name":"AccountingStandard","Value":"GAAP"},{"Name":"NoReportData","Value":"false"}]},'+
            '"Columns":{"Column":[{"ColTitle":"","ColType":"Account","MetaData":[{"Name":"ColKey","Value":"account"}]},{"ColTitle":"Total","ColType":"Money",'+
            '"MetaData":[{"Name":"ColKey","Value":"total"}]}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":"Income"},{"value":""}]},"Rows":'+
            '{"Row":[{"Header":{"ColData":[{"value":"Asset Management Fee Income","id":"60"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"ACP","id":"62"},{"value":"1582.72"}],'+
            '"type":"Data"},{"ColData":[{"value":"Carlson Trust (NATC)","id":"63"},{"value":"5958.21"}],"type":"Data"},{"ColData":[{"value":"Charles Schwab","id":"64"},'+
            '{"value":"107387.43"}],"type":"Data"},{"Header":{"ColData":[{"value":"Institutional Fee Income","id":"61"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":'+
            '"401k (Carlson Institutional)","id":"110"},{"value":"4056.34"}],"type":"Data"},{"ColData":[{"value":"Endowment","id":"151"},{"value":"398.52"}],"type":"Data"}]},'+
            '"Summary":{"ColData":[{"value":"Total Institutional Fee Income"},{"value":"4654.86"}]},"type":"Section"},{"ColData":[{"value":"Panoramic Sub Advisor Fee","id":"230"},'+
            '{"value":"226.73"}],"type":"Data"},{"ColData":[{"value":"TIAA-CREF","id":"66"},{"value":"5146.06"}],"type":"Data"}]},"Summary":{"ColData":[{"value":'+
            '"Total Asset Management Fee Income"},{"value":"114057.01"}]},"type":"Section"},{"Header":{"ColData":[{"value":"Fee Income","id":"70"},{"value":""}]},"Rows":{"Row":'+
            '[{"ColData":[{"value":"ACP","id":"71"},{"value":"300.00"}],"type":"Data"},{"ColData":[{"value":"CRT","id":"72"},{"value":"158.63"}],"type":"Data"},{"ColData":'+
            '[{"value":"Tax Services","id":"75"},{"value":"2900.00"}],"type":"Data"},{"ColData":[{"value":"Trust Income - Personal","id":"182"},{"value":"140.00"}],"type":'+
            '"Data"}]},"Summary":{"ColData":[{"value":"Total Fee Income"},{"value":"3558.63"}]},"type":"Section"},{"Header":{"ColData":[{"value":"Investment Income","id":"47"},'+
            '{"value":"2.02"}]},"Rows":{"Row":[{"ColData":[{"value":"Interest Income","id":"68"},{"value":"18.14"}],"type":"Data"}]},"Summary":{"ColData":'+
            '[{"value":"Total Investment Income"},{"value":"21.16"}]},"type":"Section"},{"ColData":[{"value":"Misc. Deposits Refunds","id":"118"},{"value":"13.19"}],"type":'+
            '"Data"}]},"Summary":{"ColData":[{"value":"Total Income"},{"value":"1177.99"}]},"type":"Section","group":"Income"},{"Summary":{"ColData":[{"value":"Gross Profit"},'+
            '{"value":"1277.99"}]},"type":"Section","group":"GrossProfit"},{"Header":{"ColData":[{"value":"Expenses"},{"value":""}]},"Rows":{"Row":[{"Header":{"ColData":[{"value":'+
            '"Auto Expenses","id":"76"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Auto Allowance","id":"77"},{"value":"180.00"}],"type":"Data"},{"ColData":[{"value":'+
            '"Mileage Reimbursement","id":"78"},{"value":"321.28"}],"type":"Data"},{"ColData":[{"value":"Parking","id":"142"},{"value":"321.40"}],"type":"Data"}]},"Summary":'+
            '{"ColData":[{"value":"Total Auto Expenses"},{"value":"545.68"}]},"type":"Section"},{"ColData":[{"value":"Bank Service Charges","id":"31"},{"value":"30.93"}],"type":'+
            '"Data"},{"ColData":[{"value":"Client Fees Paid","id":"141"},{"value":"10132.56"}],"type":"Data"},{"ColData":[{"value":"Compliance Expense","id":"80"},{"value":'+
            '"21471.27"}],"type":"Data"},{"Header":{"ColData":[{"value":"Consulting Expense","id":"81"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":'+
            '"Echelon Partners - Valuation","id":"83"},{"value":"216.46"}],"type":"Data"},{"ColData":[{"value":"Resources for Leading","id":"228"},{"value":"590.33"}],'+
            '"type":"Data"},{"ColData":[{"value":"Zero Alpha Group","id":"84"},{"value":"5723.40"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Consulting Expense"},'+
            '{"value":"130630.19"}]},"type":"Section"},{"Header":{"ColData":[{"value":"Corporate Taxes","id":"85"},{"value":""}]},"Rows":{"Row":[{"ColData":'+
            '[{"value":"Sales & Use Tax","id":"87"},{"value":"91.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Corporate Taxes"},{"value":"91.00"}]},"type":'+
            '"Section"},{"ColData":[{"value":"Depreciation Expense","id":"32"},{"value":"883.52"}],"type":"Data"},{"ColData":[{"value":"Dues and Subscriptions","id":"33"},'+
            '{"value":"3679.00"}],"type":"Data"},{"Header":{"ColData":[{"value":"Insurance Expense","id":"34"},{"value":"12151.00"}]},"Rows":{"Row":[{"ColData":[{"value":'+
            '"Employment Practices","id":"164"},{"value":"229.00"}],"type":"Data"},{"ColData":[{"value":"Professional Liability","id":"134"},{"value":"3669.70"}],"type":"Data"},'+
            '{"ColData":[{"value":"Work Comp","id":"168"},{"value":"248.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Insurance Expense"},{"value":"5317.70"}]},"type":'+
            '"Section"},{"ColData":[{"value":"Interest Expense","id":"35"},{"value":"218.76"}],"type":"Data"},{"ColData":[{"value":"Legal & Professional Fees","id":"39"},{"value":'+
            '"6720.40"}],"type":"Data"},{"Header":{"ColData":[{"value":"Marketing Expense","id":"1"},{"value":""}]},"Rows":{"Row":[{"ColData":'+
            '[{"value":"Advertising / Public Relations","id":"2"},{"value":"609.13"}],"type":"Data"},{"ColData":[{"value":"Carlson Trust","id":"4"},{"value":"400.00"}],"type":'+
            '"Data"},{"Header":{"ColData":[{"value":"Charitable Contributions","id":"79"},{"value":"10551.83"}]},"Rows":{"Row":[{"ColData":[{"value":"Colleague  Board Support","id":'+
            '"231"},{"value":"1250.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Charitable Contributions"},{"value":"11801.83"}]},"type":"Section"},{"ColData":'+
            '[{"value":"Client Appreciation","id":"135"},{"value":"143.83"}],"type":"Data"},{"ColData":[{"value":"Client Recognition - Advisor Fund","id":"3"},{"value":'+
            '"225.87"}],"type":"Data"},{"ColData":[{"value":"Consultants/Contractors","id":"5"},{"value":"3100.00"}],"type":"Data"},{"ColData":[{"value":"Events","id":"6"},'+
            '{"value":"596.17"}],"type":"Data"},{"ColData":[{"value":"Printing & Design","id":"7"},{"value":"23793.49"}],"type":"Data"},{"ColData":[{"value":"Sponsorships","id":"8"},'+
            '{"value":"354.71"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Marketing Expense"},{"value":"2475.03"}]},"type":"Section"},{"Header":{"ColData":[{"value":'+
            '"Meals and Entertainment","id":"36"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Meals & Ent - 100%","id":"113"},{"value":"167.65"}],"type":"Data"},'+
            '{"ColData":[{"value":"Meals & Ent - 50%","id":"105"},{"value":"390.81"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Meals and Entertainment"},{"value":'+
            '"488.46"}]},"type":"Section"},{"ColData":[{"value":"Miscellaneous Expense","id":"25"},{"value":"41.09"}],"type":"Data"},{"Header":{"ColData":[{"value":'+
            '"Occupancy Costs","id":"12"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Maintenance, Repairs & Cleaning","id":"11"},{"value":"286.77"}],"type":"Data"},'+
            '{"ColData":[{"value":"Rent - Bloomington","id":"16"},{"value":"379.10"}],"type":"Data"},{"ColData":[{"value":"Rent - Hastings","id":"13"},{"value":"978.08"}],"type":'+
            '"Data"},{"ColData":[{"value":"Rent - Northfield","id":"14"},{"value":"1092.00"}],"type":"Data"},{"ColData":[{"value":"Rent - Rochester","id":"15"},{"value":'+
            '"104939.67"}],"type":"Data"},{"ColData":[{"value":"Rent - ViaForte","id":"197"},{"value":"-120.00"}],"type":"Data"},{"ColData":[{"value":"Utilities","id":"109"}'+
            ',{"value":"1140.52"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Occupancy Costs"},{"value":"404306.14"}]},"type":"Section"},{"Header":{"ColData":'+
            '[{"value":"Office Expense","id":"9"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Maintenance Agreements","id":"28"},{"value":"64.73"}],"type":"Data"},'+
            '{"ColData":[{"value":"Montana Supplies & Office Expense Reimb","id":"144"},{"value":"275.00"}],"type":"Data"},{"ColData":[{"value":"Office Supplies","id":"37"},{"value":'+
            '"25707.48"}],"type":"Data"},{"ColData":[{"value":"Postage and Freight","id":"38"},{"value":"2112.09"}],"type":"Data"}]},"Summary":{"ColData":'+
            '[{"value":"Total Office Expense"},{"value":"55786.30"}]},"type":"Section"},{"Header":{"ColData":[{"value":"Payroll - Wages & Salaries","id":"89"},{"value":""}]}'+
            ',"Rows":{"Row":[{"ColData":[{"value":"Administration (#200)","id":"90"},{"value":"3580.75"}],"type":"Data"},{"ColData":[{"value":"Administrative Support - ViaForte"'+
            ',"id":"199"},{"value":"-12000.00"}],"type":"Data"},{"ColData":[{"value":"Advisors & Planners (#400)","id":"94"},{"value":"13943.91"}],"type":"Data"},{"ColData":'+
            '[{"value":"Bonus - Membership Grants","id":"154"},{"value":"610.00"}],"type":"Data"},{"ColData":[{"value":"Consulting - ViaForte","id":"200"},{"value":"-660.00"}],'+
            '"type":"Data"},{"ColData":[{"value":"Finance (#1100)","id":"224"},{"value":"1500.00"}],"type":"Data"},{"ColData":[{"value":"Human Resources (#500)","id":"158"},'+
            '{"value":"2620.04"}],"type":"Data"},{"ColData":[{"value":"Investments (#700)","id":"155"},{"value":"246.96"}],"type":"Data"},{"ColData":[{"value":"Marketing (#300)",'+
            '"id":"156"},{"value":"1377.92"}],"type":"Data"},{"ColData":[{"value":"Part-Time staff","id":"93"},{"value":"188.00"}],"type":"Data"},{"ColData":[{"value":'+
            '"Payroll/Consultants","id":"185"},{"value":"165.00"}],"type":"Data"},{"ColData":[{"value":"Principals (#100)","id":"91"},{"value":"998.00"}],"type":"Data"},'+
            '{"ColData":[{"value":"Referral Bonus","id":"195"},{"value":"3374.09"}],"type":"Data"},{"ColData":[{"value":"Tax (#900)","id":"157"},{"value":"3301.13"}],"type":'+
            '"Data"},{"ColData":[{"value":"Tech/Ops (#800)","id":"92"},{"value":"2722.08"}],"type":"Data"},{"ColData":[{"value":"Year End Bonus","id":"174"},{"value":'+
            '"1048476.28"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Payroll - Wages & Salaries"},{"value":"52764.16"}]},"type":"Section"},{"Header":{"ColData":'+
            '[{"value":"Payroll Benefits","id":"100"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"401(k) Employer Expense","id":"101"},{"value":"386309.44"}],"type":'+
            '"Data"},{"ColData":[{"value":"Child Support/Maint","id":"152"},{"value":"0.00"}],"type":"Data"},{"ColData":[{"value":"Continuing Education","id":"103"},{"value":'+
            '"9537.00"}],"type":"Data"},{"ColData":[{"value":"Dental/Vision","id":"153"},{"value":"2321.05"}],"type":"Data"},{"ColData":[{"value":"Disability Insurance","id":'+
            '"108"},{"value":"1303.65"}],"type":"Data"},{"ColData":[{"value":"Employee Appreciation","id":"104"},{"value":"1051.15"}],"type":"Data"},{"ColData":[{"value":'+
            '"FSA","id":"163"},{"value":"2203.55"}],"type":"Data"},{"ColData":[{"value":"Group Life Ins & AD/D","id":"225"},{"value":"47.16"}],"type":"Data"},{"ColData":[{"value":'+
            '"HSA","id":"160"},{"value":"32773.47"}],"type":"Data"},{"ColData":[{"value":"Medical Insurance","id":"102"},{"value":"27477.79"}],"type":"Data"}]},"Summary":'+
            '{"ColData":[{"value":"Total Payroll Benefits"},{"value":"7824.26"}]},"type":"Section"},{"ColData":[{"value":"Payroll Preparation and Administration","id":"145"},'+
            '{"value":"8172.25"}],"type":"Data"},{"Header":{"ColData":[{"value":"Payroll Tax Expenses (ER PAID)","id":"42"},{"value":"45.86"}]},"Rows":{"Row":[{"ColData":[{"value":'+
            '"Federal Unemployment","id":"98"},{"value":"1729.71"}],"type":"Data"},{"ColData":[{"value":"Medicare","id":"96"},{"value":"7517.98"}],"type":"Data"},{"ColData"'+
            ':[{"value":"MN State Unemployment","id":"99"},{"value":"2281.43"}],"type":"Data"},{"ColData":[{"value":"MN Work Enhan","id":"165"},{"value":"1006.44"}],"type":"Data"}'+
            ',{"ColData":[{"value":"MT Adm Fund","id":"193"},{"value":"56.52"}],"type":"Data"},{"ColData":[{"value":"MT Unemployment","id":"192"},{"value":"314.00"}],"type":"Data"}'+
            ',{"ColData":[{"value":"NE Unemployment","id":"237"},{"value":"143.88"}],"type":"Data"},{"ColData":[{"value":"Social Security","id":"97"},{"value":"22814.34"}],"type":'+
            '"Data"}]},"Summary":{"ColData":[{"value":"Total Payroll Tax Expenses (ER PAID)"},{"value":"30910.16"}]},"type":"Section"},{"ColData":[{"value":'+
            '"Professional Fees & License","id":"111"},{"value":"26852.78"}],"type":"Data"},{"ColData":[{"value":"Publications and Books","id":"133"},{"value":"2809.71"}],"type":'+
            '"Data"},{"ColData":[{"value":"Recruiting Expenses","id":"143"},{"value":"665.20"}],"type":"Data"},{"ColData":[{"value":"Revenue Sharing","id":"88"},{"value":'+
            '"41143.37"}],"type":"Data"},{"Header":{"ColData":[{"value":"Technology Expense","id":"17"},{"value":""}]},"Rows":{"Row":[{"ColData":[{"value":"Cellular Phones",'+
            '"id":"18"},{"value":"9031.56"}],"type":"Data"},{"ColData":[{"value":"Consulting","id":"19"},{"value":"512.50"}],"type":"Data"},{"ColData":[{"value":'+
            '"Internet / Data","id":"20"},{"value":"838.10"}],"type":"Data"},{"ColData":[{"value":"Service Calls/Repairs","id":"229"},{"value":"458.47"}],"type":"Data"}'+
            ',{"ColData":[{"value":"Software Services & Support","id":"21"},{"value":"237261.52"}],"type":"Data"},{"ColData":[{"value":"Supplies","id":"22"},{"value":"22752.28"}]'+
            ',"type":"Data"},{"ColData":[{"value":"Technology - ViaForte","id":"198"},{"value":"-120.00"}],"type":"Data"},{"ColData":[{"value":"Web Site","id":"23"},{"value":'+
            '"200.00"}],"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Technology Expense"},{"value":"404.43"}]},"type":"Section"},{"Header":{"ColData":[{"value":'+
            '"Travel Expense","id":"40"},{"value":"295.86"}]},"Rows":{"Row":[{"ColData":[{"value":"Greg Carlson Travel","id":"202"},{"value":"8773.94"}],"type":"Data"},'+
            '{"ColData":[{"value":"Jeff Carlson Travel","id":"203"},{"value":"17341.19"}],"type":"Data"},{"ColData":[{"value":"Justin Stets Travel","id":"204"},{"value":"166.10"}]'+
            ',"type":"Data"}]},"Summary":{"ColData":[{"value":"Total Travel Expense"},{"value":"677.09"}]},"type":"Section"}]},"Summary":{"ColData":[{"value":"Total Expenses"}'+
            ',{"value":"8097.44"}]},"type":"Section","group":"Expenses"},{"Summary":{"ColData":[{"value":"Net Operating Income"},{"value":"3780.55"}]},"type":"Section",'+
            '"group":"NetOperatingIncome"},{"Summary":{"ColData":[{"value":"Net Income"},{"value":"3780.55"}]},"type":"Section","group":"NetIncome"}]}}';
    }
    
    private static String getSmartSheetColumns() {
        return '{"pageNumber":1,"totalPages":1,"totalCount":128,"data":[{"id":90588386224004,"index":0,"title":"Notes","type":"TEXT_NUMBER","primary":true,"validation":false,'+
            '"width":56},{"id":4594188013594500,"index":1,"title":"Company","type":"PICKLIST","options":["BHWM","CCM","Foster","PH","PlanCorp","RCG","Savant","TCI"],"validation":'+
            'false,"width":104},{"id":2342388199909252,"index":2,"title":"Year","type":"PICKLIST","options":["2015","2016","2017"],"validation":false,"width":65},{"id":'+
            '6845987827279748,"index":3,"title":"Quarter","type":"PICKLIST","options":["1","2","3","4","5"],"validation":false,"width":62},{"id":1216488293066628,"index":4,'+
            '"title":"Label","type":"TEXT_NUMBER","validation":false,"width":108},{"id":5720087920437124,"index":5,"title":"New AUM","type":"TEXT_NUMBER","validation":false,'+
            '"width":87},{"id":3468288106751876,"index":6,"title":"Total Revenue","type":"TEXT_NUMBER","validation":false,"width":106},{"id":7971887734122372,"index":7,"title":'+
            '"Direct Expense","type":"TEXT_NUMBER","validation":false,"width":105},{"id":653538339645316,"index":8,"title":"Overhead Expense","type":"TEXT_NUMBER","validation":'+
            'false,"width":83},{"id":5157137967015812,"index":9,"title":"Direct Client Impact Team Members FTE","type":"TEXT_NUMBER","validation":false,"width":107},{"id":'+
            '2905338153330564,"index":10,"title":"Total Team Members FTE","type":"TEXT_NUMBER","validation":false,"width":94},{"id":7408937780701060,"index":11,"title":'+
            '"Ending Number of Billed Relationships","type":"TEXT_NUMBER","validation":false,"width":79},{"id":1779438246487940,"index":12,"title":'+
            '"Revenue per Direct Client Impact Team Member FTE","type":"TEXT_NUMBER","validation":false,"width":80},{"id":6283037873858436,"index":13,"title":'+
            '"Revenue per Team Member FTE","type":"TEXT_NUMBER","validation":false,"width":108},{"id":4031238060173188,"index":14,"title":"Revenue per Billed Relationship",'+
            '"type":"TEXT_NUMBER","validation":false,"width":103},{"id":8534837687543684,"index":15,"title":"AUM per Billed Relationship","type":"TEXT_NUMBER","validation":'+
            'false,"width":71},{"id":372063362934660,"index":16,"title":"Billed Relationships per Direct Client Impact Tea","type":"TEXT_NUMBER","validation":false,"width":'+
            '102},{"id":4875662990305156,"index":17,"title":"Billed Relationships per Team Member FTE","type":"TEXT_NUMBER","validation":false,"width":90},{"id":2623863176619908,'+
            '"index":18,"title":"Billable AUM","type":"TEXT_NUMBER","validation":false,"width":134},{"id":7127462803990404,"index":19,"title":"Number of Billed Relationships - New",'+
            '"type":"TEXT_NUMBER","validation":false,"width":81},{"id":1497963269777284,"index":20,"title":"Number of Billed Relationships - Lost","type":"TEXT_NUMBER","validation":'+
            'false,"width":92},{"id":6001562897147780,"index":21,"title":"Ending Number of Billed Accounts","type":"TEXT_NUMBER","validation":false,"width":98},{"id":'+
            '3749763083462532,"index":22,"title":"Median Billed Relationship - AUM","type":"TEXT_NUMBER","validation":false,"width":89},{"id":8253362710833028,"index":23,'+
            '"title":"Median New Billed Relationship - AUM","type":"TEXT_NUMBER","validation":false,"width":79},{"id":935013316355972,"index":24,"title":'+
            '"New Billed Relationships - AUM","type":"TEXT_NUMBER","validation":false,"width":96},{"id":5438612943726468,"index":25,"title":"New Acquisition - AUM","type":'+
            '"TEXT_NUMBER","validation":false,"width":150},{"id":3186813130041220,"index":26,"title":"Transfers In - Current Billed Relationships - AUM","type":"TEXT_NUMBER",'+
            '"validation":false,"width":83},{"id":7690412757411716,"index":27,"title":"Lost Billed Relationships - AUM","type":"TEXT_NUMBER","validation":false,"width":103},{"id":'+
            '2060913223198596,"index":28,"title":"Withdrawals - Current Billed Relationships - AUM","type":"TEXT_NUMBER","validation":false,"width":93},{"id":6564512850569092,'+
            '"index":29,"title":"Net New AUM","type":"TEXT_NUMBER","validation":false,"width":87},{"id":4312713036883844,"index":30,"title":'+
            '"Market Increase (Decrease) on AUM for Current Qua","type":"TEXT_NUMBER","validation":false,"width":82},{"id":8816312664254340,"index":31,"title":'+
            '"% of AUM Growth (Net) Excluding Market Impact","type":"TEXT_NUMBER","validation":false,"width":91},{"id":231325874579332,"index":32,"title":'+
            '"Average Billed Relationship Size","type":"TEXT_NUMBER","validation":false,"width":84},{"id":4734925501949828,"index":33,"title":'+
            '"Average New Billed Relationship - AUM","type":"TEXT_NUMBER","validation":false,"width":79},{"id":2483125688264580,"index":34,"title":'+
            '"Average Fee Percentage for AUM Revenue Only","type":"TEXT_NUMBER","validation":false,"width":97},{"id":6986725315635076,"index":35,"title":"Total Revenue- Annual",'+
            '"type":"TEXT_NUMBER","validation":false,"width":150},{"id":1357225781421956,"index":36,"title":"AUM Revenue","type":"TEXT_NUMBER","validation":false,"width":72},{"id":'+
            '5860825408792452,"index":37,"title":"Non-AUM Revenue","type":"TEXT_NUMBER","validation":false,"width":84},{"id":3609025595107204,"index":38,"title":"Gross Profit",'+
            '"type":"TEXT_NUMBER","validation":false,"width":51},{"id":8112625222477700,"index":39,"title":"Operating Income","type":"TEXT_NUMBER","validation":false,"width":149},'+
            '{"id":794275828000644,"index":40,"title":"Other Income","type":"TEXT_NUMBER","validation":false,"width":55},{"id":5297875455371140,"index":41,"title":"Other Expense","type"'+
            ':"TEXT_NUMBER","validation":false,"width":65},{"id":3046075641685892,"index":42,"title":"Pre-Tax Net Income","type":"TEXT_NUMBER","validation":false,"width":51},{"id":'+
            '7549675269056388,"index":43,"title":"Income Taxes","type":"TEXT_NUMBER","validation":false,"width":51},{"id":1920175734843268,"index":44,"title":"Net Income","type":'+
            '"TEXT_NUMBER","validation":false,"width":90},{"id":6423775362213764,"index":45,"title":"% of Revenue","type":"TEXT_NUMBER","validation":false,"width":150},{"id":'+
            '4171975548528516,"index":46,"title":"Owner Direct Client Impact Compensation","type":"TEXT_NUMBER","validation":false,"width":102},{"id":8675575175899012,"index":47,'+
            '"title":"Non-Owner Direct Client Impact Compensation","type":"TEXT_NUMBER","validation":false,"width":85},{"id":512800851289988,"index":48,"title":'+
            '"Total Direct Expense Compensation","type":"TEXT_NUMBER","validation":false,"width":100},{"id":5016400478660484,"index":49,"title":"Owner Management Compensation",'+
            '"type":"TEXT_NUMBER","validation":false,"width":149},{"id":2764600664975236,"index":50,"title":"Non-Owner Management Compensation","type":"TEXT_NUMBER","validation":'+
            'false,"width":117},{"id":7268200292345732,"index":51,"title":"Operations Team Members Compensation","type":"TEXT_NUMBER","validation":false,"width":130},{"id":'+
            '1638700758132612,"index":52,"title":"Administrative Team Members Compensation","type":"TEXT_NUMBER","validation":false,"width":113},{"id":6142300385503108,"index":53,'+
            '"title":"Other Team Member Compensation","type":"TEXT_NUMBER","validation":false,"width":85},{"id":3890500571817860,"index":54,"title":"Total Overhead Compensation",'+
            '"type":"TEXT_NUMBER","validation":false,"width":115},{"id":8394100199188356,"index":55,"title":"Total Compensation","type":"TEXT_NUMBER","validation":false,"width":97},'+
            '{"id":1075750804711300,"index":56,"title":"Owner Benefits","type":"TEXT_NUMBER","validation":false,"width":144},{"id":5579350432081796,"index":57,"title":'+
            '"Non-Owner Benefts","type":"TEXT_NUMBER","validation":false,"width":146},{"id":3327550618396548,"index":58,"title":"Total Benefits","type":"TEXT_NUMBER","validation":'+
            'false,"width":71},{"id":7831150245767044,"index":59,"title":"Revenue per Team Member","type":"TEXT_NUMBER","validation":false,"width":119},{"id":2201650711553924,'+
            '"index":60,"title":"Benefits as a % of Total Compensation","type":"TEXT_NUMBER","validation":false,"width":110},{"id":6705250338924420,"index":61,"title":'+
            '"Benefits per Team Member FTE","type":"TEXT_NUMBER","validation":false,"width":73},{"id":4453450525239172,"index":62,"title":"Benefits per Team Member","type":'+
            '"TEXT_NUMBER","validation":false,"width":87},{"id":8957050152609668,"index":63,"title":"Profit per Team Member FTE","type":"TEXT_NUMBER","validation":false,"width":'+
            '142},{"id":55404014135172,"index":64,"title":"Profit per Direct Client Impact Team Member FTE","type":"TEXT_NUMBER","validation":false,"width":51},{"id":'+
            '4559003641505668,"index":65,"title":"Profit per Billed Relationship","type":"TEXT_NUMBER","validation":false,"width":144},{"id":2307203827820420,"index":66,"title":'+
            '"Billed Relationships per Team Member","type":"TEXT_NUMBER","validation":false,"width":82},{"id":6810803455190916,"index":67,"title":"Discretionary","type":'+
            '"TEXT_NUMBER","validation":false,"width":113},{"id":1181303920977796,"index":68,"title":"Non-Discretionary","type":"TEXT_NUMBER","validation":false,"width":72},'+
            '{"id":5684903548348292,"index":69,"title":"Planning and Consulting Fees","type":"TEXT_NUMBER","validation":false,"width":119},{"id":3433103734663044,"index":70,"title":'+
            '"Retainer Fees","type":"TEXT_NUMBER","validation":false,"width":87},{"id":7936703362033540,"index":71,"title":"Securities Commissions-Current","type":"TEXT_NUMBER",'+
            '"validation":false,"width":51},{"id":618353967556484,"index":72,"title":"Securities Trails","type":"TEXT_NUMBER","validation":false,"width":51},{"id":5121953594926980,'+
            '"index":73,"title":"Insurance Commissions-New or First Year","type":"TEXT_NUMBER","validation":false,"width":51},{"id":2870153781241732,"index":74,"title":'+
            '"Insurance Renewals","type":"TEXT_NUMBER","validation":false,"width":51},{"id":7373753408612228,"index":75,"title":"Other Fees","type":"TEXT_NUMBER","validation":'+
            'false,"width":69},{"id":1744253874399108,"index":76,"title":"Commissions Paid to Outside Reps or Referral Fees","type":"TEXT_NUMBER","validation":false,"width":94},'+
            '{"id":6247853501769604,"index":77,"title":"Benefits - Owner","type":"TEXT_NUMBER","validation":false,"width":51},{"id":3996053688084356,"index":78,"title":'+
            '"Benefits - Non-Owner Client Impact Team Members","type":"TEXT_NUMBER","validation":false,"width":111},{"id":8499653315454852,"index":79,"title":'+
            '"Benefits - Non-Owner Management Team","type":"TEXT_NUMBER","validation":false,"width":81},{"id":336878990845828,"index":80,"title":"Benefits - Operations","type":'+
            '"TEXT_NUMBER","validation":false,"width":97},{"id":4840478618216324,"index":81,"title":"Benefits - Administration","type":"TEXT_NUMBER","validation":false,"width":96},'+
            '{"id":2588678804531076,"index":82,"title":"Benefits - Other Team Members","type":"TEXT_NUMBER","validation":false,"width":104},{"id":7092278431901572,"index":83,"title":'+
            '"Total Expenses","type":"TEXT_NUMBER","validation":false,"width":150},{"id":1462778897688452,"index":84,"title":"Advertising/Public Relations/Marketing","type":'+
            '"TEXT_NUMBER","validation":false,"width":162},{"id":5966378525058948,"index":85,"title":"Auto Expenses","type":"TEXT_NUMBER","validation":false,"width":94},{"id":'+
            '3714578711373700,"index":86,"title":"Charitable Contributions","type":"TEXT_NUMBER","validation":false,"width":106},{"id":8218178338744196,"index":87,"title":'+
            '"Client Appreciation","type":"TEXT_NUMBER","validation":false,"width":115},{"id":899828944267140,"index":88,"title":"Depreciation/Amortization","type":"TEXT_NUMBER",'+
            '"validation":false,"width":171},{"id":5403428571637636,"index":89,"title":"Dues - Clubs","type":"TEXT_NUMBER","validation":false,"width":93},{"id":3151628757952388,'+
            '"index":90,"title":"Dues - Professional","type":"TEXT_NUMBER","validation":false,"width":116},{"id":7655228385322884,"index":91,"title":"Equipment Leases/Purchases",'+
            '"type":"TEXT_NUMBER","validation":false,"width":136},{"id":2025728851109764,"index":92,"title":"Insurance","type":"TEXT_NUMBER","validation":false,"width":96},{"id":'+
            '6529328478480260,"index":93,"title":"Office Expense","type":"TEXT_NUMBER","validation":false,"width":90},{"id":4277528664795012,"index":94,"title":"Payroll Taxes",'+
            '"type":"TEXT_NUMBER","validation":false,"width":92},{"id":8781128292165508,"index":95,"title":"Professional Services","type":"TEXT_NUMBER","validation":false,"width":'+
            '95},{"id":196141502490500,"index":96,"title":"Rent","type":"TEXT_NUMBER","validation":false,"width":77},{"id":4699741129860996,"index":97,"title":'+
            '"Repairs and Maintenance","type":"TEXT_NUMBER","validation":false,"width":93},{"id":2447941316175748,"index":98,"title":"Software/Hardware Expense","type":'+
            '"TEXT_NUMBER","validation":false,"width":131},{"id":6951540943546244,"index":99,"title":"Tax and Licenses","type":"TEXT_NUMBER","validation":false,"width":88},{"id":'+
            '1322041409333124,"index":100,"title":"Travel and Entertainment","type":"TEXT_NUMBER","validation":false,"width":189},{"id":5825641036703620,"index":101,"title":'+
            '"Training and Continuing Education","type":"TEXT_NUMBER","validation":false,"width":90},{"id":3573841223018372,"index":102,"title":"Utilities/Phone/Fax/Online service",'+
            '"type":"TEXT_NUMBER","validation":false,"width":181},{"id":8077440850388868,"index":103,"title":"All Other Expenses","type":"TEXT_NUMBER","validation":false,"width":89}'+
            ',{"id":759091455911812,"index":104,"title":"Goal-Gross New Client Billed AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":5262691083282308,"index":105,'+
            '"title":"Goal-Lost Client AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":3010891269597060,"index":106,"title":"Goal-Net New Client Billed AUM","type":'+
            '"TEXT_NUMBER","validation":false,"width":150},{"id":7514490896967556,"index":107,"title":"Goal-Existing Client Deposits AUM","type":"TEXT_NUMBER","validation":false,'+
            '"width":150},{"id":1884991362754436,"index":108,"title":"Goal-Existing Client Withdrawals AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":'+
            '6388590990124932,"index":109,"title":"Goal- Net Existing Client New AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":4136791176439684,"index":110,'+
            '"title":"Goal-New Clients","type":"TEXT_NUMBER","validation":false,"width":150},{"id":8640390803810180,"index":111,"title":"Goal-Lost Clients","type":"TEXT_NUMBER",'+
            '"validation":false,"width":150},{"id":477616479201156,"index":112,"title":"Goal-Net New Clients","type":"TEXT_NUMBER","validation":false,"width":150},{"id":'+
            '4981216106571652,"index":113,"title":"Goal-Year-over-year revenue growth","type":"TEXT_NUMBER","validation":false,"width":150},{"id":2729416292886404,"index":114,'+
            '"title":"Average Client Age","type":"TEXT_NUMBER","validation":false,"width":150},{"id":7233015920256900,"index":115,"title":"Median Client age","type":"TEXT_NUMBER",'+
            '"validation":false,"width":150},{"id":1603516386043780,"index":116,"title":"Retired client %","type":"TEXT_NUMBER","validation":false,"width":150},{"id":'+
            '6107116013414276,"index":117,"title":"Retirees as % of AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":3855316199729028,"index":118,"title":'+
            '"Annual Goal 1","type":"TEXT_NUMBER","validation":false,"width":150},{"id":8358915827099524,"index":119,"title":"Annual Goal 2","type":"TEXT_NUMBER","validation":'+
            'false,"width":150},{"id":1040566432622468,"index":120,"title":"Annual Goal 3","type":"TEXT_NUMBER","validation":false,"width":150},{"id":5544166059992964,"index":121,'+
            '"title":"Annual Goal 4","type":"TEXT_NUMBER","validation":false,"width":150},{"id":3292366246307716,"index":122,"title":"New AUM % of Total AUM","type":"TEXT_NUMBER",'+
            '"validation":false,"width":150},{"id":7795965873678212,"index":123,"title":"New Billed AUM % of Total AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":'+
            '2166466339465092,"index":124,"title":"Transfer In AUM % of Total AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":6670065966835588,"index":125,"title":'+
            '"Withdrawals AUM % of Total AUM","type":"TEXT_NUMBER","validation":false,"width":150},{"id":4418266153150340,"index":126,"title":"Lost AUM % of Total AUM","type":'+
            '"TEXT_NUMBER","validation":false,"width":150},{"id":8921865780520836,"index":127,"title":"Net New AUM % of Total AUM","type":"TEXT_NUMBER","validation":false,"width":'+
            '150}]}';
    }
    
    private static String getNetDocsNameChangeSuccess(){
        return '{"count":1}';
    }
    
    private static String genericSuccess() {
        return '{"message":"SUCCESS"}';
    }
    
    private static String genericFailure() {
        return '{"message":"FAILURE"}';
    }

    private static String getTokenErrorTestResponse() {
        return '{"error":"Token has expired or is invalid"}';
    }   

    private static String getTokenSuccessTestResponse() {
        return '{"access_token":"dummytoken","refresh_token":"dummytoken", "expires_in":"3600"}';
    }

    private static String getLongTokenSuccessTestResponse() {
        return '{"access_token":"dummytokenwithmorethan255characters11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111","refresh_token":"dummytoken"}';
    }
}