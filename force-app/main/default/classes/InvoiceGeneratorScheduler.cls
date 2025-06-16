global class InvoiceGeneratorScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        InvoiceGeneratorBatch batch = new InvoiceGeneratorBatch();
        Database.executeBatch(batch, 200);
    }
}