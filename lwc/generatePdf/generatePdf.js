import { LightningElement, api, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getInfo from '@salesforce/apex/GeneratePdfController.getPdf';
import sendEmail from '@salesforce/apex/GeneratePdfController.sendEmail';
import savePdf from '@salesforce/apex/GeneratePdfController.saveInSalesforce';

export default class generatePdf extends NavigationMixin(LightningElement) {
  @api invoke() {}
  
  @track bShowModal = false;
  @api recordId;

  comment;
  @track email = '';

  handleEmailChange(event) {
    if (event.target.name === 'emailAddress') {
      this.email = event.target.value;
    }
  }

  handleCommentChange(event) {
    this.comment = event.target.value;
  }

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  savePdfModal() {
    this.bShowModal = true;
  }
  
  closeModal() {
    this.bShowModal = false;
  }

  generatePdfModal() {
    if(this.comment == null || this.comment == 'undefined' || this.comment == undefined) {
      this.comment = ' ';
    }else {
      this[NavigationMixin.GenerateUrl]({
        type: 'standard__webPage',
        attributes: {
          url: '/apex/samplePdf?id=' + this.recordId + '&comment=' + this.comment
        }
      }).then(generatedUrl => {
        window.open(generatedUrl);
      });
    }
  }  

  getRecordId() {
    getInfo({ recordId: this.recordId, customerComment: this.comment });
  }

  sendEmailHandler(evt) {
    // send mail
    console.log("Sending email to: ", this.email);
    sendEmail({ toAddress: this.email, recordId: this.recordId, customerComment: this.comment });
  }

  savePdfToSalesforce() {
    // save pdf
    savePdf({ recordId: this.recordId, customerComment: this.comment });
  }
}