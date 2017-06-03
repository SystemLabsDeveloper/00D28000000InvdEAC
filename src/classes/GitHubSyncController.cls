global without sharing class GitHubSyncController {

    // GET callout
    global static string doExecuteCallout(string username, string token, string method, string resource, map<string,string> params){
        
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
        
        Blob headerValue = Blob.valueOf(username + ':' + token);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        system.debug('Sending ' + method + ' request to ' + endpoint);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return res.getBody();
        
    }
    
    // POST callout
    global static string doExecuteCallout(string username, string token, string method, string resource, string body){
        
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
        
        Blob headerValue = Blob.valueOf(username + ':' + token);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        system.debug('Sending ' + method + ' request to ' + endpoint + '(Request Body: ' + body + ')');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
       return res.getBody();
        
    }

    @AuraEnabled
    global static GitHubSyncSettings__c getSettings(){
        return GitHubSyncSettings__c.getOrgDefaults();
    }
     
    @AuraEnabled
    global static GitHubSyncSettings__c saveGitHubSettings(string settingId, string token){
        
        system.debug('SettingId : ' + settingId);
        system.debug('Token : ' + token);

    	GitHubSyncSettings__c settings = new GitHubSyncSettings__c();
        
        if(settingId != '')
            settings.Id = settingId;
        
        settings.Token__c = token;
        
        database.upsert(settings);
        return settings;
    }
    
    global static map<string,string> params = new map<string,string>();
    
    private static final Integer METADATA_API_VERSION = 
        Integer.valueOf(new MetadataService.MetadataPort().endpoint_x.substringAfterLast('/'));
    
    //@AuraEnabled
    //global static List<commits> commitList {get;set;}
    //public static string commitMessage {get;set;}

    global class commits {
        
        @AuraEnabled
        global String sha {get;set;}
        
        @AuraEnabled
        global cls_commit commit_x {get;set;}
    }
    
    global class cls_commit {
        
        @AuraEnabled
        global cls_author author {get;set;}
        
        @AuraEnabled
        global string message {get;set;}
        
        @AuraEnabled
        global tree tree {get;set;}
    }
    
    global class tree {
        
    }
    
    global class cls_author {
        
        @AuraEnabled
        global String date_x {get;set;}
        
        @AuraEnabled
        global string name {get;set;}
        
        @AuraEnabled
        global string getdate_x_formatted(){
            TimeZone tz = UserInfo.getTimeZone();
            
            datetime date_x_datetime = datetime.valueOf(date_x.replace('T',' ').replace('Z', ' '));
            date_x_dateTime = date_x_datetime.addSeconds(tz.getOffset(date_x_datetime)/1000);
            
            return date_x_datetime.format('MMM d') + ', '  + date_x_datetime.format('h:mma');
        }
    }
    
    @AuraEnabled
    global static List<commits> getRepoCommits(string username, string token){ 
        string payload = doExecuteCallout(username, token, 'GET', 'repos/SystemLabsDeveloper/' + UserInfo.getOrganizationId() + '/commits', params);
        payload = payload.replaceAll('"commit"','"commit_x"').replaceAll('"date"', '"date_x"');
        
        List<commits> commitList = (List<commits>)JSON.deserialize(payload, List<commits>.class);
        
        system.debug('commitList : ' + commitList);
        return commitList;
    }
    
    @AuraEnabled
    global static string doCommitAll(string username, string password){

        string latestCommit = getLatestCommit(username, password);
        string baseTree = getBaseTree(username, password, latestCommit);
        
        return null;
    }
    
    public static string getLatestCommit(string username, string password){
        string payload = doExecuteCallout(username, password, 'GET', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/refs/heads/master', params);
        string latestCommitSha;
        
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
        return latestCommitSha;
        
    }
    
    public static string getBaseTree(string username, string password, string latestCommitSha){
        
        string payload = doExecuteCallout(username, password, 'GET', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/commits/' + latestCommitSha, params);
        
        string baseTreeSha;
        
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
        return baseTreeSha;
    }
    
    public class newTree {
        string base_tree {get;set;}
        List<element> tree {get;set;}
    }
    
    public class element {
        public string path {get;set;}
        public string mode = '100644';
        public string type = 'blob';
        public string content {get;set;}
    }
    
    public static newTree tree {get;set;}
    
    public static MetadataService.MetadataPort createService() {
        
        String content = Page.SessionId.getContent().toString();
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                e = content.indexOf('End_Of_Session_Id');

        system.debug('@@@@ Page.SessionId.getContent().toString() : ' + Page.SessionId.getContent().toString());
        
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = content.substring(s, e);
        
        return service; 
    }
    
    @AuraEnabled
    global static string doRequestMetadata(string[] elementTypes) {
        
        system.debug('ELEMENT TYPEs : ' + elementTypes);
        
        MetadataService.AsyncResult AsyncResult;
        
        // Construct unmanaged package with list of desired components to retrieve in zip
        MetadataService.MetadataPort service = createService();				
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion = METADATA_API_VERSION;
        retrieveRequest.packageNames = null;
        retrieveRequest.singlePackage = true;
        retrieveRequest.specificFiles = null;
        retrieveRequest.unpackaged = new MetadataService.Package_x();
        retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        
        for(string elementType : elementTypes){
            retrieveRequest.unpackaged.types.add(
                generatePackageTypes(elementType)
            );
        }

        AsyncResult = service.retrieve(retrieveRequest);
        return AsyncResult.Id;
        
    }
 
    @AuraEnabled
    public static transient string zipFileContent {get;set;}

    @AuraEnabled
    public static MetadataService.RetrieveResult getRequestStatus(string requestId){
        MetadataService.MetadataPort service = createService();
        
        system.debug('@@@@ checking status of ' + requestId);
	
        MetadataService.RetrieveResult requestResult = service.checkRetrieveStatus(requestId, true);
        
        system.debug('@@@@ requestResult: ' + requestResult);
        
        if(requestResult.status == 'Succeeded')
            zipFileContent = requestResult.zipFile;
        
        return requestResult;
    }
    
    @AuraEnabled
    public static AsyncApexJob getBatchProgress(string requestId){
        AsyncApexJob batch = [select Id, Status, TotalJobItems, JobItemsProcessed, NumberOfErrors 
                              from AsyncApexJob
                              where Id = :requestId
                              limit 1];
        
        return batch;
    }

    private static MetadataService.PackageTypeMembers generatePackageTypes(string typeName){
        
        MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
        packageType.name = typeName; 

        packageType.members = new List<String>();

        set<string> exclusionSet = new set<string>();
            exclusionSet.add('MetadataService');
            exclusionSet.add('ToolingAPIWSDL'); 

        string q = 'select Name from ' + typeName + ' where Name not in :exclusionSet';

       List<sObject> elements = database.query(q);


        for(sObject obj : elements){
            packageType.members.add(string.valueOf(obj.get('Name')));
        }

        return packageType;
        
    }
    
    @AuraEnabled
    public static string getBatchId(string zipFile, string commMsg){
        batchCommitController con = new batchCommitController(zipFile, commMsg);
        return string.valueOf(database.executeBatch(con, 5));
    }
}