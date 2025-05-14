public class ChatterPostTriggerHandler {
    public static void handleAfterInsert(List<FeedItem> newFeedItems) {
        // set the names of the Chatter groups to send emails to
        // List<String> groupNames = new List<String>{'Test group', 'Orion Ops'};
        Map<String, String> groupEmailMap = new Map<String, String>();
        for (Group_Setting__mdt groupSetting : Group_Setting__mdt.getAll().values()) {
            groupEmailMap.put(groupSetting.Label, groupSetting.Group_Email__c);
        }
        //System.debug('groupMetadata size: ' + groupMetadata.size()); 
        // Map<String,String> emailToNameMap = new Map<String,String>();
        
        // Create a map of collaboration group names to their Ids
        /*   Map<String, Id> groupNameToIdMap = new Map<String, Id>();
List<CollaborationGroup> groups = [SELECT Name, Id FROM CollaborationGroup WHERE Name IN :groupNames];
for (CollaborationGroup cGroup : groups) {
groupNameToIdMap.put(cGroup.Name, cGroup.Id);
}*/
        
        // Create a map of user Ids to their email addresses
        /*  Set<Id> groupIds = new Set<Id>(groupNameToIdMap.values());
List<CollaborationGroupMember> members = [SELECT MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE CollaborationGroupId IN :groupIds];
Set<Id> userIds = new Set<Id>();
for (CollaborationGroupMember member : members) {
userIds.add(member.MemberId);
}*/
        /*     Map<Id, String> userIdToEmailMap = new Map<Id, String>();
List<User> users = [SELECT Id, Email, Name FROM User WHERE Id IN :userIds];
for (User user : users) {
userIdToEmailMap.put(user.Id, user.Email);
}*/
        
        // Send emails to group members
        for (FeedItem post : newFeedItems) {
            System.debug('post: ' + post);
            // check if the post contains an @mention of any of the groups
            for (String groupName : groupEmailMap.keySet()) {
                if (groupName != null && post.Body.contains('@' + groupName)) {
                    System.debug('groupName: ' + groupName); 
                    String groupEmail = groupEmailMap.get(groupName);
                    // Get the email addresses of the members of the mentioned group
                    /*  Set<Id> mentionedGroupIds = new Set<Id>{groupNameToIdMap.get(groupName)};
Set<Id> mentionedUserIds = new Set<Id>();
for (CollaborationGroupMember member : members) {
if (mentionedGroupIds.contains(member.CollaborationGroupId)) {
mentionedUserIds.add(member.MemberId);
}
}*/
                    /* List<String> emailAddresses = new List<String>();
for (Id userId : mentionedUserIds) {
emailAddresses.add(userIdToEmailMap.get(userId));
}*/
                    
                    // send email to group members
                    
                    User poster = [SELECT Name FROM User WHERE Id = :post.CreatedById];
                    
                    String postBody = post.Body.stripHtmlTags(); 
                    String recordLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + post.ParentId;
                    String recordLinkHtml = '<a href="' + recordLink + '">' + recordLink + '</a>';
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setCharset('UTF-8');
                    system.debug('test emails  '  +groupEmail);
                    email.setToAddresses(new List<String>{groupEmail});
                    email.setSubject('Chatter Group Mention Email');
                    string htmlbody = 'A Chatter post was made that mentions the group "' + groupName + '".<br/><br/>' +
                        'Post made by: ' + poster.Name + '<br/><br/>' +
                        'Chatter Post: ' + postBody + '<br/><br/>' +
                        'Record link: ' + recordLinkHtml;
                    System.debug('Email Body Before Encoding: ' + htmlbody);
                    email.setHtmlBody(htmlbody);
                    
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                    
                    break;
                    
                }
            }
        }
    }
}