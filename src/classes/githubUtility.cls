public class githubUtility {
    
    public static Organization org = [select Id, Name, isSandbox, NamespacePrefix from Organization limit 1];
    private static GitHubSyncSettings__c api {
        get {
            return GitHubSyncSettings__c.getOrgDefaults();
        }
    }
 
    public static string payload;
    
    public static string latestCommitSha;
    public static string baseTreeSha;
    public static string newTreeSha;
    public static string newcommitSha;
    
    public static string doExecuteCallout(string method, string resource, map<string,string> params){
        
        system.debug('@@@@ username : password : ' +api.Username__c + ' : ' + api.token__c);
        
        string endpoint = 'https://api.github.com';
        
        if(resource.startsWith('/')){
            resource = resource.removeStart('/');
        }
        
        if(resource != null){
            endpoint += '/' + resource;
        }
        
        if(!params.keySet().isEmpty()){
            endpoint += '?';
            
            for(string s : params.keySet()){
                endpoint += s + '=' + params.get(s) + '&';
            }
        
            endpoint.removeEnd('&');
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        
        Blob headerValue = Blob.valueOf(api.Username__c + ':' + api.token__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        system.debug('Sending ' + method + ' request to ' + endpoint);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return res.getBody();
        
    }
    
    // POST callout
    public static string doExecuteCallout(string method, string resource, string body){
        
        string endpoint = 'https://api.github.com';
        
        if(resource.startsWith('/')){
            resource = resource.removeStart('/');
        }
        
        if(resource != null){
            endpoint += '/' + resource;
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setBody(body);
        
        system.debug('@@@@ username : password : ' +api.Username__c + ' : ' + api.token__c);
        
        Blob headerValue = Blob.valueOf(api.Username__c + ':' + api.token__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        system.debug('Sending ' + method + ' request to ' + endpoint + '(Request Body: ' + body + ')');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return res.getBody();
        
    }
  
    public static void getLatestCommit(){
        payload = githubUtility.doExecuteCallout('GET', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/refs/heads/master', params);
        
        string shaLatestCommit;
        
        JSONParser parser = JSON.createParser(payload);
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == 'sha')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    latestCommitSha = parser.getText();
                }
        }
        
        system.debug('latestCommitSha : ' + latestCommitSha);
        //return shaLatestCommit;
        
    }
    
    public static void getBaseTree(){
        
        payload = githubUtility.doExecuteCallout('GET', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/commits/' + latestCommitSha, params);
        
        string shaBaseTree;
        
        JSONParser parser = JSON.createParser(payload);
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'tree')) {
                // Get the value.
                parser.nextToken();
                parser.nextToken();
                parser.nextToken();
                baseTreeSha = parser.getText();
            }
        }
        
        system.debug('baseTreeSha : ' + baseTreeSha);
        //return shaBaseTree;
    }
    
    public static map<string,string> params = new map<string,string>();
}