public without sharing class ClientInventoryHelper {
    public static List<Attachment> getAttachments(Id parentId) {
        System.debug(parentId);
        List<Attachment> attachments = [Select Id, Name, CreatedBy.Name, CreatedBy.Profile.Name, CreatedDate From Attachment Where ParentId = :parentId Order By Name];
        return attachments;
    } 

    public static List<ContentDocumentLink> getDocuments(Id parentId) {
        System.debug(parentId);
        List<ContentDocumentLink> attachments = [Select Id, ContentDocument.Title, ContentDocumentId, ContentDocument.CreatedBy.Name, ContentDocument.CreatedBy.Profile.Name, ContentDocument.CreatedDate From ContentDocumentLink Where LinkedEntityId = :parentId Order By ContentDocument.Title];
        return attachments;
    } 
 
}