global class InvoiceGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer recordsProcessed = 0;
    private Integer recordsFailed = 0;
    private static List<Invoice_Error_Log__c> logsToInsert = new List<Invoice_Error_Log__c>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query Orders with status 'Activated' and no Invoice yet
        return Database.getQueryLocator([
            SELECT Id, Name,TotalAmount,(SELECT Id, Product2Id, Quantity, UnitPrice,TotalPrice FROM OrderItems)
            FROM Order
            WHERE Status = 'Activated' 
            AND Id NOT IN (SELECT Order__c FROM Invoice__c )
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Order> orders) {
        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        List<Invoice_Line__c> lineItemsToInsert = new List<Invoice_Line__c>();
    try{
        
        for(Order ord : orders) {
            Invoice__c inv = new Invoice__c(
                Order__c = ord.Id,
                Total_Amount__c = ord.TotalAmount,
                Invoice_Generated_Time__c = DateTime.now() 
                
            );
            invoicesToInsert.add(inv);
        }
        
        if(!invoicesToInsert.isEmpty()) {
            insert invoicesToInsert;
            
            // Create line items
            for(Integer i = 0; i < orders.size(); i++) {
                for(OrderItem oi : orders[i].OrderItems) {
                    Invoice_Line__c ili = new Invoice_Line__c(
                        Invoice__c = invoicesToInsert[i].Id,
                        Order_Product__c = oi.Id,
                        Product__c = oi.Product2Id,
                        Quantity__c = oi.Quantity,
                        Unit_Price__c = oi.UnitPrice,
                        Total_Price__c = oi.TotalPrice
                    );
                    lineItemsToInsert.add(ili);
                }
            }
            
            if(!lineItemsToInsert.isEmpty()) {
                insert lineItemsToInsert;
            }
            
            recordsProcessed += orders.size();
        }
        Invoice_Error_Log__c iel = new Invoice_Error_Log__c(
            Status__c = 'Success',
            Records_Processed__c = recordsProcessed,
            Run_Time__c = DateTime.now()
        );
        logsToInsert.add(iel);
        
    }catch(Exception e) {
        recordsFailed += orders.size();
        Invoice_Error_Log__c iel = new Invoice_Error_Log__c(
            Status__c = 'Error',
            Error_Message__c = e.getMessage(),
            Run_Time__c = DateTime.now(),
            Records_Processed__c = recordsProcessed
        );
        logsToInsert.add(iel);
        }
        
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Post-processing or notifications
        if(!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
}