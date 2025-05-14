/**
 * @description       : 
 * @author            : Michael Lloyd (Demand Chain)
 * @group             : 
 * @last modified on  : 12-05-2022
 * @last modified by  : Michael Lloyd (Demand Chain)
**/
@isTest
public with sharing class BoxRedirectURLControllerTest {
    static testMethod void testRedirectBoxInNewWindow() {
        Account testHousehold = new Account(Name = 'Test Name');
        insert testHousehold;

        Test.StartTest();
		Test.setMock(HttpCalloutMock.class, new MockBoxToolkitResponse());
        List<String> redirectURL = boxRedirectURLController.redirectBoxInNewWindow(new List<Id>{testHousehold.Id});
        Test.stopTest();

        System.assertEquals('https://carlsoncap.app.box.com/folder/174571899157', redirectURL[0]);
    }
}