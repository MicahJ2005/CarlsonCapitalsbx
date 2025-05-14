/**
* @author Orchestrate LLC
* @date 2017
*
* @group Core
*
* @description NetDocuments Integration. Contains static variables and methods used across the NetDocuments integration.
*
*/
public with sharing class NetDocumentsService {

    // APPLICATION SETUP INFORMATION 
    public static String ndAppKey = 'AP-5RJ1ZUJV'; //App Key/Client ID
    public static String ndAppSecret = 'CsOchPpv2mS74r66AlxsrmzgIGNgPBAzwbwh3SvhWaIMAcu8'; //Client Secret
    public static String redirectURI = URL.getSalesforceBaseURL().toExternalForm() + '/apex/NetDocumentsAuth';
    public static String ndBaseUrl = 'https://api.vault.netvoyage.com';
    public static String ndCabinetId = 'NG-25V3O2A5'; //CCM Client Files

    //public NetDocumentsService() { }

    /*
    *
    * PRIMARY PUBLIC METHODS
    *
    */  

    /*
    @description Constructs accessToken based on User CS values
    */
    public static String returnAccessToken(NetDocumentsSettings__c setting){
        String ndAccessToken;
        if(String.isNotBlank(setting.AccessToken2__c)){
            ndAccessToken = setting.AccessToken__c+setting.AccessToken2__c;
        }else{
            ndAccessToken = setting.AccessToken__c;
        }
        return ndAccessToken;
    }

    /*
    @description Constructs refreshToken based on User CS values
    */
    public static String returnRefreshToken(NetDocumentsSettings__c setting){
        String ndRefreshToken;
        if(String.isNotBlank(setting.RefreshToken2__c)){
            ndRefreshToken = setting.RefreshToken__c+setting.RefreshToken2__c;
        }else{
            ndRefreshToken = setting.RefreshToken__c;
        }
        return ndRefreshToken;
    }


    /*******************************************************************************************************
    * @description Assembles a multi-part request to upload a single document through NetDocuments API.
    *
    * @param fileBody File data
    * @param fileName File data
    * @param hhId File metadata
    * @param hhName File metadata
    * @param settings NetDocumentsSettings__c for authentication information needed for the request
    * @return HttpRequest Contains all elements requested for request to upload document
    *
    */

    public static HttpRequest assembleMultiPartRequest(Blob fileBody,String fileName,String contentType,String objectType,String hhId,String hhName,Boolean isContent,NetDocumentsSettings__c settings) {
        // profile info formatted as a list of custom field objects
        String profileInfo = '[{"id":1,"value":"'+hhId+'","description":"'+hhName+'"},'+
                                (objectType=='client_inventory__c' ? '{"id":5,"value":"Initial Client/Prospect Documents"},' : '')+
                                determineDocumentType(objectType,fileName) + '{"id":4,"value":"' + System.Today().Year() + '"}]';   

        // common form elements
        String boundary = '----------------------------sfdc-multi-form';
        String crlf = '\r\n';

        // gather header components
        List<String> fileNameComponents = fileName.split('\\.');

        // create header
        String headerTemplate = '--' + boundary+crlf+'Content-Disposition: form-data; name="{0}"'+crlf+crlf;
        String header = String.format(headerTemplate,new List<String>{'action'});
        header += 'upload' + crlf;
        header += String.format(headerTemplate,new List<String>{'name'});
        String fName = fileName.replace('.'+fileNameComponents.get(fileNameComponents.size()-1),'');
        //System.debug(fName);
        header += fName + crlf;//fileName.replace('.'+fileNameComponents.get(fileNameComponents.size()-1),'') + crlf; //filename without extension
        header += String.format(headerTemplate,new List<String>{'extension'});

        // determine file extension
        String fileExtension = '';
        if (fileNameComponents.size()>1) {
            fileExtension = fileNameComponents.get(fileNameComponents.size()-1);
        } else if (isContent) {
            fileExtension = contentType;
        } else {
            fileExtension = determineFileExtension(contentType);
        }
        //System.debug(fileExtension);
        header += fileExtension + crlf; //extension
        header += String.format(headerTemplate,new List<String>{'profile'});
        header += profileInfo + crlf; 
        header += String.format(headerTemplate,new List<String>{'cabinet'});
        header += ndCabinetId + crlf; 

        // add file information
        header += '--' + boundary+crlf+'Content-Disposition: form-data; name="file"; filename=""'+crlf+'Content-Transfer-Encoding: base64'+crlf;
        header += 'Content-Type:content/stream; charset=UTF-8'+crlf+crlf;

        // create footer
        String footer = crlf + '--' + boundary + '--' + crlf;
        //System.debug(header);
        //System.debug(footer);
        // assemble the full request
        String fullBody = header+EncodingUtil.base64Encode(fileBody)+footer;
        String accessToken = NetDocumentsService.returnAccessToken(settings);
        // create the request and return it for use in the calling method
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ndBaseUrl+'/v1/Document');
        req.setMethod('POST');
        req.setBody(fullBody);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'Bearer '+accessToken);
        req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
        req.setHeader('Content-Length',String.valueof(req.getBodyAsBlob().size()));
        req.setHeader('Host','api.vault.netvoyage.com');
        req.setTimeout(120000);

        return req;
    }   

    /*******************************************************************************************************
    * @description Determines the doc type variable - looking at the filename as well as the object type
    *
    * @param objectType The object type associated with the file
    * @param fileName The file's name
    * 
    * @return The doctype json to add to the body of the request
    *
    */     
    private static String determineDocumentType(String objectType,String fileName) {
        String docType = objectType=='document_group__c' ? '{"id":2,"value":"Quarterly Reports"},' : '{"id":2,"value":"Client Documentation"},';
        if (fileName.containsIgnoreCase('meeting summary')) {
            docType = '{"id":2,"value":"Meeting Documentation"},';
        } 
        return docType;
    }

    /*******************************************************************************************************
    * @description Determines the file extension using the file's name, its fileextension (if content) or by parsing the ContentType (Attachment)
    *
    * @param contentType The file's content type
    * @return File extension to use on uploadd
    *
    */      
    private static String determineFileExtension(String contentType) {
        String fileExtension = 'pdf';
        if (contentType=='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
            fileExtension = 'xlsx';
        } else if (contentType=='application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
            fileExtension = 'docx';
        } else if (contentType=='application/vnd.openxmlformats-officedocument.presentationml.presentation') {
            fileExtension = 'pptx';            
        } else {
            try {
                List<String> fileExtensionComponents = contentType.split('/');
                fileExtension = fileExtensionComponents.get(1)!='octet-stream' ? fileExtensionComponents.get(1) : 'pdf';
            } catch (Exception e) {}
        }
        return fileExtension;
    }

    /*******************************************************************************************************
    * @description Collect an access token from the refresh token. Returns whether it was successful (or not)
    *
    * @param performUpsert Whether to update the custom setting from this method (used when called outside of this)
    * @return Success or failure to update.
    *
    */        
    public static Boolean hasUpdatedAccessToken(Boolean performUpsert,NetDocumentsSettings__c settings) {
        Boolean isSuccess = false;
        if (settings.RefreshToken__c!=null) {
            String refreshToken = NetDocumentsService.returnRefreshToken(settings);
            System.debug('collecting access token');
            String endpoint = ndBaseUrl + '/v1/OAuth';
            String oAuthCode = EncodingUtil.base64Encode(Blob.valueof(ndAppKey+':'+ndAppSecret));
            String reqBody = 'grant_type=refresh_token&refresh_token='+EncodingUtil.urlEncode(refreshToken,'UTF-8');

            // set request data
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Basic '+ oAuthCode); //Authorization: Bearer mF_9.B5f-4.1JqM
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(reqBody);

            // send the request and get the token!
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // gather the response items and update the settings in the finish methods (after callouts are complete)
            NetDocumentsService.TokenResponse tr = NetDocumentsService.parseTokenResponse(res.getBody());
            if (tr!=null && tr.access_token!=null) {
                System.debug(tr);
                isSuccess = true;
                if(tr.access_token.length()>255){
                    settings.AccessToken__c = tr.access_token.left(255);
                    settings.AccessToken2__c = tr.access_token.substring(255);
                }else{
                    settings.AccessToken__c = tr.access_token;
                }
                // should not be updated
                if (tr.refresh_token!=null) {
                    if(tr.refresh_token.length()>255){
                        settings.RefreshToken__c = tr.refresh_token.left(255);
                        settings.RefreshToken2__c = tr.refresh_token.substring(255);
                    }else{
                        settings.RefreshToken__c = tr.refresh_token;
                    }
                }
                if (performUpsert) {upsert settings;}
            }           
        }

        return isSuccess;
    }  

    /*******************************************************************************************************
    * @description Future method to update settings record.
    * 
    * @param userId
    * @param aToken
    * @param rToken
    * @return none
    *
    */ 
    @future
    public static void upsertSettingsFuture(Id userId,String aToken,String rToken, String aExpires, String rExpires) {
        NetDocumentsSettings__c nds = NetDocumentsSettings__c.getInstance(userId);
        if(aToken.length()>255){
            nds.AccessToken__c = aToken.left(255);
            nds.AccessToken2__c = aToken.substring(255);
        }else{
            nds.AccessToken__c = aToken;
        }
        if(rToken.length()>255){
            nds.RefreshToken__c = rToken.left(255);
            nds.RefreshToken2__c = rToken.substring(255);
        }else{
            nds.RefreshToken__c = rToken;
        }
        nds.TokenExpiration__c = Datetime.now().addSeconds(Integer.valueOf(aExpires));
        //Currently no refresh token expiration is provided, but it says it is 1yr. After OAuth2.0 is released, this will be updated
        nds.RefreshTokenExpiration__c = Datetime.now().addYears(Integer.valueOf(rExpires));
        upsert nds;
    }


    /*
    *
    * EMAIL NOTIFICATION SUMMARIES
    *
    */ 

    public static void sendAuthenticationSummaryEmail(String msgBody,User userInfo) {
        // email body
        String emailMessage = '<br/><br/><a href="'+URL.getSalesforceBaseURL().toExternalForm()+'/apex/NetDocumentsAuth">Please authenticate with NetDocuments.</a>';
        if (msgBody!=null) {
            emailMessage+='<br/><br/>'+msgBody;
        }

        sendEmail('Authentication Required',emailMessage,userInfo); 
    }

    public static void sendBatchNotificationEmail(String jobId,String msgBody,String errString,User userInfo) {
        String emailMessage = '';

        //AsyncApexJob a = [SELECT id, ApexClassId, 
        //               JobItemsProcessed, TotalJobItems, 
        //               NumberOfErrors, CreatedBy.Email 
        //               FROM AsyncApexJob 
        //               WHERE id = :jobId];
        
        //     + 'has finished.  It executed ' 
        //     + a.totalJobItems 
        //     + ' batches.  Of which, ' + a.jobitemsprocessed 
        //     + ' processed without any exceptions thrown and ' 
        //     + a.numberOfErrors +
        //     ' batches threw unhandled exceptions.';

        if (msgBody!=null) { emailMessage += msgBody; }
        if (errString!='') { emailMessage += '<br/><br/>* * * * *<br/><br/>'+errString; }

        sendEmail('Document Upload Summary',emailMessage,userInfo); 
    }    

    private static void sendEmail(String subject,String emailMessage,User userInfo) {
        // create email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // set email addresses and reply information
        //String[] toAddresses = new String[] {userInfo.email,'pcedev@orchestratellc.com'};
        String[] toAddresses = new String[] {userInfo.email};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('noreply@salesforce.com');

        // sender and subject
        mail.setSenderDisplayName('CCM NetDocuments Integration');
        mail.setSubject(subject);
        
        // add body
        mail.setPlainTextBody(emailMessage);
        mail.setHtmlBody(emailMessage);
        mail.setUseSignature(false);

        // send it out!
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
        }
    }   

    /*
    *
    * APEX CLASSES 
    * REQUEST/RESPONSE CONTAINING ACCESS AND REFRESH TOKEN
    *
    */ 
    
    public class TokenRequest {
        public String grant_type; // 'authorization_code' (with code param provided) or 'refresh_token' (with refresh_token param provided)
        public String code; 
        public String redirect_uri; 
        public String refresh_token; 
    }          
    
    public class TokenResponse {
        public String code; 
        public String access_token; 
        public String refresh_token; 
        public String expires_in;
        public String token_type;   
        public String error;   
    }     
    
    public static TokenResponse parseTokenResponse(String json) { 
        TokenResponse obj = (TokenResponse)System.JSON.deserialize(json, TokenResponse.class);         
        return obj; 
    }    

    /*
    *
    * MISC
    *
    */    

    /*******************************************************************************************************
    * @description misc method to get profile data for a specific document id
    * 
    * Response Example:
    * {
    * "customAttributes":[{"id":2,"value":"Client Documentation"},{"description":"Randy Moss Family","id":1,"value":"001i000000CjNgeAAF"},{"id":5,"value":"Photos"}],
    * "location":{"account":"CA-7II96TKH","cabinet":"NG-25V3O2A5"},
    * "misc":{"approved":false,"archived":false,"deleted":false,"echo":true,"external":false,"favorite":false,"signed":false},
    * "permissions":[{"administer":false,"cabDefault":false,"edit":true,"noAccess":false,"share":true,"view":true}],
    * "standardAttributes":{"created":"\/Date(1411651258000)\/","createdBy":"Tim Jackson","createdByGuid":"","envId":":Q15:e:u:f:q:~140925092058549.nev","extension":"jpg",
    * "id":"4847-8812-3422","modified":"\/Date(1411651259000)\/","modifiedBy":"Tim Jackson","modifiedByGuid":"VAULT-tim@carlsoncap.com","name":"Moss-Randy2","officialVer":1,"size":23,"syncMod":3599215354,"url":"https:\/\/vault.netvoyage.com\/Q15\/e\/u\/f\/q\/~140925092058549.nev","versions":1}
    * }    
    *
    * @param docId The NetDocuments Document Id
    * @return HttpRequest Request object. Send and then System.debug() the req.getBody() to the console for review
    *
    */ 
    //public HttpRequest getProfileData(String docId) {

    //  HttpRequest req = new HttpRequest();
    //  req.setEndpoint(ndBaseUrl+'/v1/Document/'+docId+'/info');
    //  req.setMethod('GET');
    //  req.setHeader('Accept', 'application/json');
    //  //req.setHeader('Accept-Encoding', 'gzip, deflate');
    //  req.setHeader('Authorization', 'Bearer '+settings.AccessToken__c);
    //  req.setHeader('Content-Type','application/json');
    //  //req.setBody(headerEncoded+bodySection+footerEncoded);
    //  //req.setBodyAsBlob(bodyBlob);
    //  //req.setHeader('Content-Length',String.valueof(req.getBodyAsBlob().size()));
    //  req.setHeader('Host','api.vault.netvoyage.com');
    //  req.setTimeout(120000);

    //  return req;
    //}     


    // Execute Anonymous Script
    //NetDocumentsService ndcc = new NetDocumentsService();
    //String ndAppKey = 'AP-5RJ1ZUJV'; 
    //String ndAppSecret = 'CsOchPpv2mS74r66AlxsrmzgIGNgPBAzwbwh3SvhWaIMAcu8';       

    //String redirectURI = URL.getSalesforceBaseURL().toExternalForm() + '/apex/NetDocumentsAuth';

    //String endpoint = ndcc.ndBaseUrl+'/v1/Document';
    //String authCode = EncodingUtil.base64Encode(Blob.valueof(ndAppKey+':'+ndAppSecret));

    //if (!Test.isRunningTest()) {
    //    // for each attachment for this Inventory record call out to NetDocs
    //    for (Attachment a : [Select Name,Body,ContentType From Attachment Where ParentId='a3c29000001w6dj']) {
    //        HttpRequest req = ndcc.assembleMultiPartRequest(a);
    //        //HttpRequest req = ndcc.getProfileData('4847-8812-3422');
    //        System.debug('---- REQUEST -----');
    //        System.debug(req);
    //        System.debug('----- /REQUEST -----');
    //        Http http = new Http();
    //        HTTPResponse res = http.send(req);
    //        System.debug('----- RESPONSE -----');
    //        System.debug(res.getBody());
    //        System.debug('----- /RESPONSE -----');
    //        NetDocumentsService.TokenResponse tr = NetDocumentsService.parseTokenResponse(res.getBody());
    //    }
    //}

    // potential error response
    //{"created":"\/Date(1484049141974)\/",
    //"createdBy":"CRM Admin",
    //"createdByGuid":"VAULT-IYG30ZS2",
    //"envId":":Q6:u:l:9:1:~170110065221974.nev",
    //"errors":["Profile error on field 1. Client requires a value.. ","Profile error on field 2. Doc Type requires a value.. "],
    //"extension":"pdf","id":"4826-8871-9424",
    //"modified":"\/Date(1484049142662)\/",
    //"modifiedBy":"CRM Admin",
    //"modifiedByGuid":"VAULT-IYG30ZS2",
    //"name":"NetDocuments REST API",
    //"officialVer":1,
    //"size":294,
    //"syncMod":7725019570,
    //"url":"https:\/\/vault.netvoyage.com\/Q6\/u\/l\/9\/1\/~170110065221974.nev",
    //"versions":1}


}