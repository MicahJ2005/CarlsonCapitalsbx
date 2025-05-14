/**
* @author Orchestrate LLC
* @date 2017
*
* @group Core
*
* @description NetDocuments Integration
* 
* Files should be added to the CCM Client Files cabinet (NG-25V3O2A5) with the following profile fields:
* 
* Client: <Salesforce Household Id (18)>
* Doc Type: Client Documentation
* Doc Sub-Type: Initial Client/Prospect Documents
*
*/
public without sharing class NetDocumentsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    public static String ndAppKey = NetDocumentsService.ndAppKey;
    public static String ndAppSecret = NetDocumentsService.ndAppSecret;
    public static String redirectURI = NetDocumentsService.redirectURI;
    public static String ndBaseUrl = NetDocumentsService.ndBaseUrl;
    public static String ndCabinetId = NetDocumentsService.ndCabinetId;
    
    Integer successCount = 0;
    String uploadedDocumentNames = '';
    String errorString = '';

    NetDocumentsSettings__c settings;

    String singleDocumentId;
    String objectType;
    String parentId;
    Datetime netDocsUploadDate;
    User userInfo;
    Boolean isAttachmentBatch = false;

    sObject parentObject;
    String householdName = '';

    String hhId = '';
    String hhName = ''; 

    // constructor for single document
    public NetDocumentsBatch(String documentId,String userId,String hhId,String hhName) {
        this.singleDocumentId = documentId;
        this.hhId = hhId;
        try {
            this.hhName = [Select Name From Account Where Id = :hhId Limit 1].Name;
        } catch (Exception e) {}        
        gatherUserSettings(userId);
    }   

    // constructor for uploading all documents from a parent record
    public NetDocumentsBatch(String parentId,String userId,Boolean isAttachmentBatch) {
        this.parentId = parentId;
        this.isAttachmentBatch = isAttachmentBatch;
        gatherUserSettings(userId);
    }

    private void gatherUserSettings(String userId) {
        this.userInfo = [Select Name,Email From User Where Id = :userId Limit 1];
        this.settings = NetDocumentsSettings__c.getInstance(userId);        
    }

    /*
    *
    * BATCH CLASS METHODS
    *
    */ 

    public Database.queryLocator start(Database.BatchableContext ctx) {
        if (Test.isRunningTest() || NetDocumentsService.hasUpdatedAccessToken(true,settings)) {
            if (parentId!=null) { // if this is not a single document, non-household upload
                objectType = String.valueOf(Id.valueOf(parentId).getSObjectType()).toLowerCase();
                String parentObjectQuery = 'select id,FilesAddedtoNetDocs__c,Household__c,Household__r.Name From '+objectType+' Where Id = \''+parentId+'\' Limit 1';
                System.debug('parentObjectQuery '+parentObjectQuery);       
                parentObject = Database.query(parentObjectQuery);
                System.debug('parentObject');       
                System.debug(parentObject);       
                if (parentObject!=null && parentObject.get('FilesAddedtoNetDocs__c')!=null) {
                    netDocsUploadDate = (Datetime)parentObject.get('FilesAddedtoNetDocs__c');
                }       
                //Set<String> objectsWithHouseholdFieldAPIName = new Set<String>{'document_group__c','client_inventory__c'};
                //String hhFieldAPIName = objectsWithHouseholdFieldAPIName.contains(objectType) ? 'household__c' : 'account__c';
                if (hhId==null || hhId=='') {
                    hhId = (String)parentObject.get('household__c');                                
                    hhName = (String)parentObject.getSobject('household__r').get('Name');                    
                }
            }                           
            
            if (singleDocumentId!=null) {
                // return details for a single document
                return Database.getQueryLocator([Select PathOnClient,VersionData,LastModifiedDate 
                                                    From ContentVersion 
                                                    Where ContentDocumentId = :singleDocumentId]);
            } else if (isAttachmentBatch) {
                return Database.getQueryLocator([Select Name,Body,ContentType,LastModifiedDate 
                                                    From Attachment 
                                                    Where ParentId=:parentId]);
            } else {
                // look for permissions linked to this document
                List<ContentDocumentLink> links = [Select ContentDocumentId From ContentDocumentLink Where LinkedEntityId=:parentId];
                Set<Id> contentIds = new Set<Id>();
                for (ContentDocumentLink c : links) {
                    contentIds.add(c.ContentDocumentId);
                }
                return Database.getQueryLocator([Select PathOnClient,VersionData,LastModifiedDate 
                                                    From ContentVersion 
                                                    Where ContentDocumentId in :contentIds]);
            }
        }
        return null;
    }
        
    public void execute(Database.BatchableContext ctx, List<sObject> scope){
        System.debug('scope '+scope.size());
        postDocumentsToAPI(scope,!isAttachmentBatch);   
    }

    public void finish(Database.BatchableContext ctx) {
        String uploadMsg = 'The following '+successCount+' file(s) have been successfully uploaded from CRM to NetDocuments for '+hhName+'. It can take up to 10 minutes for a file to be available in NetDocuments. <a href="https://vault.netvoyage.com/neWeb2/goID.aspx?cabinet=NG-25V3O2A5&ws='+hhId+'" target="_blank">View Client Files in NetDocuments</a></div>';
        if (successCount == 0) {
            uploadMsg = 'No files were uploaded from CRM to NetDocuments';
        }
        uploadMsg += '<br/><br/>';
        // if there are uploaded documents or an error message in this string, send email
        if (uploadedDocumentNames!='') {
            NetDocumentsService.sendBatchNotificationEmail(ctx.getJobId(),uploadMsg + uploadedDocumentNames,errorString,userInfo);          
        }

        if (successCount>0 && parentObject!=null) {
            // attempt to update the date field on which files were uploaded
            // will not work with Account (single documents)
            try {
                parentObject.put('FilesAddedtoNetDocs__c',System.now());
                if(!Test.isRunningTest())
                    update parentObject;                
            } catch (Exception e) {
                uploadMsg += '<br/>FilesAddedtoNetDocs__c field update error: '+e.getMessage()+' '+e.getStackTraceString();
            }
            
            // attempt to update the net docs link field
            // will only work with document groups
            try {
                parentObject.put('NetDocs_Link__c',true);
                if(!Test.isRunningTest())
                    update parentObject;                
            } catch (Exception e) {}
        }
        upsert settings;
    }

    /*
    *
    * METHODS 
    *
    */     


    /*******************************************************************************************************
    * @description Post documents to API.
    * Files should be added to the CCM Client Files cabinet (NG-25V3O2A5) with the following profile fields:
    *
    * Client: <Salesforce Household Id (18)>
    * Doc Type: Client Documentation
    * Doc Sub-Type: Initial Client/Prospect Documents    
    *
    * @param attachments List of Attachments or Chatter Files (ContentVersion) documents
    * @return none
    *
    */        
    private void postDocumentsToAPI(List<sObject> attachments,Boolean isContent) {
        Boolean hasErrors = false;  
        //Boolean isAttachment = String.valueOf(Id.valueOf(attachments.get(0)).getSObjectType()).equalsIgnoreCase('attachment');
        // get household data to populate required custom fields in NetDocs profile 
        // As of 2017-01 works with document_group__c or client_inventory__c objects
        // TODO add 

        // for each attachment for this Inventory record send file to NetDocs
        for (sObject a : attachments) {
            String fileSize = 'NA';
            try {
                if (isAttachmentBatch) {
                    fileSize = String.valueOf(a.get('BodyLength'));
                } else {
                    fileSize = String.valueOf(a.get('ContentSize'));
                }
            } catch (Exception e) { }
            // if we haven't uploaded files yet or the file was uploaded after that date
            HttpRequest req; 
            Blob fileBody;
            String fileName;
            if (isAttachmentBatch) { // 1. Attachments - assemble the request
                fileBody = (Blob)a.get('body');
                fileName = (String)a.get('name');
            } else { // 2. Chatter Files
                fileBody = (Blob)a.get('VersionData');
                fileName = (String)a.get('PathOnClient');   
            }

            // compare dates to ensure we are not uploading the document multiple times  
            Datetime attachmentlastModifiedDate = (Datetime)a.get('LastModifiedDate');
            System.debug('netDocsUploadDate '+netDocsUploadDate);       
            System.debug('attachmentlastModifiedDate '+attachmentlastModifiedDate);       
            if (netDocsUploadDate == null || attachmentlastModifiedDate > netDocsUploadDate) {
                String contentType = '';
                try {
                    contentType = isContent ? (String)a.get('FileExtension') : (String)a.get('ContentType');
                } catch  (Exception e) {}
                try {
                    req = NetDocumentsService.assembleMultiPartRequest(fileBody,fileName,contentType,objectType,hhId,hhName,isContent,settings); 
                    // send request and obtain the response
                    Http http = new Http();
                    HTTPResponse res = http.send(req);

                    // ADD THE NETDOCUMENTS RESPONSE TO THE EMAIL
                    if (res!=null && res.getStatus()!=null) {
                        errorString+='<br/>'+fileName+' Response<br/><br/>Status:<br/>'+res.getStatus()+'<br/>Response:<br/>'+res.getBody()!=null ? res.getBody() : 'No Response Body';
                    } else {
                        errorString+='<br/>'+fileName+': No Response from NetDocs';
                    }

                    // obtain the response
                    NetDocumentsService.TokenResponse tr;
                    try {
                        //System.debug(res.getBody());
                        tr = NetDocumentsService.parseTokenResponse(res.getBody());
                    } catch (Exception e) {
                        hasErrors = true;   
                        errorString+='<br/>Error with \''+fileName+'\':<br/>'+e.getMessage();
                    }

                    // check for expired or invalid token and increment success counter
                    if (tr!=null && tr.error!=null) { // && 
                        errorString+='<br/>Error: '+tr.error;
                        hasErrors = true;   
                        if (tr.error.contains('Token has expired or is invalid')) {
                            NetDocumentsService.sendAuthenticationSummaryEmail('Please re-authenticate with NetDocuments.',userInfo);     
                        }                    
                    } else {
                        uploadedDocumentNames+='<br/>'+fileName;
                        successCount++;
                    }                                 
                } catch (Exception e) {
                    uploadedDocumentNames+='<br/>'+fileName+' is too large. Please upload to NetDocs manually.';
                    //uploadedDocumentNames+='<br/>'+fileName+' is too large ('+fileSize+' bytes). Please upload to NetDocs manually. '+e.getMessage();
                }
            } else {
                uploadedDocumentNames+='<br/>(Already Uploaded) '+fileName;
            }
        }
    }      


}