/**
 * @description       : QueueableDMLTest test class.
 * @author            : matthewl@demandchain.com
 * @group             : 
 * @last modified on  : 2023-06-12
 * @last modified by  : matthewl@demandchain.com
**/
@isTest
public with sharing class BatchDMLTest {
    

    /**
    * @description insertTest writen so that we dont care if they actually get inserted.  done so that this 
    * test can be used in several orgs without having to worry about the orgs having the same data structure.
    * @author matthewl@demandchain.com | 2023-06-12 
    **/
    @isTest
    public static void dmlTest() {
        List<Account> accounts = new List<Account>();
        Integer recordCount = 2;
        for (Integer i = 0; i < recordCount; i++) {
            Account a = new Account();
            a.Name = 'Account ' + i;
            accounts.add(a);
        }

        BatchDML.dml(accounts, 2, BatchDML.DmlType.DMLINSERT, false, null);
        BatchDML.dml(accounts, 2, BatchDML.DmlType.DMLUPDATE, false, null);
        BatchDML.dml(accounts, 2, BatchDML.DmlType.DMLUPSERT, false, null);
        BatchDML.dml(accounts, 2, BatchDML.DmlType.DMLUPSERT, false, Account.Id);
        BatchDML.dml(accounts, 2, BatchDML.DmlType.DMLDELETE, false, Account.Id);
    }

    /**
    * @description insertTest writen so that we dont care if they actually get inserted.  done so that this 
    * test can be used in several orgs without having to worry about the orgs having the same data structure.
    * @author matthewl@demandchain.com | 2023-06-12 
    **/
    @isTest
    public static void BatchDMLTestConstructorTest1() {
        List<Account> accounts = new List<Account>();
        Integer recordCount = 2;
        for (Integer i = 0; i < recordCount; i++) {
            Account a = new Account();
            a.Name = 'Account ' + i;
            accounts.add(a);
        }
        Test.startTest();
        Database.executeBatch(new BatchDML(accounts, BatchDML.DmlType.DMLINSERT), 2);
        Test.stopTest();
    }

     /**
    * @description insertTest writen so that we dont care if they actually get inserted.  done so that this 
    * test can be used in several orgs without having to worry about the orgs having the same data structure.
    * @author matthewl@demandchain.com | 2023-06-12 
    **/
    @isTest
    public static void BatchDMLTestConstructorTest2() {
        List<Account> accounts = new List<Account>();
        Integer recordCount = 2;
        for (Integer i = 0; i < recordCount; i++) {
            Account a = new Account();
            a.Name = 'Account ' + i;
            accounts.add(a);
        }
        Test.startTest();
        Database.executeBatch(new BatchDML(accounts, BatchDML.DmlType.DMLINSERT, false), 2);
        Test.stopTest();
    }

     /**
    * @description insertTest writen so that we dont care if they actually get inserted.  done so that this 
    * test can be used in several orgs without having to worry about the orgs having the same data structure.
    * @author matthewl@demandchain.com | 2023-06-12 
    **/
    @isTest
    public static void BatchDMLTestConstructorTest3() {
        List<Account> accounts = new List<Account>();
        Integer recordCount = 2;
        for (Integer i = 0; i < recordCount; i++) {
            Account a = new Account();
            a.Name = 'Account ' + i;
            accounts.add(a);
        }
        Test.startTest();
        Database.executeBatch(new BatchDML(accounts, BatchDML.DmlType.DMLINSERT, false, Account.Id ), 2);
        Test.stopTest();
    }
    
     /**
    * @description insertTest writen so that we dont care if they actually get inserted.  done so that this 
    * test can be used in several orgs without having to worry about the orgs having the same data structure.
    * @author matthewl@demandchain.com | 2023-06-12 
    **/
    @isTest
    public static void BatchDMLTestInvocable() {
        List<Account> accounts = new List<Account>();
        Integer recordCount = 2;
        for (Integer i = 0; i < recordCount; i++) {
            Account a = new Account();
            a.Name = 'Account ' + i;
            accounts.add(a);
        }
        
        BatchDML.InvocableInput input = new BatchDML.InvocableInput();
        input.sobjects = accounts;
        input.dmlOperation = 'Insert';
        input.recordsPerTransaction = 100;
        
        
        Test.startTest();
        BatchDML.invocableMethod(new List<BatchDML.InvocableInput>{input});
        Test.stopTest();
    }
    
    @isTest
    public static void BatchDMLTestDmlType() {
       
        Test.startTest();
        BatchDML.DmlType insertType = BatchDML.getDmlType('Insert');
        BatchDML.DmlType updateType = BatchDML.getDmlType('Update');
        BatchDML.DmlType deleteType = BatchDML.getDmlType('Delete');
        Test.stopTest();
        
        Assert.areEqual(insertType, BatchDML.DmlType.DMLINSERT);
        Assert.areEqual(updateType, BatchDML.DmlType.DMLUPDATE);
        Assert.areEqual(deleteType, BatchDML.DmlType.DMLDELETE);
    }
    
    @isTest
    public static void BatchDMLTestDmlTypeException() {
       
        Test.startTest();
        try{
            BatchDML.DmlType insertType = BatchDML.getDmlType('Inserts');
        } catch(Exception ex){
			Assert.areEqual(ex.getMessage(), 'Invalid DML Operation.');
        }
        
        Test.stopTest();
    }
}