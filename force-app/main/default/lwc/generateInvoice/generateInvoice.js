import { LightningElement,wire } from 'lwc';
import runNow from '@salesforce/apex/InvoiceController.runNow';
import getLastRun from '@salesforce/apex/InvoiceController.getLastRun';

export default class GenerateInvoice extends LightningElement {
    lastRun;

    @wire(getLastRun)
    wiredLog({ error, data }) {
        if (data) this.lastRun = data;
    }

    handleRunNow() {
        runNow().then(() => {
            this.template.querySelector('lightning-button').label = 'Run Again';
        });
    }
}