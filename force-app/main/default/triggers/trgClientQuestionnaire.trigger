trigger trgClientQuestionnaire on Discover_Questionnaire__c (after insert,after update) {
    Map<String,Boolean> triggerMap = new Map<String,Boolean>{
        'isUpdate'=>Trigger.isUpdate,
        'isInsert'=>Trigger.isInsert,
        'isAfter'=>Trigger.isAfter,
        'isBefore'=>Trigger.isBefore
    };
    Utility.sendClientInformationNotification(Trigger.newMap.keySet(),triggerMap,'discover_questionnaire__c');
}