trigger ChatterPostTrigger on FeedItem (after insert, after update) {
    ChatterPostTriggerHandler.handleAfterInsert(Trigger.new);
}