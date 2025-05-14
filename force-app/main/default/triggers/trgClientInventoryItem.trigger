trigger trgClientInventoryItem on Client_Inventory_Item__c (before update,before insert) {
    for (Client_Inventory_Item__c c : Trigger.new) {
        if (c.Name==null) {
            c.Name = c.Type__c!=null ? c.Type__c : '[not entered]';
        }
    }
}