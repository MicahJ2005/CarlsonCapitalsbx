/**
 * @description       : Batchable class that will perform dml on records
 * @testclass(s)      : BatchDMLTest
 *
 * @author            : Matthew J Lennington
 * @group             : Demand Chain
 * @last modified on  : 2024-02-19
 * @last modified by  : Matthew J Lennington
 * @change            : Added Logging
 *
 */
public class BatchDML implements Database.Batchable<SObject> {
    public enum DmlType {
        DMLINSERT,
        DMLUPSERT,
        DMLUPDATE,
        DMLDELETE
    }
    private List<Sobject> records;
    private DmlType dml;
    private boolean allorNone;
    private Schema.SObjectField keyfield;

    /**
     * @description : Initialize Method
     *
     * @param records : records to update
     * @param dml : DmlType
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public BatchDML(List<Sobject> records, DmlType dml) {
        this.records = records;
        this.dml = dml;
        this.allorNone = true;
        this.keyfield = null;
    }

    /**
     * @description : Initialize Method
     *
     * @param records : records to update
     * @param dml : DmlType
     * @param allorNone : allorNone
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public BatchDML(List<Sobject> records, DmlType dml, Boolean allorNone) {
        this.records = records;
        this.dml = dml;
        this.allorNone = allorNone;
        this.keyfield = null;
    }

    /**
     * @description : Initialize Method
     *
     * @param records : records to update
     * @param dml : DmlType
     * @param allorNone : allorNone
     * @param keyfield : keyfield
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public BatchDML(List<Sobject> records, DmlType dml, Boolean allorNone, Schema.SObjectField keyfield) {
        this.records = records;
        this.dml = dml;
        this.allorNone = allorNone;
        this.keyfield = keyfield;
    }

    /**
     * @description : batchable start method.
     *
     * @param info : BatchableContext
     * @return Iterable<SObject>
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public Iterable<SObject> start(Database.BatchableContext info) {
        return this.records;
    }

    /**
     * @description : batchable start method.
     *
     * @param info : BatchableContext
     * @param scope : records
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public void execute(Database.BatchableContext info, List<sObject> scope) {
        //Log.push('GroundForce', 'BatchDML', 'saveResultParser');
        dmlOperation(scope, this.dml, this.allorNone, this.keyfield);
    }

    /**
     * @description : batchable finish method.
     *
     * @param info : BatchableContext
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public void finish(Database.BatchableContext info) {
        System.debug(LoggingLevel.INFO, 'BatchDML FinishMethod.');
    }

    /**
     * @description : dmlOperation method.  performs dml
     *
     * @param records : record list
     * @param dml : dml type
     * @param allorNone : allornone
     * @param keyfield : keyfield
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    private static void dmlOperation(List<SObject> records, DmlType dml, Boolean allorNone, Schema.SObjectField keyfield) {
        try {
            if (dml == DmlType.DMLINSERT) {
                saveResultParser(Database.insert(records, allorNone));
            } else if (dml == DmlType.DMLUPDATE) {
                saveResultParser(Database.update(records, allorNone));
            } else if (dml == DmlType.DMLUPSERT && keyfield != null) {
                Database.upsert(records, keyfield, allorNone);
            } else if (dml == DmlType.DMLUPSERT) {
                Database.upsert(records, allorNone);
            } else if (dml == DmlType.DMLDELETE) {
                Database.delete(records, allorNone);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Exception Occured');
            System.debug(LoggingLevel.ERROR, ex.getCause());
            System.debug(LoggingLevel.ERROR, ex.getLineNumber());
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            //Log.exception(ex);
            //Log.emit();
        }
    }

    /**
     * @description : determines whether to batch the records.  If the record count is
     *                > then the size variable we create a batch job.  else we just
     *                perform the dml.
     *
     * @param records : record list
     * @param size : Batch Size
     * @param dml : dml type
     * @param allorNone : allornone
     * @param keyfield : keyfield
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public static void dml(List<Sobject> records, Integer size, DmlType dml, boolean allorNone, Schema.SObjectField keyfield) {
        //We want it to always run in seperate tranasctions
        //if (records.size() > size) {
            Database.executeBatch(new BatchDML(records, dml, allorNone, keyfield), size);
        //} else if (!records.isEmpty()) {
            //dmlOperation(records, dml, allorNone, keyfield);
        //}
    }

    /**
     * @description : overloaded dml method.  null for keyfield
     *
     * @param records : record list
     * @param size : Batch Size
     * @param dml : dml type
     * @param allorNone : allornone
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    public static void dml(List<Sobject> records, Integer size, DmlType dml, boolean allorNone) {
        dml(records, size, dml, allorNone, null);
    }

    /**
     * @description : Additional Error Handling for save errors in instances of allornone = false
     *
     * @param srList : List<Database.SaveResult>
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-01-31
     *
     */
    private static void saveResultParser(List<Database.SaveResult> srList) {
        //Log.push('GroundForce', 'BatchDML', 'saveResultParser');
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'The following error has occurred.');
                    System.debug(LoggingLevel.ERROR, err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Fields that affected this error: ' + err.getFields());
                    //Log.stringException(err.getStatusCode() + ': ' + err.getMessage() + ' : ' + err.getFields(), sr.getId());
                }
            }
        }
        //Log.emit();
    }
    
    @InvocableMethod(label='Batch DML' description='Performs DML in a Batch Context')
    public static void invocableMethod(List<InvocableInput> inputs) {
        for(InvocableInput input : inputs){
			BatchDML.dml(input.sobjects, input.recordsPerTransaction, getDmlType(input.dmlOperation), false);
        }
    }
    @TestVisible
    private static DmlType getDmlType(String invocableDmlOperation) {
        Switch on invocableDmlOperation {
            when 'Insert', 'insert' {
            	return DmlType.DMLINSERT;
            } when 'Update', 'update' {
            	return DmlType.DMLUPDATE;
            } when 'Delete', 'delete' {
            	return DmlType.DMLDELETE;
            } when else {
                throw new IllegalArgumentException('Invalid DML Operation.');
            }
        }
    }
    
    public class InvocableInput {
        @InvocableVariable(label='SObjects' description='Records to perform Batch DML on' required=true)
        public List<Sobject> sobjects;
        @InvocableVariable(label='DML Operation' description='Insert, Update, or Delete' required=true)
        public String dmlOperation;
        @InvocableVariable(label='Records Per Transaction' description='Maximum Number of Records per Transaction' required=true)
        public Integer recordsPerTransaction;
        
    }
}