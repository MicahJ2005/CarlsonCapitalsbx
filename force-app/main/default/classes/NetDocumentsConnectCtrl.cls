/**
* @author Orchestrate LLC
* @date 2017
*
* @group Integration
*
* @description NetDocuments integration. 
*
* use current user to login
* Button on I&Q page to move all documents attached to I&Q
* checkbox indicating files added to netdocs
* link to document based on id	    
*
*/
public class NetDocumentsConnectCtrl {
	// application setup information - basic data stored in NetDocumentsService class
    private static String ndAppKey = NetDocumentsService.ndAppKey;// = 'AP-5RJ1ZUJV'; //App Key/Client ID
    private static String ndAppSecret = NetDocumentsService.ndAppSecret;// = 'CsOchPpv2mS74r66AlxsrmzgIGNgPBAzwbwh3SvhWaIMAcu8'; //Client Secret
    private static String redirectURI = NetDocumentsService.redirectURI;// = URL.getSalesforceBaseURL().toExternalForm() + '/apex/NetDocumentsAuth';
    private static String ndBaseUrl = NetDocumentsService.ndBaseUrl;// = 'https://api.vault.netvoyage.com';
    private static String ndCabinetId = NetDocumentsService.ndCabinetId;// = 'NG-25V3O2A5'; //CCM Client Files
    private static NetDocumentsSettings__c settings = NetDocumentsSettings__c.getInstance(UserInfo.getUserId());
    private String appAuthCode;
    
    // variables used on VF pages (Post and Auth)	
    public String parentId {get;set;}
    public String householdId {get;set;}
    public Boolean authRequired {get;private set;}

    /*******************************************************************************************************
    * @description Constructor.
    *
    * call this page to add files to NetDocs
    * 1. Check for a valid token
    * 2. If we have a refresh token call for a valid access_token using that
    * 3. If we do not have a refresh token or there is another error we need to get authorization (redirect user)
    * 
    * @param none
    * @return none
    *
    */     
    public NetDocumentsConnectCtrl() {
    	// initially assume this user has authenticated with netdocs
    	authRequired = false;

		// gather the parent Id if it is available
    	try {
            parentId = ApexPages.currentPage().getParameters().get('parentId');
		} catch (Exception e) {
			System.debug('Error on parentId gathering: '+e.getMessage()+' - '+e.getStackTraceString());
		}		

        // gather the household Id if it is available (single doc uploads)
        try {
            householdId = ApexPages.currentPage().getParameters().get('householdId');
        } catch (Exception e) {
            System.debug('Error on householdId gathering: '+e.getMessage()+' - '+e.getStackTraceString());
        }                   	
	
		// gather the auth code used to obtain the token if one is available
    	try {
	    	// look for code parameter on initial page load which will be present if we were redirected here
	    	appAuthCode = ApexPages.currentPage().getParameters().get('code');
		} catch (Exception e) {
			System.debug('Error on code gathering: '+e.getMessage()+' - '+e.getStackTraceString());
		}			    	
    }


    /*
    *
    * AUTHENTICATION METHODS
    *
    */         

    /*******************************************************************************************************
    * @description Called on page load to authenticate if user has not already done so.
    * Redirects first time or expired user to the NetDocs authentication page. Otherwise refreshes the page.
    * Authentication code is used in HTTP call to obtain an access and a refresh token (one year expiration)
    * 
    * example: 'https://vault.netvoyage.com/neWeb2/OAuth.aspx?client_id=<client_ID>&scope=<scope>&response_type=token&redirect_uri=<redirect_uri>';
    * 
    * @param none
    * @return PageReference to provide access to NetDocs and obtain an OAuth token
    *
    */     
    public PageReference obtainAuthCode() {
    	ApexPages.message msg;
    	PageReference pr;
    	//appAuthCode = ApexPages.currentPage().getParameters().get('code');
    	// if there is no code and we're missing an access and refresh token this is the initial call
    	if ( (appAuthCode==null || appAuthCode=='')) { // && settings.AccessToken__c==null && settings.RefreshToken__c==null
		    String ndAppScope = 'read%20edit%20organize'; // permissions needed in order to add new documents - scope parameters
            //Tim, Kat and API User will get full scope privileges for API calls/testing -as of 02-25-2021, KNM
            if (UserInfo.getUserId() == '0056g0000047De2AAE' || UserInfo.getUserId() == '0056g0000046iowAAA' || UserInfo.getUserId() == '0056g000002BrWwAAK'){
                ndAppScope = 'full';
            }
	    	String authCodePage = 'https://vault.netvoyage.com/neWeb2/OAuth.aspx?client_id='+ndAppKey+'&scope='+ndAppScope+'&response_type=code&redirect_uri='+redirectURI;
	    	pr = new PageReference(authCodePage);
	    	pr.setRedirect(true);
    	} else {
	        collectAccessToken(true);
			msg = new ApexPages.message(ApexPages.severity.INFO,'You have successfully authenticated with NetDocuments. You may close this window.');
    	}

		if (msg!=null){ ApexPages.addMessage(msg); }
    	return pr;
    }

    /*******************************************************************************************************
    * @description Collect an access token from the refresh token.
	*
    * @param useRefresh Whether or not to use a refresh token
    * @return none
    *
    */        
    public Boolean collectAccessToken(Boolean useRefresh) {
    	System.debug('collecting access token');
		if (appAuthCode!=null) {
	        String endpoint = ndBaseUrl + '/v1/OAuth';
	        String oAuthCode = EncodingUtil.base64Encode(Blob.valueof(ndAppKey+':'+ndAppSecret));

			// otherwise this is an error or the first time we're authenticating
			HttpRequest req = new HttpRequest();
			req.setEndpoint(endpoint);
			// set method and all headers
			req.setMethod('POST');
			req.setHeader('Authorization', 'Basic '+ oAuthCode); //Authorization: Bearer mF_9.B5f-4.1JqM
			req.setHeader('Accept', 'application/json');
			req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

			// set the request body
			req.setBody('grant_type=authorization_code&code='+EncodingUtil.urlEncode(appAuthCode,'UTF-8')+'&redirect_uri='+EncodingUtil.urlEncode(redirectURI,'UTF-8'));

			// send the request and get the token!
			Http http = new Http();
			HTTPResponse res = http.send(req);
            
            System.debug(res.getBody());
            System.debug(res.getStatusCode());
            
            if (res.getStatusCode() == 200){
                // gather the response items and update the settings (future method)   
                NetDocumentsService.TokenResponse tr = NetDocumentsService.parseTokenResponse(res.getBody());
                if (tr.access_token!=null && tr.refresh_token!=null) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'We have a valid access token.'));
                }
                //System.debug('token response '+tr);
                // update the settings with current access and refresh token
                NetDocumentsService.upsertSettingsFuture(UserInfo.getUserId(),tr.access_token,tr.refresh_token, tr.expires_in, '1'); // may need to move DML off this page
                return True;
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Unable to authenticate with NetDocuments.'));
                return False;
            }
		} else {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'No code was provided for use with NetDocuments. Please try again.'));
            return False;
		}
    }  

    /*
    *
    * NETDOCUMENTS METHODS
    *
    */     

    /*******************************************************************************************************
    * @description Kicks off a batch job to post documents to NetDocuments using a provided Inventory Id
    * 
    * @param none
    * @return PageReference to provide access to NetDocs and obtain an OAuth token
    *
    */     
    public PageReference postDocuments() {
        Boolean isSingleDocument = false;
    	ApexPages.message msg;
    	if (parentId!=null) {
            // determine if we have a single document id passed in
            Set<String> singleDocumentTypes = new Set<String>{'contentversion','contentdocument'};
            if (singleDocumentTypes.contains(String.valueOf(Id.valueOf(parentId).getSObjectType()).toLowerCase())) {
                isSingleDocument = true;
            }
            // create a new instance of this class and attempt to collect an access token from the stored information; if successful initiate a batch job to update
            NetDocumentsBatch ndb;
            if (isSingleDocument) {
                ndb = new NetDocumentsBatch(parentId,String.valueOf(UserInfo.getUserId()),householdId,'');
            } else {
                ndb = new NetDocumentsBatch(parentId,String.valueOf(UserInfo.getUserId()),true);
            } 
    		if (!NetDocumentsService.hasUpdatedAccessToken(true,settings)) {
				msg = new ApexPages.message(ApexPages.severity.INFO,'We were unable to obtain a valid access token from NetDocuments. Please reauthenticate.');
				authRequired = true;
    		} else {
				// create a new batch to avoid potential callout/DML collision in instance of class

                if (!isSingleDocument) {
                    // 1. attachments
                    ndb = new NetDocumentsBatch(parentId,String.valueOf(UserInfo.getUserId()),true);
                    Database.executeBatch(ndb,1);

                    // 2. Chatter File/ContentVersion
                    ndb = new NetDocumentsBatch(parentId,String.valueOf(UserInfo.getUserId()),false);                         
                } else {
                    // for single document, alternate constructor and no attachment batch
                    ndb = new NetDocumentsBatch(parentId,String.valueOf(UserInfo.getUserId()),householdId,'');                         
                }
                // execute the Chatter File/ContentVersion batch
				Database.executeBatch(ndb,1);   	

                // add notification
                if (!isSingleDocument) {
                    // if not a single document and the id relates to a household query for the id and add to the page message
                    sObject parentObject = Database.query('select Household__c From '+String.valueOf(Id.valueOf(parentId).getSObjectType()).toLowerCase()+' Where Id = \''+parentId+'\' Limit 1');
                    householdId = (String)parentObject.get('household__c');
                }
                String pageMsg = '<div><p>Your documents are being uploaded to NetDocuments and should be available soon. It can take up to 10 minutes for a file to be available in NetDocuments. You may close this window.</p><br/><br/><a href="https://vault.netvoyage.com/neWeb2/goID.aspx?cabinet=NG-25V3O2A5&ws='+householdId+'" target="_blank">View Client Files in NetDocuments</a></div>';                
				msg = new ApexPages.message(ApexPages.severity.INFO,pageMsg);
    		}
		} else {
			msg = new ApexPages.message(ApexPages.severity.WARNING,'You must provide a valid Client Inventory Id in order to post to NetDocuments.');
		}

		ApexPages.addMessage(msg);

		return null;
    }


}