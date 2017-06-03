@isTest
public class test_ABNLookupController {
    
    public static Account a;
    
    public static testmethod void init(){
        a = new Account();
        a.Name = 'SystemLabs';
        insert a;
    }
    
    public static testmethod void testABNLookup(){
         
        //a = [select Id, Name from Account limit 1];
        init();

        test.setMock(HttpCalloutMock.class, new ABNLookupMockResponse());
        
        ApexPages.StandardController stdCon = new ApexPages.StandardController(a);
        ABNLookupController con = new ABNLookupController(stdCon);
        
        test.setCurrentPage(Page.ABNLookupPage);
        
        con.getABNResults();
        
        con.selectedABN = '12 234 234 1234';
        con.selectedLegalName = 'SystemLabs Pty Ltd'; 
        
        con.selectABN();

    }

}