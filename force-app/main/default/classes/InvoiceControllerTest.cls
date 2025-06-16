@isTest
private class InvoiceControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Create order
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;
        
        // Create order item
        OrderItem orderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert orderItem;
        
        // Activate the order
        testOrder.Status = 'Activated';
        update testOrder;
    }
    
    @isTest
    static void testRunNow() {
        Test.startTest();
        InvoiceController.runNow();
        Test.stopTest();
        
        // Verify that an invoice was created
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        System.assertEquals(1, invoices.size(), 'One invoice should be created');
        
        // Verify that an error log was created
        List<Invoice_Error_Log__c> logs = [SELECT Id, Status__c FROM Invoice_Error_Log__c];
        System.assertEquals(1, logs.size(), 'One error log should be created');
        System.assertEquals('Success', logs[0].Status__c, 'Process should complete successfully');
    }
    
    @isTest
    static void testGetLastRun() {
        // Create a test error log
        Invoice_Error_Log__c testLog = new Invoice_Error_Log__c(
            Status__c = 'Success',
            Run_Time__c = DateTime.now(),
            Records_Processed__c = 1
        );
        insert testLog;
        
        Test.startTest();
        Invoice_Error_Log__c result = InvoiceController.getLastRun();
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Success', result.Status__c, 'Status should match');
        System.assertEquals(testLog.Id, result.Id, 'Should return the most recent log');
    }
}