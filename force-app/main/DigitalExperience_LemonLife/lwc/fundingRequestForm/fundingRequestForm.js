import {LightningElement} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import AMOUNT_FIELD                from '@salesforce/schema/Funding_Request__c.Amount__c';
import APPLICANT_FIRST_NAME_FIELD  from '@salesforce/schema/Funding_Request__c.Applicant_First_Name__c';
import APPLICANT_LAST_NAME_FIELD   from '@salesforce/schema/Funding_Request__c.Applicant_Last_Name__c';
import APPLICANT_EMAIL_FIELD       from '@salesforce/schema/Funding_Request__c.Applicant_Email__c';
import PENNSYLVANIA_RESIDENT_FIELD from '@salesforce/schema/Funding_Request__c.Pennsylvania_Resident__c';

export default class FundingRequestForm extends LightningElement {

    objectApiName;
    fields;
    
    constructor() {
        super();
        try {
            this.objectApiName = AMOUNT_FIELD.objectApiName;
            this.fields = [
                AMOUNT_FIELD,
                APPLICANT_FIRST_NAME_FIELD,
                APPLICANT_LAST_NAME_FIELD,
                APPLICANT_EMAIL_FIELD,
                PENNSYLVANIA_RESIDENT_FIELD,
            ];
        } catch (error) {
            console.log(`MATDEV issue invoking imported fields: `+ error);
        }
    }

    showForm = true;

    handleSubmit(event) {
        const fields = event.detail.fields;
        // console.log(`MATDEV fields`, JSON.stringify(fields));
        const isPaResident = fields[PENNSYLVANIA_RESIDENT_FIELD.fieldApiName];
        if(isPaResident) {
            let form = this.template.querySelector("lightning-record-form");
            form.submit();
            this.showForm = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    variant: 'success',
                    title: 'Thank you, your application is being reviewed',
                    message: 'You will receive an email with our decision',
                    mode: 'dismissable'
                })
            );
        } else {
            event.preventDefault();
            this.dispatchEvent(
                new ShowToastEvent({
                    variant: 'info',
                    title: 'Application Denied',
                    message: 'Funds are only available for Pennsylvania residents',
                    mode: 'sticky'
                })
            );
        }
    }

}