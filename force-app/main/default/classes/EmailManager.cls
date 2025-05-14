public class EmailManager {
    
    public void sendEmail(String emailBody, String emailSubject, List<String> emailList){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Mail.setToAddresses(emailList);
        mail.setReplyTo('noreply@salesforce.com');
        mail.setSenderDisplayName('Salesforce Process');
        mail.setSubject(emailSubject);
        mail.setPlainTextBody(emailBody);
        mail.setHtmlBody(emailBody);
        mail.setUseSignature(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
}