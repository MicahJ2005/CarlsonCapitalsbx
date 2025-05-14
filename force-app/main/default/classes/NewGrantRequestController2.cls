/////This controller is used to simply redirect the old portal URL to the new Digital Experience Portal
public with sharing class NewGrantRequestController2 {
    public String redirectUrl {get; set;}
    public Boolean isRedirect {get; set;}
    private Account acc {get; set;}
    
    public NewGrantRequestController2(ApexPages.StandardController sc) {
        this.acc = (Account)sc.getRecord();
        this.redirectToNewPortalPage();
    }
     
    public PageReference redirectToNewPortalPage() {
        isRedirect = true;
        boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if(runningInASandbox == true){
            redirectUrl = 'https://ccmfsc--fscsandbox.sandbox.my.site.com/ACPPortal';
        }
        else{
            redirectUrl = 'https://clients.force.com/ACPPortal';
        }
        
        return null;
    }
}