global class restEngine {
    
    public static Prolytics__c settings = Prolytics__c.getOrgDefaults();
    
    public static string oid = userInfo.getOrganizationId().left(15);
    
    private static String clientId = settings.Consumer_Key__c;
    private static String clientSecret = settings.Client_Secret__c;
    private static String username = settings.Username__c;
    private static String password = settings.password__c + settings.Security_Token__c;
    
    public static string url = 'https://na24.salesforce.com/services';
    
    public static List<record> recList {get;set;}
    
    public record projectRec {get;set;}
    public record invoiceRec {get;set;}
    public record opportunityRec {get;set;}
    
    public class deserializeResponse{
        
        // token values
        public String id;
        public String access_token;
        
        // sObject records
        public List<record> records;
        
        // single records
        public record project;
        public record invoice;
        public record opportunity;
               
    }
    
    // sObject record values
    public class record {
        public string id{get;set;}
        public string name{get;set;}
        
        // project fields
        public string SOW_c{get;set;}
        public string short_description_c{get;set;}
        public string StageName{get;set;}
        public string Remaining_Hours_c{get;set;}
        
        // invoice fields
        public string Date_c {get;set;}
        public string Due_Date_c {get;set;}
        public string Status_c {get;set;}
        public string Opportunity_c {get;set;}
    }
    
    public static String ReturnAccessToken(){
        
        String reqbody = 'grant_type=password&client_id='+clientId+'&client_secret='+clientSecret+'&username='+username+'&password='+password;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqbody);
        req.setMethod('POST');
        req.setEndpoint(url + '/oauth2/token');
        
        system.debug(req);
        
        HttpResponse res = h.send(req);
        deserializeResponse resp = (deserializeResponse)JSON.deserialize(res.getbody(),deserializeResponse.class);
        
        return resp.access_token;
    }
    
    public static list<record> restQuery(string queryString){
        
        string accessToken = returnAccessToken();
        
        if(accessToken != null){

            Http h2 = new Http();
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization','Bearer ' + accessToken);
            req.setHeader('Content-Type','application/json');
            req.setHeader('accept','application/json');
          
            req.setMethod('GET');
            req.setEndpoint(url + '/data/v34.0/query/?q='+encodingUtil.urlEncode(queryString, 'UTF-8'));
            
            HttpResponse res = h2.send(req);
            
            deserializeResponse resp = (deserializeResponse)JSON.deserialize(res.getBody().replaceAll('__c', '_c'),deserializeResponse.class);
            
            system.debug(res.getBody());
            system.debug(resp.records);
            //system.debug(resp.name);
            return resp.records;

        }
        
        return null;
    }
    
    // project query
    public static pagereference projectQuery(){
        recList = new List<record>();
        
        for(record r : restQuery('SELECT Name, Amount, SOW__c, Short_Description__c, StageName, Remaining_Hours__c FROM Opportunity WHERE Account.Org_Id__c = \'00D28000000Invd\' ORDER BY CreatedDate DESC')){
            recList.add(r);
        }
		return null;
    }
    
    // invoice query
    public static pagereference invoiceQuery(){
        recList = new List<record>();
        
        for(record r : restQuery('SELECT Name, Id, Due_Date__c, Date__c, Status__c, Opportunity__c FROM Invoice__c WHERE Account__r.Org_Id__c = \'00D28000000Invd\' AND Status__c != \'Draft\' AND Status__c != \'Approved\' ORDER BY Due_Date__c DESC')){
            recList.add(r);
        }
		return null;
    }
    
    public static pagereference project(){
        
        return null;
    }
    
    public static pagereference invoice(){
        
        return null;
    }
    
    
}