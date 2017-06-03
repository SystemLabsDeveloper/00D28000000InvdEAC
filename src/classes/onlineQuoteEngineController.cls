public class onlineQuoteEngineController {
    
    public string AccountName {get;set;}
    public string AccountSize {get;set;}
    
    public string ContactFirstName {get;set;}
    public string ContactLastName {get;set;}
    public string ContactEmail {get;set;}
    
    public PageReference saveContactDetails(){
        
        Account acc = new Account();
        Contact con = new Contact();
        
        // check for duplicate account
        List<Account> dupeAcc = [select Id from Account where Name = :AccountName order by CreatedDate DESC];
        
        if(dupeAcc.size() != 0){
            acc.Id = dupeAcc[0].Id;
            
        } else {
            acc.Name = AccountName;
        }
        
        // check for duplicate account
        List<Contact> dupeCon = [select Id from Contact where email = :ContactEmail order by CreatedDate DESC];
        
        if(dupeCon.size() != 0){
            con.Id = dupeCon[0].Id;
            
        } else {
            con.AccountId = acc.Id;
            con.FirstName = ContactFirstName;
            con.LastName = ContactLastName;
            con.Email = ContactEmail;
        }

        try{
            database.upsert(acc);
            database.upsert(con);
        } catch (exception e){
            
        }
        
        return null;
        
    }

}