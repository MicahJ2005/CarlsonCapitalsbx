/**
 * @description       : Unit Test for Invocable_FormatDateTime
 * @author            : Sophia Murphy (Demand Chain)
 * Modifications Log 
 * 12.24.2024	Sophia Murphy (Demand Chain)
 * 				Initial Creation
**/
@isTest
public with sharing class Invocable_FormatDateTimeTest {
    
    @isTest
    public static void formatTest() {

        //Pass the section name and meeting id into the invocable
        List<Invocable_FormatDateTime.InputValue> inputList = new List<Invocable_FormatDateTime.InputValue>();
        Invocable_FormatDateTime.InputValue input = new Invocable_FormatDateTime.InputValue();

        input.dateTimeInput = Date.today();
        input.format = 'EEEE, M/d/yyyy, h:mm a';
        inputList.add(input);
        
        Invocable_FormatDateTime.formatDateTime(inputList);
    }
}