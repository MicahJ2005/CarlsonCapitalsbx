public class KeyValuePair {
    @InvocableVariable(required=true)
    @AuraEnabled
    public String key;
    
    @InvocableVariable(required=true)
    @AuraEnabled
    public String value;
    
    // No-argument constructor
    public KeyValuePair() {
    }
    
    // Constructor to initialize key and value
    public KeyValuePair(String key, String value) {
        this.key = key;
        this.value = value;
    }
}