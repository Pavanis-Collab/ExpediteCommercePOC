@isTest
private class InvoiceGeneratorBatchTest {
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        insert accounts;
        
        // Create test products
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 10; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                IsActive = true
            ));
        }
        insert products;
        
        // Create pricebook entries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        for(Product2 prod : products) {
            pricebookEntries.add(new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert pricebookEntries;
        
        // Create orders with order items
        List<Order> orders = new List<Order>();
        for(Account acc : accounts) {
            orders.add(new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = Test.getStandardPricebookId()
            ));
        }
        insert orders;
        
        
        // Create order items
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Order ord : orders) {
            // Create 2-3 order items per order
            for(Integer i = 0; i < 3; i++) {
                orderItems.add(new OrderItem(
                    OrderId = ord.Id,
                    PricebookEntryId = pricebookEntries[i].Id,
                    Quantity = 1,
                    UnitPrice = 100
                ));
            }
        }
        insert orderItems;
        
    }
    
    @isTest
    static void testBatchProcessing() {
        // Get the count of orders before processing
        List<Order> orders = [Select Id from Order where Status = 'Draft'];
        for(Order ord: orders){
            ord.Status = 'Activated';
        }
        update orders;
        Test.startTest();
        // Execute the batch
        InvoiceGeneratorBatch batch = new InvoiceGeneratorBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify results
        // 1. Check if invoices were created
        List<Invoice__c> invoices = [SELECT Id, Order__c, Total_Amount__c FROM Invoice__c];
        System.assertEquals(5, invoices.size(), 'Number of invoices should match number of orders');
        
        // 2. Check if invoice line items were created
        List<Invoice_Line__c> lineItems = [SELECT Id, Invoice__c FROM Invoice_Line__c];
        System.assertEquals(5 * 3, lineItems.size(), 'Number of line items should match number of order items');
        
        // 3. Verify the amounts
        for(Invoice__c inv : invoices) {
            Order ord = [SELECT TotalAmount FROM Order WHERE Id = :inv.Order__c];
            System.assertEquals(ord.TotalAmount, inv.Total_Amount__c, 'Invoice amount should match order amount');
        }
        
        // 4. Check process logs
        List<Invoice_Error_Log__c> logs = [
            SELECT Id, Status__c, Records_Processed__c 
            FROM Invoice_Error_Log__c 
            WHERE Status__c='Success' order by Run_Time__c DESC
        ];
        System.assert(!logs.isEmpty(), 'Error logs should be created');
        System.assertEquals('Success', logs[0].Status__c, 'Process should complete successfully');
        System.assertEquals(5, logs[0].Records_Processed__c, 'All orders should be processed');
    }
    @isTest
    static void testBatchWithNoOrders() {
        // Create a test order without order items to force an error
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Order> ord = [Select Id from Order where Status = 'Activated' limit 1];
       
        Test.startTest();
        InvoiceGeneratorBatch batch = new InvoiceGeneratorBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify error log was created
        List<Invoice__c> invoices = [
            SELECT Id
            FROM Invoice__c order by Invoice_Generated_Time__c DESC
        ];
        System.assertEquals(invoices.size(), 0);
    }
    
    
}