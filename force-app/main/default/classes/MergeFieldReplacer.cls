public class MergeFieldReplacer {
    @InvocableMethod(label='Replace Merge Fields' description='Replaces merge fields in the email body with actual values from the provided map')
    public static List<String> replaceMergeFields(List<MergeFieldReplacer.Input> inputList) {
        List<String> results = new List<String>();
        for (Input input : inputList) {
            String emailBody = input.emailBody;
            Map<String, String> variableMap = new Map<String, String>();
            
            //Put all the Footers in, they will be in everything
            variableMap.put('BloomingtonFooter', System.label.BloomingtonFooter);
            variableMap.put('HastingsFooter', System.label.HastingsFooter);
            variableMap.put('NorthfieldFooter', System.label.NorthfieldFooter);
            variableMap.put('RochesterFooter', System.label.RochesterFooter);

            // Populate the map with key-value pairs
            for (KeyValuePair pair : input.variableMap) {
                if (pair.key != null && pair.value != null) {
                    System.debug(pair.key + ': ' + pair.value);
                    variableMap.put(pair.key, pair.value);
                }
            }
            
            // Replace merge fields with actual values from the map
            for (String variableName : variableMap.keySet()) {
                String variableValue = variableMap.get(variableName);
                emailBody = emailBody.replace('{!' + variableName + '}', variableValue);
            }
            
            results.add(emailBody);
        }
        return results;
    }
    
    public class Input {
        @InvocableVariable(required=true)
        @AuraEnabled
        public String emailBody;
        
        @InvocableVariable(required=true)
        @AuraEnabled
        public List<KeyValuePair> variableMap;

        // No-argument constructor
        public Input() {
        }

        // Constructor to initialize emailBody and variableMap
        public Input(String emailBody, List<KeyValuePair> variableMap) {
            this.emailBody = emailBody;
            this.variableMap = variableMap;
        }
    }
}