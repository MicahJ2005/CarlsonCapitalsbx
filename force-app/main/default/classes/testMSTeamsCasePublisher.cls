@isTest
public class testMSTeamsCasePublisher {
    static testmethod void runtest(){
        Account a = new Account(name='test');
        insert a;
        Contact con = new Contact(LastName='lname',firstname='fname',AccountId=a.id);
        insert con;
        Case c = new Case(Status='New',Origin='Email',AccountId=a.id,ContactId=con.id,subject='This is my test subject',description='Test description.');
        insert c;
        c = [select CaseNumber,Subject,Status,Description,OwnerId from Case where id=:c.id limit 1];
        
        MSTeamsCasePublisher.SFCase SFCase = new MSTeamsCasePublisher.SFCase(c, con,true);
        List<MSTeamsCasePublisher.SFCase> cases = new List<MSTeamsCasePublisher.SFCase>{SFCase};        
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
            //simulating process builder running invocable method
            MSTeamsCasePublisher.postToTeams(cases);
        Test.stopTest();
    }
}