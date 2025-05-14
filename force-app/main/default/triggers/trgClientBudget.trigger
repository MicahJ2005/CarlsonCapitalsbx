trigger trgClientBudget on client_budget__c (after insert,after update) {
    Map<String,Boolean> triggerMap = new Map<String,Boolean>{
        'isUpdate'=>Trigger.isUpdate,
        'isInsert'=>Trigger.isInsert,
        'isAfter'=>Trigger.isAfter,
        'isBefore'=>Trigger.isBefore
    };
    Utility.sendClientInformationNotification(Trigger.newMap.keySet(),triggerMap,'client_budget__c');
}