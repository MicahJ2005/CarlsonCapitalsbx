/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Scheduled_FlowTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Scheduled_FlowTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Scheduled_Flow__c());
    }
}