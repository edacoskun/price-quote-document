public class GeneratePdfController {
    
  public List<OpportunityLineItem> oppLineItem { get; set; }
  public Opportunity opportunity { get; set; }
  public String currentRecordId { get; set; }
  public String comment { get; set; }
 
  public GeneratePdfController() {
    currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
    comment = ApexPages.currentPage().getparameters().get('comment');

    getOppProduct();
  }

  public void getOppProduct() { 
    currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
    comment = ApexPages.currentPage().getparameters().get('comment');
    System.debug('Id: ' + currentRecordId);
    System.debug('URL: ' + Apexpages.currentPage().getUrl());
    try {
      if(String.isNotBlank(currentRecordId)) {
        oppLineItem = [SELECT Id, Name, 
                              Opportunity.Name, Opportunity.Currency__c, 
                              Opportunity.Amount, Opportunity.CloseDate, 
                              Opportunity.OwnerId, Opportunity.Owner.Name, 
    
                              Opportunity.Account.Name, Opportunity.Account.Phone, 
                              Opportunity.Account.Website, Opportunity.Account.BillingStreet, 
                              Opportunity.Account.BillingCity, Opportunity.Account.BillingPostalCode,
    
                              PricebookEntry.Id, PricebookEntry.UnitPrice, PricebookEntry.Product2Id, 
                              PricebookEntry.Product2.Name, PricebookEntry.ProductCode, 
                              Quantity, TotalPrice
                       FROM   OpportunityLineItem
                       WHERE  OpportunityId = :currentRecordId];
        opportunity = oppLineItem[0].Opportunity;
        System.debug('oppLineItem: ' + oppLineItem.size());
        System.debug('opportunity: ' + opportunity);
      }
      if(oppLineItem.size() == 0) {}
    } 
    catch(Exception e) {
      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Query error:  ' + e.getMessage())); 
      System.debug('Error:  ' + e.getMessage());
    }
  } 

  @AuraEnabled
  public static Blob getPdf(String recordId, String customerComment) {
      System.debug('Record Id for Attachment: ' + recordId);
      System.debug('Comment: ' + customerComment);

      // reference the attachment page and pass in the ID
      PageReference pdf = Page.samplePdf;
      pdf.getParameters().put('id', recordId); 
      pdf.getParameters().put('comment', customerComment);
      pdf.setRedirect(true);

      // take the PDF content
      Blob b = pdf.getContent();
      
      return b;
  }

  @AuraEnabled
  public static void sendEmail(List<String> toAddress, String recordId, String customerComment) {
    Blob b = getPdf(recordId, customerComment);

    System.debug('Record Id for Attachment: ' + recordId);
    System.debug('Comment: ' + customerComment);

    try {
      // create email
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

      System.debug('Email Address: ' + toAddress);
      email.setToAddresses(toAddress);

      email.setReplyTo('edacoskun42.ec@gmail.com');
      email.setSenderDisplayName('Salesforce');
      email.setBccSender(false);
      email.setUseSignature(false);

      email.setSubject('Price Quote');
      String body = 'A price quote pdf has been created for the opportunity product. I am sharing the pdf with you in attachment.';
      email.setHtmlBody(body);

      Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
      fileAttachment.setFileName('PriceQuote.pdf');

      fileAttachment.Body = b;

      email.setFileAttachments(new Messaging.EmailFileAttachment[] { fileAttachment });

      // send email
      Messaging.SendEmailResult[] result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
    } catch (Exception e) {
      Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Caught email exception: ' + e));
      System.debug('Mail exception: ' + e.getMessage());
    }
  }

  @AuraEnabled
  public static void saveInSalesforce(String recordId, String customerComment) {
    Blob b = getPdf(recordId, customerComment);

    Savepoint savePoint = Database.setSavepoint();

    try {
      // Content Version Record
      ContentVersion fileToUpload = new ContentVersion();
      fileToUpload.ContentLocation = 'S'; // Salesforce
      fileToUpload.Title = 'Price Quote';
      fileToUpload.PathOnClient = '/' + fileToUpload.Title + '.pdf';
      fileToUpload.Origin = 'C';
      fileToUpload.VersionData = b;
      
      insert fileToUpload;
      System.debug('Info: ' + fileToUpload);

      // Create a ContentDocument Link Record
      // First get the content document Id from ContentVersion
      Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileToUpload.Id].ContentDocumentId;
      System.debug('contentDocument Id: ' + contentDocumentId);

      // Create ContentDocumentLink
      ContentDocumentLink linkToRecord = new ContentDocumentLink();
      linkToRecord.ContentDocumentId = contentDocumentId;
      linkToRecord.LinkedEntityId = recordId; // RecordID of the parent
      linkToRecord.ShareType = 'I'; // Inferred permission
      linkToRecord.Visibility = 'AllUsers';

      insert linkToRecord;
    } catch (Exception e) {
      //System.debug('Failed to insert fileToUpload, error is: ' + e.getMessage());
      Database.rollback(savePoint);
      System.debug('Failed to insert linkToRecord, error is: ' + e.getMessage());
    }
  }  
} 