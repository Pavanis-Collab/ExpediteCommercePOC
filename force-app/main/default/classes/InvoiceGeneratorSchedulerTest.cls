@isTest
private class InvoiceGeneratorSchedulerTest {
    @isTest
    static void testSchedulerExecution() {
        // Create test data if needed
        Test.startTest();
        
        // Schedule the job
        String jobId = System.schedule('Test Invoice Generator Schedule', 
            '0 0 0 * * ?', // Run at midnight every day
            new InvoiceGeneratorScheduler());
            
        // Verify the job was scheduled
        List<CronTrigger> jobs = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                                FROM CronTrigger 
                                WHERE Id = :jobId];
        
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
        System.assertEquals('0 0 0 * * ?', jobs[0].CronExpression, 'Cron expression should match');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Execute the scheduler directly
        InvoiceGeneratorScheduler scheduler = new InvoiceGeneratorScheduler();
        scheduler.execute(null);
        
        // Verify that the batch job was queued
        AsyncApexJob[] jobs = [SELECT Id, Status, NumberOfErrors 
                             FROM AsyncApexJob 
                             WHERE ApexClass.Name = 'InvoiceGeneratorBatch'
                             ORDER BY CreatedDate DESC 
                             LIMIT 1];
        
        System.assertEquals(1, jobs.size(), 'Batch job should be queued');
        System.assertEquals('Queued', jobs[0].Status, 'Batch job should be queued');
        
        Test.stopTest();
    }
} 