global with sharing class SendSMSCtrl {
    
    public List<Contact> c {get;set;}
    public String contactId {get;set;}
    public String mobile {get;set;}
    public String twofactor {get;set;}
    public String userProfile {get;set;}
    
    public SendSMSCtrl() {
        if(ApexPages.currentPage().getParameters().containsKey('id')) {
            String cId = ApexPages.currentPage().getParameters().get('id');
            c = [select Id, MobilePhone, Two_Factor_Phone__c from contact where id =: cId limit 1];
            if(c.size() > 0) {
                mobile = c.get(0).MobilePhone != null ? c.get(0).MobilePhone.replace(')','').replace('(','').replace('-','').replace(' ','') : '';
                twofactor = c.get(0).Two_Factor_Phone__c != null ? c.get(0).Two_Factor_Phone__c.replace(')','').replace('(','').replace('-','').replace(' ','') : '';
                contactId = c.get(0).Id != null ? c.get(0).Id : '';
            }
        } else {
            contactId = '';
            mobile = '';
            twofactor = '';
        }
    }
    
    @RemoteAction
    global static String getProfile() {
        String userProfile = '';
        if(userInfo.getProfileId() != '') {
            List<Profile> p = [select id, name from profile where id =: userInfo.getProfileId() limit 1];
            if(p.size() > 0) {
                userProfile = p.get(0).Name != null ? p.get(0).Name : '';
            }   
        }
        return userProfile;
    }
    
    @RemoteAction
    global static Map<String,String> getFromNums() {
        Map<String,String> respMap = new Map<String,String>();
        try {
            HttpRequest request = new HttpRequest();
        
            String username = '829fe451735ab13011a0a9f4f1d796bf84b486da66899666';
            String password = 'f334e7904d728f937e45fa4731e2bbc3c6898cb703f71882';
          
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            request.setHeader('Content-Type','application/json');
            
            Http http = new Http();
            
            request.setEndpoint('https://api.catapult.inetwork.com/v1/users/u-aqb2en3yrnnfz27tgavdgti/phoneNumbers');
            request.setMethod('GET');
            
            HttpResponse resp = http.send(request);
            if(resp.getStatus() == 'OK') {
                List<Object> numList = (List<Object>) JSON.deserializeUntyped(resp.getBody());
                List<String> numSort = new List<String>();
                Map<String,String> tmp = new Map<String,String>();
                for(integer i = 0; i < numList.size(); i++) {
                    Map<String,Object> numObj = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(numList.get(i)));
                    if(String.valueOf(numObj.get('numberState')) == 'enabled') {
                        numSort.add(String.valueOf(numObj.get('nationalNumber')));
                        tmp.put(String.valueOf(numObj.get('nationalNumber')), String.valueOf(numObj.get('number')).substring(2,String.valueOf(numObj.get('number')).length()));
                    }
                }
                numSort.sort();
                for(integer i = 0; i < numSort.size(); i++) {
                    respMap.put(numSort.get(i),tmp.get(numSort.get(i)));
                }
            } else {
                respMap.put('error',resp.getStatus());  
            }
            return respMap;
        } catch (Exception e) {
            respMap.put('error', e.getMessage());
            return respMap;
        }
    }
    
    @RemoteAction
    global static String sendSMS(String fromNum, String toNum, String message, String contactId) {
        try {
            String response = '';
        
            HttpRequest request = new HttpRequest();
            
            String username = '829fe451735ab13011a0a9f4f1d796bf84b486da66899666';
            String password = 'f334e7904d728f937e45fa4731e2bbc3c6898cb703f71882';
          
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            request.setHeader('Content-Type','application/json');
            
            BandwidthSMS__c settings = BandwidthSMS__c.getOrgDefaults();
            String defaultAppId = Test.isRunningTest() ? '553cc8ec-d5a7-46f1-bb45-d308d2b15bb0' : String.valueOf(settings.Default_Application_Id__c);
            
            Http http = new Http();
            
            request.setEndpoint('https://messaging.bandwidth.com/api/v2/users/5005537/messages');
            request.setMethod('POST');
            string outgoingMessage = '{'+'"from":"'+fromNum+'","to":"'+toNum+'","applicationId":"'+defaultAppId+'","text":"'+message.replace('\n','\\n').replace('\r','\\r')+'"'+'}';
            request.setBody(outgoingMessage);
            
            HttpResponse resp = http.send(request);
            response += resp.getStatus();
            
            if(resp.getStatus() == 'Accepted') {
                Task t = new Task();
                Date actDate = Date.today();
                if(contactId != '') {
                    t = new Task(Description = 'From: '+fromNum+'\nTo: '+toNum+'\nMessage: '+message, ActivityDate = actDate, WhoId = contactId, Priority = 'Normal', Status = 'Completed', Subject = 'SMS Message', Type = 'Text' );
                } else {
                    t = new Task(Description = 'From: '+fromNum+'\nTo: '+toNum+'\nMessage: '+message, ActivityDate = actDate, Priority = 'Normal', Status = 'Completed', Subject = 'SMS Message', Type = 'Text' );
                }
                if(t != null) {
                    Database.SaveResult saveRes = Database.insert(t, false);
                    if(!saveRes.isSuccess()) {
                        response += ' message, but the task record creation failed';
                    } 
                }
            }
            return response;
        } catch (Exception e) {
            return e.getMessage();
        }
    }
}