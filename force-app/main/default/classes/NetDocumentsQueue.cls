public class NetDocumentsQueue implements Queueable, Database.AllowsCallouts {

    public static String ndAppKey = NetDocumentsService.ndAppKey;
    public static String ndAppSecret = NetDocumentsService.ndAppSecret;
    public static String redirectURI = NetDocumentsService.redirectURI;
    public static String ndBaseUrl = NetDocumentsService.ndBaseUrl;
    public static String ndCabinetId = NetDocumentsService.ndCabinetId;
    public static String repositoryId = 'CA-7II96TKH';
    public static Id adminId = '0056g0000047DGUAA2'; //CRM Admin user ID. There shouldn't be multiple users accessing.
    public NetDocumentsSettings__c settings {get; set;}
    
    public List<Id> accountIdList {get; set;} 
    
    @TestVisible static Boolean makeCallout = true;
    
    public NetDocumentsQueue(List<Id> accIdList){
        this.accountIdList = accIdList;
    }
    
    public void execute(QueueableContext qc){
        settings = NetDocumentsSettings__c.getInstance(adminId);
        
        Boolean updated = False;
        if (settings.TokenExpiration__c < Datetime.now()){
            if (settings.RefreshTokenExpiration__c < Datetime.now()){
                EmailManager em = new EmailManager();
                em.sendEmail('Failed to update account names on NetDocs because we need to re authenticate the CRM Admin account at /apex/NetDocumentsAuth. Update names for account IDs: ' + String.valueOf(accountIdList),
                             'Reauthenticate with CRM Admin for NetDocs',
                             new List<String>{'crmadmin@carlsoncap.com'});
            } else if (makeCallout) {
                //NetDocumentsConnectCtrl ndcc = new NetDocumentsConnectCtrl();
                //updated = ndcc.collectAccessToken(True);
                updated = NetDocumentsService.hasUpdatedAccessToken(True, settings);
                System.debug('Continue after updating access token: ' + updated);
                settings = NetDocumentsSettings__c.getInstance(adminId);
            }
        } else {
            updated = True;
        }
        if (updated && makeCallout){
            makeCallouts(accountIdList);
            
        }
    }
    
    @future(callout=True)
    public static void makeCallouts(List<Id> accountIdList){
        List<Account> accountList = [SELECT Id, Name FROM Account WHERE Id IN :accountIdList];
        NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance(adminId);
        String accessToken;
        if(String.isNotBlank(settings.AccessToken2__c)){
            accessToken = settings.AccessToken__c+settings.AccessToken2__c;
        }else{
            accessToken = settings.AccessToken__c;
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'text/json');
        req.setHeader('Authorization', 'Bearer '+ accessToken);
        req.setHeader('Host','api.vault.netvoyage.com');
        req.setTimeout(120000);
        
        String failedAccounts = '';
        for (account a : accountList){
            req.setEndpoint(ndBaseUrl+'/v1/attributes/' + repositoryId + '/1/' + a.Id);
            JSONGenerator gen = JSON.createGenerator(True);
            gen.writeStartObject();
            gen.writeStringField('description', a.Name);
            gen.writeBooleanField('hold', false);
            gen.writeStringField('key', String.valueOf(a.Id));
            gen.writeEndObject();
            
            req.setBody(gen.getAsString());
            System.debug('Request Body: ' + req.getBody());
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Response body: ' + res.getBody());
            System.debug('Response status code: ' + res.getStatusCode());
            System.debug('Response status: ' + res.getStatus());
            if (res.getStatusCode() == 200){
                System.debug('Updated names in NetDocs for: ' + a.Name);
            } else {
                System.debug('Failed to update names in NetDocs for ' + a.Name);
                failedAccounts += a.Name + ', ';
            }
        }
        if (failedAccounts <> ''){
            EmailManager em = new EmailManager();
            em.sendEmail('Failed to update account names on NetDocs. Please manually update names for accounts: ' + failedAccounts.removeEnd(', '),
                         'Failed to update account names at NetDocs',
                         new List<String>{'crmadmin@carlsoncap.com'});
        }
    }
}