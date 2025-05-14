public with sharing class TermsCtrl {
    private User u;
    public Boolean signTerms {get;private set;}    

    public TermsCtrl() {
        u = [Select Terms_Of_Use_Date__c From User Where Id = :UserInfo.getUserId()];
        signTerms = u.Terms_Of_Use_Date__c==null ? true : false;
    }  

    // validation occurs in JS
    public PageReference agreeSubmit() {
        PageReference pr;
        u.Terms_Of_Use_Date__c=System.today();
        update u;
        pr = Page.CCMPortalHome;
        pr.setRedirect(true);
        return pr; // reload page
    }    
}