@RestResource(urlMapping='/sms/*')
global class BandwidthSMSRestCtrl {
    
    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.request;
        
        System.debug('Request Body: ' + req.requestBody.toString());
        Map<String, String> params = req.params;
        System.debug('Params: ' + params);
        
        /*Map<String, String> m2 = new Map<string,string>();
        JSONParser parser = JSON.createParser(req.requestBody.toString());
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME)  {
                string name = parser.getText();
                // Get the value.
                parser.nextToken();
                //System.debug('Values: ' + parser.getText());
                m2.put(name, parser.getText());
            }
        }
        
        System.debug('Parsed Map: ' + m2);*/
        
        Type resultType = Type.forName('BandwidthSMSRestCtrl.BandwidthMessage');
        System.debug('Type: ' + resultType);
        BandwidthMessage deserializeResults = (BandwidthMessage)JSON.deserialize(req.requestBody.toString().replace('time', 'ztime').replace('from','zfrom').replace('[','').replace(']',''), resultType);
        System.debug('==========> deserialize() results = ' + deserializeResults);
        
        //Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
        
        HttpRequest request = new HttpRequest();
        
        String username = '829fe451735ab13011a0a9f4f1d796bf84b486da66899666';
        String password = 'f334e7904d728f937e45fa4731e2bbc3c6898cb703f71882';
      
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        request.setHeader('Content-Type','application/json');
        
        Http http = new Http();
        BandwidthSMS__c settings = BandwidthSMS__c.getOrgDefaults();
        String defaultNum = Test.isRunningTest() ? '(507) 301-6947' : String.valueOf(settings.Default_Forward_Number__c);
        //String transferNum = Test.isRunningTest() ? '(507) 301-6041' : String.valueOf(settings.Default_Transfer_Number__c);
        String defaultAppId = Test.isRunningTest() ? '553cc8ec-d5a7-46f1-bb45-d308d2b15bb0' : String.valueOf(settings.Default_Application_Id__c);
        Integer delayInMilliseconds = 1500;
        Long startingTime = System.now().getTime(); 
        
        
        if(deserializeResults.type == 'message-received') {
            while (System.now().getTime() - startingTime < delayInMilliseconds)  {
                //sleep to prevent Bandwidth error for more than one message per second
            }
            
            String toNumber = deserializeResults.message.to;
            
            String query = 'select id, mobilephone, Two_Factor_Phone__c, AccountId from contact where (Two_Factor_Phone__c like \''+toNumber+'\' or Two_Factor_Phone__c like \''+toNumber.substring(2,toNumber.length())+'\'';
                
            if(toNumber.substring(2,toNumber.length()).length() >= 10) {
                String template = '({0}) {1}-{2}';
                String s = toNumber.substring(2,toNumber.length());
                List<String> fillValues = new String[]{ s.substring(0,3),s.substring(3,6), s.substring(6,10) };
                String formatted = String.format(template,fillValues);
                query += ' or Two_Factor_Phone__c like \''+formatted+'\')';
            } else {
                query += ')';
            }
            query += ' and MobilePhone != null limit 1';
            List<Contact> c = Database.query(query);
            
            if(c.size() >= 1 && settings != null) {
                if(defaultNum != null) {
                    try {
                        request.setEndpoint('https://messaging.bandwidth.com/api/v2/users/5005537/messages');
                        request.setMethod('POST');
                        string outgoingMessage = '{"from": "+1'+defaultNum.replace(')','').replace('(','').replace('-','').replace(' ','')+'","to": ["+1'+c.get(0).MobilePhone.replace(')','').replace('(','').replace('-','').replace(' ','')+'"],"applicationId":"'+defaultAppId+'","text": "'+deserializeResults.message.text.replace('\n','\\n').replace('\r','\\r')+'"}';
                        request.setBody(outgoingMessage);
                        System.debug('OutgoingMessage: ' + outgoingMessage);
                        String retString = '';
                        HttpResponse response = http.send(request);
                        System.debug('HttpResponse: ' + response.getbody());
                        retString += 'Client message status: ' + response.getStatus() + ' |';
                        
                        /* -- not sending second SMS as of 10/3/22
                        startingTime = System.now().getTime(); 
                        while (System.now().getTime() - startingTime < delayInMilliseconds)  {
                            //sleep to guarantee second message is received second
                        }
                        
                        String contactMessage = 'If you did not attempt to login to your account, it is likely CCM is accessing your account on your behalf. Please call 507.645.8887 if you have questions.';
                        request.setBody('{"from": "+1'+defaultNum.replace(')','').replace('(','').replace('-','').replace(' ','')+'","to": ["+1'+c.get(0).MobilePhone.replace(')','').replace('(','').replace('-','').replace(' ','')+'"],"applicationId":"'+defaultAppId+'","text": "'+contactMessage.replace('\n','\\n').replace('\r','\\r')+'"}');
                        response = http.send(request);
                        retString += ' Client followup message status: ' + response.getStatus();
                        */
                        
                        Date actDate = Date.today();
                        Task t = new Task(Description = 'From: '+deserializeResults.message.zfrom+'\nTo: '+deserializeResults.message.to+'\nMessage: '+deserializeResults.message.text, ActivityDate = actDate, WhoId = c.get(0).Id, Priority = 'Normal', Status = 'Completed', Subject = 'SMS Message', Type = 'Text', OwnerId = '0056g0000047DGUAA2' );
                        if(c.get(0).AccountId != null) t.WhatId = c.get(0).AccountId;
                        Database.SaveResult save = Database.insert(t,false);
                        System.debug(save);
                        
                        if(!Test.isRunningTest()) sendEmail(deserializeResults);
                        
                        return retString;
                        
                    } catch (Exception exp) {
                        return exp.getMessage();
                    }
                } else {
                    return 'no default number supplied';
                }
            } else {
                String fromNum = deserializeResults.message.zfrom;
                String q = 'select id, mobilephone, Two_Factor_Phone__c, AccountId from contact where (mobilephone like \''+fromNum+'\' or mobilephone like \''+fromNum.substring(2,fromNum.length())+'\'';
                
                if(fromNum.substring(2,fromNum.length()).length() >= 10) {
                    String template = '({0}) {1}-{2}';
                    String s = fromNum.substring(2,fromNum.length());
                    List<String> fillValues = new String[]{ s.substring(0,3),s.substring(3,6), s.substring(6,10) };
                    String formatted = String.format(template,fillValues);
                    q += ' or mobilephone like \''+formatted+'\') limit 1';
                } else {
                    q += ') limit 1';
                }
                List<Contact> cList = Database.query(q);
                Date actDate = Date.today();
                Task t;
                t = new Task(Description = 'From: '+deserializeResults.message.zfrom+'\nTo: '+deserializeResults.message.to+'\nMessage: '+deserializeResults.message.text, ActivityDate = actDate, Status = 'Not Started', Subject = 'SMS Message', OwnerId = '0056g000004zPg6AAE' );
                String retString = 'number not found in Salesforce, adding general task';
                if(cList.size() > 0) {
                    t.WhoId = cList.get(0).Id;
                    if(cList.get(0).AccountId != null) t.WhatId = cList.get(0).AccountId;
                    retString = 'mobile phone found in Salesforce, adding task';
                }
                Database.SaveResult save = Database.insert(t,false);
                System.debug(save);
                
                if(!Test.isRunningTest()) sendEmail(deserializeResults);
                
                return retString;   
            }
        } /*WE DONT NEED THIS ANYMORE TRANSFERS HAPPEN ON THE NUMBER IN THE BANDWIDTH PORTAL    else if(String.valueOf(m.get('eventType')).toLowerCase() == 'answer') {
            try {
                if(transferNum != null) {
                    request.setEndpoint('https://messaging.bandwidth.com/api/v2/users/5005537/calls/'+String.valueOf(m.get('callId')));
                    request.setMethod('POST');
                    request.setBody('{"state":"transferring","transferCallerId":"'+String.valueOf(m.get('from'))+'","transferTo":"+1'+transferNum.replace(')','').replace('(','').replace('-','').replace(' ','')+'"}');
                    HttpResponse response = http.send(request);
                    String retString = 'Call transfer status status: ' + response.getStatus();
                    return retString;
                } else {
                    return 'no transfer number set';
                }
            } catch (Exception exp) {
                return exp.getMessage();
            }
        }*/
        else {
            return 'cannot handle message provided: '+ req.requestBody.toString();
        }
    }
    
    public static String sendEmail(BandwidthMessage m) {
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'accounts@carlsoncap.com'}; 
            mail.setToAddresses(toAddresses);
            mail.setReplyTo('accounts@carlsoncap.com');
            mail.setSenderDisplayName('accounts@carlsoncap.com');
            mail.setSubject('SMS Received From '+m.message.zfrom);
            mail.setPlainTextBody(m.message.text);
            mail.setHtmlBody(m.message.text);
            Messaging.SendEmailResult[] mailRes = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            return String.valueOf(mailRes[0].isSuccess());
        } catch (Exception e) {
            return e.getMessage();
        }
    }
    
    public class BandwidthMessage {
        public datetime ztime;
        public string type;
        public string to;
        public string description;
        public SubMessage message;
        public BandwidthMessage (){
        }
    }
    
    public class SubMessage{
        public string id;
        public string owner;
        public string applicationId;
        public datetime ztime;
        public integer segmentCount;
        public string direction;
        public string to;
        public string zfrom;
        public string text;
        public SubMessage(){
        }
    }
}