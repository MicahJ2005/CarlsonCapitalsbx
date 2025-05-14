global class Invocable_FormatDateTime {
    
	@InvocableMethod(label='Format DateTime')
    public static List<ReturnValue> formatDateTime(List<InputValue> inputValues) {
        List<ReturnValue> returnValues = new List<ReturnValue>();
        for (InputValue inputValue : inputValues) {
            Datetime dt = inputValue.dateTimeInput;
            String format = inputValue.format;
            
            ReturnValue returnValue = new ReturnValue();
            returnValue.formattedDateTime = dt.format(format);
            returnValues.add(returnValue);
        }
        return returnValues;
    }
    
    global class InputValue {
        @InvocableVariable
        global Datetime dateTimeInput;

        @InvocableVariable
        global String format;
    }
    
    global class ReturnValue {
        @InvocableVariable
        global String formattedDateTime;
    }
}