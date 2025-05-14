/**
 * @description : Controller for MeetingNotesPDF VF Page
 * @testClass : MeetingNotesPDFControllerTest
 *
 * @author Matthew J Lennington -- (Demand Chain)
 * @date 2024-09-27
 *
 * 12.20.2024   Sophia Murphy (Demand Chain)
 *              Updated to allow a theme to be passed in; and we show all of the same theme.
 * 01.21.2025   Sophia Murphy (Demand Chain)
 *              Added in meeting frequencies, etc
 *
*/
public with sharing class MeetingNotesPDFController {

    public Id householdId {get; set;}
    public String householdName {get; set;}
    public String themeName { get; set;}

    public Map<String, Date> nextMeetingMap { get; set; }
    public Map<String, Date> lastMeetingMap { get; set; }
    public Map<String, String> frequencyMeetingMap { get; set; }

    public Map<String, String> accountTeamMemberMap { get; set; }

    public boolean pageErrors {get; set;}
    public List<Client_Meeting_Note__c> notes {get; set;}

    public String advisorName { get; set; }
    public String taxName { get; set; }
    public String paraName { get; set; }

    public MeetingNotesPDFController() {
        householdId = ApexPages.currentPage().getParameters().get('id');
        themeName = ApexPages.currentPage().getParameters().get('theme');

        nextMeetingMap = new Map<String, Date>();
        lastMeetingMap = new Map<String, Date>();
        frequencyMeetingMap = new Map<String, String>();

        advisorName = '';
        taxName = '';
        paraName = '';

        if (householdId == NULL) {
            pageErrors = True;
            system.debug('Must have a household ID for this page to generate');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must have a household ID for this page to generate'));
        } else {
            init();
        }
    }

    public MeetingNotesPDFController(ApexPages.StandardController stdController) {
        householdId = stdController.getRecord().Id;
        themeName = ApexPages.currentPage().getParameters().get('theme');

        nextMeetingMap = new Map<String, Date>();
        lastMeetingMap = new Map<String, Date>();
        frequencyMeetingMap = new Map<String, String>();

        advisorName = '';
        taxName = '';
        paraName = '';

        init();
    }


    public void init() {

        notes = getMeetings(householdId, themeName);
        Account hhRecord = getHouseHold(householdId);
        householdName = hhRecord.Name;

        for(AccountTeamMember tmr : hhRecord.AccountTeamMembers) {
            if(tmr.TeamMemberRole == 'Primary Advisor') {
                advisorName = tmr.User.Name;
            }
            if(tmr.TeamMemberRole == 'Tax Advisor') {
                taxName = tmr.User.Name;
            }
            if(tmr.TeamMemberRole == 'Paraplanner') {
                paraName = tmr.User.Name;
            }
        }

        //I didn't want to do each theme as it's own if - because that would make test classes more difficult - 
        // and this way -all the lines should be covered.
        //get picklist values
        Map<String, String> themeToField = new Map<String, String>();
        
        themeToField.put('Background-Next', null);
        themeToField.put('Net Worth-Next', 'Net_Worth_Next_Meeting__c');
        themeToField.put('Investment-Next', 'Investment_Next_Meeting__c');
        themeToField.put('Cash Flow-Next', 'Cash_Flow_Next_Meeting__c');
        themeToField.put('Retirement Planning-Next', 'Retirement_Planning_Next_Meeting__c');
        themeToField.put('Tax Planning-Next', 'Tax_Planning_Next_Meeting__c');
        themeToField.put('Risk Management-Next', 'Risk_Management_Next_Meeting__c');
        themeToField.put('Charitable Planning-Next', 'Charitable_Planning_Next_Meeting__c');
        themeToField.put('Education Planning-Next', 'Education_Planning_Next_Meeting__c');
        themeToField.put('Estate Planning-Next', 'Estate_Planning_Next_Meeting__c');

        themeToField.put('Background-Last', null);
        themeToField.put('Net Worth-Last', 'Net_Worth_Last_Meeting__c');
        themeToField.put('Investment-Last', 'Investment_Last_Meeting__c');
        themeToField.put('Cash Flow-Last', 'Cash_Flow_Last_Meeting__c');
        themeToField.put('Retirement Planning-Last', 'Retirement_Planning_Last_Meeting__c');
        themeToField.put('Tax Planning-Last', 'Tax_Planning_Last_Meeting__c');
        themeToField.put('Risk Management-Last', 'Risk_Management_Last_Meeting__c');
        themeToField.put('Charitable Planning-Last', 'Charitable_Planning_Last_Meeting__c');
        themeToField.put('Education Planning-Last', 'Education_Planning_Last_Meeting__c');
        themeToField.put('Estate Planning-Last', 'Estate_Planning_Last_Meeting__c');

        themeToField.put('Background-Frequency', null);
        themeToField.put('Net Worth-Frequency', 'Net_Worth_Frequency__c');
        themeToField.put('Investment-Frequency', 'Investment_Frequency__c');
        themeToField.put('Cash Flow-Frequency', 'Cash_Flow_Frequency__c');
        themeToField.put('Retirement Planning-Frequency', 'Retirement_Planning_Frequency__c');
        themeToField.put('Tax Planning-Frequency', 'Tax_Planning_Frequency__c');
        themeToField.put('Risk Management-Frequency', 'Risk_Management_Frequency__c');
        themeToField.put('Charitable Planning-Frequency', 'Charitable_Planning_Frequency__c');
        themeToField.put('Education Planning-Frequency', 'Education_Planning_Frequency__c');
        themeToField.put('Estate Planning-Frequency', 'Estate_Planning_Frequency__c');

        Set<String> meetingThemes = getPicklistValues('Client_Meeting_Note__c', 'Meeting_Theme__c');
        system.debug('DC: meetingThemes: ' + meetingThemes);

        for(String mtgTheme : meetingThemes) {
            String nextMtgField = themeToField.get(mtgTheme + '-Next');
            String lastMtgField = themeToField.get(mtgTheme + '-Last');
            String freqField = themeToField.get(mtgTheme + '-Frequency');

            //Fill them all with dummy values...
            nextMeetingMap.put(mtgTheme, Date.newInstance(1900,1,1));
            lastMeetingMap.put(mtgTheme, Date.newInstance(1900,1,1));
            frequencyMeetingMap.put(mtgTheme, '');

            if(nextMtgField != null) {
                Date tmpDate = (Date) hhRecord.get(nextMtgField);
                if(tmpDate != null) {
                    nextMeetingMap.put(mtgTheme, tmpDate);
                }
                
            }
            if(lastMtgField != null) {
                Date tmpDate = (Date) hhRecord.get(lastMtgField);
                if(tmpDate != null) {
                    lastMeetingMap.put(mtgTheme, tmpDate);
                }
            }
            if(freqField != null) {
                String tmpStr = (String) hhRecord.get(freqField);
                if(tmpStr != null) {
                    frequencyMeetingMap.put(mtgTheme, tmpStr);
                }
            }
        }
        System.debug('DC: nextMeetingMap: ' + nextMeetingMap);
        System.debug('DC: frequencyMeetingMap: ' + frequencyMeetingMap);
        
    }

    public static Account getHouseHold(Id householdId){
        return [SELECT Name, 
                Cash_Flow_Next_Meeting__c, Cash_Flow_Last_Meeting__c, Cash_Flow_Frequency__c, 
                Charitable_Planning_Next_Meeting__c, Charitable_Planning_Last_Meeting__c, Charitable_Planning_Frequency__c, 
                Education_Planning_Next_Meeting__c, Education_Planning_Last_Meeting__c, Education_Planning_Frequency__c, 
                Estate_Planning_Next_Meeting__c, Estate_Planning_Last_Meeting__c, Estate_Planning_Frequency__c, 
                Investment_Next_Meeting__c, Investment_Last_Meeting__c, Investment_Frequency__c, 
                Net_Worth_Next_Meeting__c, Net_Worth_Last_Meeting__c, Net_Worth_Frequency__c, 
                Retirement_Planning_Next_Meeting__c, Retirement_Planning_Last_Meeting__c, Retirement_Planning_Frequency__c, 
                Risk_Management_Next_Meeting__c, Risk_Management_Last_Meeting__c, Risk_Management_Frequency__c, 
                Tax_Planning_Next_Meeting__c, Tax_Planning_Last_Meeting__c, Tax_Planning_Frequency__c,
                (SELECT Id, TeamMemberRole, User.Name FROM AccountTeamMembers)
                FROM ACCOUNT WHERE Id = :householdId LIMIT 1];
    }

    
    
    // /**
    //  * @description : getMeetingsLoopedQuery returns a list of Client_Meeting_Note__c
    //  * @param householdId : Id of the Household
    //  * @return List<Client_Meeting_Note__c>
    //  *
    //  * @author Matthew J Lennington -- (Demand Chain)
    //  * @date 2024-09-27
    //  *
    // */
    // public static List<Client_Meeting_Note__c> getMeetingsLoopedQuery(Id householdId) {
    
    //     //get picklist values
    //     Set<String> meetingThemes = getPicklistValues('Client_Meeting_Note__c', 'Meeting_Theme__c');

    //     List<Client_Meeting_Note__c> result = new List<Client_Meeting_Note__c>();
    //     for(String theme : meetingThemes){
    //         List<Client_Meeting_Note__c> cmn =  [SELECT Id, Summary__c, Name,  Meeting_Theme__c, Meeting_Date_Time__c 
    //         FROM Client_Meeting_Note__c
    //         where Household__c =: householdId AND Meeting_Theme__c =: theme ORDER BY Meeting_Date_Time__c DESC LIMIT 1 ];
    //         if(!cmn.isEmpty()){
    //             result.add(cmn[0]);
    //         }
    //     }
    //     return result;
    // }

     /**
     * @description : getMeetingsLoopedQuery returns a list of Client_Meeting_Note__c
     * @param householdId : Id of the Household
     * @return List<Client_Meeting_Note__c>
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-09-27
     *
    */
    public static List<Client_Meeting_Note__c> getMeetings(Id householdId, String theme) {
    
        system.debug('DC: theme: ' + theme);
        List<Client_Meeting_Note__c> result = new List<Client_Meeting_Note__c>();
        Set<String> allThemes = getPicklistValues('Client_Meeting_Note__c', 'Meeting_Theme__c');
        
        if(theme != null) {
            //If there is a theme present, we want all notes for that single theme
            for(Client_Meeting_Note__c note : [SELECT Id, Summary__c, Name,  Meeting_Theme__c, Meeting_Date_Time__c, CreatedDate, 
                (SELECT Question__c	, Status__c, Notes__c  FROM Client_Meeting_Tasks__r WHERE Status__c != 'N/A'  order by createdDate ASC)
                    FROM Client_Meeting_Note__c 
                    WHERE Household__c =: householdId
                    AND Meeting_Theme__c =: theme
                    ORDER BY LastModifiedDate DESC]) {

                    result.add(note);
            }
        } else {
            //If no theme is added; then we just want all the LATEST meeting notes
            for(Client_Meeting_Note__c note : [SELECT Id, Summary__c, Name,  Meeting_Theme__c, Meeting_Date_Time__c, CreatedDate, 
                (SELECT Question__c	, Status__c, Notes__c  FROM Client_Meeting_Tasks__r WHERE Status__c != 'N/A'  order by createdDate ASC)
                    FROM Client_Meeting_Note__c 
                    WHERE Household__c =: householdId
                    ORDER BY Sort__c, LastModifiedDate DESC]) {
                    if(allThemes.contains(note.Meeting_Theme__c)){
                        allThemes.remove(note.Meeting_Theme__c);
                        result.add(note);
                    }
                    if(allThemes.isEmpty()){
                        break;
                    }
            }
        }
        return result;

    }

    /**
     * @description : returns a picklist 
     * 
     * @param String : objectName
     * @param String : fieldName
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-09-27
     *
    */
    public static Set<String> getPicklistValues(String objectName, String fieldName) {
        Set<String> picklistValues = new Set<String>();
        
        // Get the object describe
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
            
            // Get the field describe
            Schema.SObjectField field = objectType.getDescribe().fields.getMap().get(fieldName);
            if (field != null) {
                Schema.DescribeFieldResult fieldResult = field.getDescribe();
                //System.debug('DC: fieldResult: ' + fieldResult);
                // Get the picklist values
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    //System.debug('DC: entry: ' + entry);
                    picklistValues.add(entry.getValue());
                }
            } else {
                System.debug('Field not found: ' + fieldName);
            }
        } else {
            System.debug('Object not found: ' + objectName);
        }

        return picklistValues;
    }
}