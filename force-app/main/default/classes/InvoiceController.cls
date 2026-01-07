public with sharing class InvoiceController {
   @auraEnabled
   public static void runNow(){
    Database.executeBatch(new InvoiceGeneratorBatch());
   }

   
   @auraEnabled(cacheable=true)
   public static Invoice_Error_Log__c getLastRun(){
    return [SELECT Id, Run_Time__c, Status__c FROM Invoice_Error_Log__c ORDER BY Run_Time__c DESC LIMIT 1];
   }
}