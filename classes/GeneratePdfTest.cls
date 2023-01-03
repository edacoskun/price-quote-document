@isTest
public class GeneratePdfTest {
    @testSetup
    static void setupTestData() 
    {
        Account accRecord = new Account();
        accRecord.Name = 'Test Acc';
        insert accRecord;

        Contact conRecord = new Contact();
        conRecord.Lastname = 'test';
        conRecord.Email = 'test@test.com';
	insert conRecord;

        Opportunity oppRecord = new Opportunity();
        oppRecord.AccountId = accRecord.Id;
        oppRecord.Name = 'Test Opp';
        oppRecord.Currency__c = 35;
        oppRecord.Amount = 1000;
        oppRecord.StageName = 'Prospecting';
        oppRecord.CloseDate = Date.today();
        oppRecord.OwnerId = UserInfo.getUserId();
        insert oppRecord;
    
        Product2 prodInstance = new Product2();
        prodInstance.Name = 'Instance Prod';
        prodInstance.ProductCode = 'XPro';
        prodInstance.isActive = true;
        insert prodInstance;
    
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Pricebook2Id = test.getStandardPricebookId();
        pbEntry.Product2Id = prodInstance.Id;
        pbEntry.UnitPrice = 85.00;
        pbEntry.IsActive = true;
        insert pbEntry;
    
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.OpportunityId = oppRecord.Id;
        oppLineItem.PricebookEntryId = pbEntry.Id;
        oppLineItem.Quantity = 6;
        oppLineItem.TotalPrice = oppLineItem.Quantity * pbEntry.UnitPrice;
        insert oppLineItem;
    }

    @isTest
    public static void testSuccessQuery()
    {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name='Test Opp' LIMIT 1];
        
        test.StartTest();

        PageReference pageRef = Page.samplePdf;
        pageRef.getparameters().put('comment', 'eda');
        pageRef.getparameters().put('id', String.valueOf(opp.Id));
        test.setCurrentPage(pageRef);

        GeneratePdfController testSamlpePdf = new GeneratePdfController();
        testSamlpePdf.getOppProduct();
        
        test.StopTest();
    } 

    @isTest
    public static void testFailedQuery()
    {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        
        test.StartTest();

        PageReference pageRef = Page.samplePdf;
        pageRef.getparameters().put('comment', '');
        pageRef.getparameters().put('id', 'abc');
        test.setCurrentPage(pageRef);

        GeneratePdfController testSamlpePdf = new GeneratePdfController();
        testSamlpePdf.getOppProduct();
         
        test.StopTest();
    } 

    @isTest
    public static void testGetPdf()
    {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        
        test.StartTest();

        PageReference pageRef = Page.samplePdf;
        pageRef.getparameters().put('comment', '');
        pageRef.getparameters().put('id', String.valueOf(opp.Id));
        test.setCurrentPage(pageRef);

        GeneratePdfController.getPdf(String.valueOf(opp.Id), 'test comment');
         
        test.StopTest();
    } 

    @isTest
    public static void testFailedGetPdf()
    {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        
        test.StartTest();

        PageReference pageRef = Page.samplePdf;
        pageRef.getparameters().put('comment', '');
        pageRef.getparameters().put('id', String.valueOf(opp.Id));
        test.setCurrentPage(pageRef);

        Blob b;

        GeneratePdfController.getPdf(String.valueOf(opp.Id), 'test comment');
         
        test.StopTest();
    } 

    @isTest 
    public static void testSendEmail() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        test.StartTest();

        PageReference pageRef = Page.samplePdf;
        pageRef.getparameters().put('id', String.valueOf(opp.Id));
        pageRef.getparameters().put('comment', 'test comment');
        test.setCurrentPage(pageRef);

        List<String> testToAddress = new List<String>();
        testToAddress.add('edacoskun@gmail.com');

        GeneratePdfController.sendEmail(testToAddress, String.valueOf(opp.Id), 'test comment');

        test.StopTest();
    } 
  
    @isTest 
    public static void testFailedSendEmail() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        test.StartTest();

        PageReference pageRef = Page.samplePdf;
        pageRef.getparameters().put('id', String.valueOf(opp.Id));
        pageRef.getparameters().put('comment', 'test comment');
        test.setCurrentPage(pageRef);

        List<String> testToAddress = new List<String>();

        GeneratePdfController.sendEmail(testToAddress, String.valueOf(opp.Id), 'test comment');

        test.StopTest();
    } 

    @isTest
    public static void testSavePdf() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        test.StartTest();
        
        ContentVersion content = new ContentVersion(); 
        content.ContentLocation = 'S';
        content.Title='test title'; 
        content.PathOnClient = '/' + content.Title + '.pdf'; 
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData = bodyBlob; 

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = opp.Id;
        contentlink.contentdocumentid = [SELECT contentdocumentid FROM contentversion WHERE Id =: content.Id].contentdocumentid;
        contentlink.ShareType = 'I'; // Inferred permission
        contentlink.Visibility = 'AllUsers';

        GeneratePdfController.saveInSalesforce(String.valueOf(opp.Id), 'test comment');

        test.StopTest();
    }

    @isTest
    public static void testFailedSavePdf() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        test.StartTest();

        ContentVersion conVer = new ContentVersion(); 
        conVer.ContentLocation = 'S'; // Salesforce
        conVer.Title = 'Price Quote';
        conVer.PathOnClient = '/' + conVer.Title + '.pdf';
        conVer.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = null;
        contentlink.contentdocumentid = conDoc;


        GeneratePdfController.saveInSalesforce(String.valueOf(opp.Id), 'test comment');

        test.StopTest();
    }
   
}
