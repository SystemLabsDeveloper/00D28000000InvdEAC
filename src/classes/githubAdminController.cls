global class githubAdminController {
    
    /////////////////////////////////////////////////////////////////////////////
    ////////////////////////////// Utility Methods //////////////////////////////
    /////////////////////////////////////////////////////////////////////////////
    
    public static Organization org = [select Id, Name, isSandbox, NamespacePrefix from Organization limit 1];
    private static GitHub_API_Setting__mdt api = [select Id, Username__c, Password__c from GitHub_Api_Setting__mdt limit 1];
    
    public static string payload;
    
    public void init(){
        // List available Metadata Types via the 'describeMetadata' API call
        MetadataService.MetadataPort service = createService();					
        MetadataService.DescribeMetadataResult describeResult = service.describeMetadata(METADATA_API_VERSION);
        
        allJobsComplete = false;
        
    }
    
    public static void doExecuteCallout(string method, string resource, map<string,string> params){
        
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
        
        Blob headerValue = Blob.valueOf(api.Username__c + ':' + api.Password__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        system.debug('Sending ' + method + ' request to ' + endpoint);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        payload = res.getBody();
        
    }
    
    // POST callout
    public static void doExecuteCallout(string method, string resource, string body){
        
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
        
        Blob headerValue = Blob.valueOf(api.Username__c + ':' + api.Password__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        system.debug('Sending ' + method + ' request to ' + endpoint + '(Request Body: ' + body + ')');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        payload = res.getBody();
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////// Metadata API Methods ////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    
    private static final Integer METADATA_API_VERSION = 
        Integer.valueOf(new MetadataService.MetadataPort().endpoint_x.substringAfterLast('/'));
    
    //public MetadataService.AsyncResult AsyncResult {get; private set;}
    
    public boolean retrievePollerEnabled {get; private set;}
    public boolean batchPollerEnabled {get; private set;}
    
    public boolean allJobsComplete {get; private set;}
    
    public string AsyncId {get; private set;}
    public string batchId {get; private set;}
    
    public integer jobsComplete {get; private set;}
    
    public transient blob zipBlob {get; private set;} 
    
    public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        return service; 
    }
    
    @remoteAction
    public static string requestMetadata() {		
        
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
        
        /*retrieveRequest.unpackaged.types.add(
            generatePackageTypes('ApexClass')
        );*/
        
        // add triggers
        retrieveRequest.unpackaged.types.add(
            generatePackageTypes('ApexTrigger')
        );

        // add static resources
        /*retrieveRequest.unpackaged.types.add(
            generatePackageTypes('StaticResource')
        );
        
        // add pages
        retrieveRequest.unpackaged.types.add(
            generatePackageTypes('ApexPage')
        );*/
        
        AsyncResult = service.retrieve(retrieveRequest);
        return AsyncResult.Id;
        
    }
    
    public static MetadataService.RetrieveResult requestResult {get; set;}
    
    @remoteAction
    public static MetadataService.RetrieveResult getRequestStatus(string requestId){
        MetadataService.MetadataPort service = createService();
        
        requestResult = service.checkRetrieveStatus(requestId, true);
        
        return requestResult;
    }
    
    //public static string jsonBody {get;set;}
    
    public static List<param> jsonParams = new List<param>();
    
    public class param {
        public string key;
        public string value;
    }
    
    @remoteAction
    public static string addParamToMap(string key, string value){

        param p = new param();
        p.key = key;
        p.value = value;

        jsonParams.add(p);
        return p.key + ' added to params list';
    }
    
    @remoteAction
    public static string syncJson(){
        
        return 'There are ' + jsonParams.size() + ' params to sync';
        
        /*string jsonBody = encodingUtil.base64Encode(jsonBlob);
        
        githubUtility.getLatestCommit(); // gets SHA of most recent commit to master branch
        githubUtility.getBaseTree(); // gets sha of master branch tree to use as base
        
        string latestCommitSha = githubUtility.latestCommitSha;
        
        system.debug('jsonBody: ' + jsonBody);
        
        gitHubUtility.payload = githubUtility.doExecuteCallout('POST', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/trees', jsonBody);
        
        JSONParser parser = JSON.createParser(gitHubUtility.payload);
        
        while (parser.nextToken() != null && gitHubUtility.newTreeSha == null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'sha')) {
                // Get the value.
                parser.nextToken();
                githubUtility.newTreeSha = parser.getText();
                break;
            }
        }
        
        system.debug('newTreeSha : ' + gitHubUtility.newTreeSha);
        
        Timezone tz = UserInfo.getTimeZone();
        integer tzOffset = tz.getOffset(system.now());
        
        string requestBody = '{'
            + '"message": "Test Commit - ' + system.now().format('dd/MM/yyyy hh:MM:a') + '",'
            + '"author": {'
            + '"name": "' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '",'
            + '"email": "' + UserInfo.getUserEmail() + '",'
            + '"date": "' + system.now().format('yyyy-MM-dd', 'UTC') + 'T' + system.now().format('HH:mm:ss', 'UTC') + 'Z' + '"'
            + '},'
            + '"parents": ['
            + '"' + latestCommitSha + '"'
            + '],'
            + '"tree": "' + githubUtility.newTreeSha + '"'
            + '}';
        
        
        gitHubUtility.payload = githubUtility.doExecuteCallout('POST', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/commits', requestBody);
        
        parser = JSON.createParser(gitHubUtility.payload);
        
        while (parser.nextToken() != null && gitHubUtility.newCommitSha == null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'sha')) {
                // Get the value.
                parser.nextToken();
                gitHubUtility.newCommitSha = parser.getText();
                break;
            }
        }
        
        requestBody = '{'
            + '"sha": "' + gitHubUtility.newCommitSha + '",'
            + '"force": true'
            + '}';
        
        gitHubUtility.payload = githubUtility.doExecuteCallout('POST', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/refs/heads/master', requestBody); 
        
        system.debug('payload : ' + gitHubUtility.payload);
        
        //gitHubUtility.payload = githubUtility.doExecuteCallout('POST', '/repos/SystemLabsDeveloper/00D28000000InvdEAC/git/trees', jsonBody);
        return gitHubUtility.payload;*/
        
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
    
    @remoteAction
    public static string processZipFile(string encodedZipString){
        
        blob encodedZipBlob = encodingUtil.base64Decode(encodedZipString);
        
        Zippex zip = new Zippex(encodedZipBlob);
        
        tree = new newTree();
        
        tree.base_tree = 'Test Base Tree';
        tree.tree = new list<element>();
        
        for(string s : zip.getFileNames()){
            
            element e = new element();
            e.path = 'src/' + s;
            e.content = zip.getFile(s).toString();
            
            tree.tree.add(e);
        }
        
        string jsonBody = json.serialize(tree);
        
        return jsonBody;
    }
    
    @remoteAction
    public static void logZip(object zipFileObject){
        system.debug(zipFileObject);
    }
    
    /*@remoteAction
public static string checkAsyncResult(string requestId) {

MetadataService.RetrieveResult retrieveResult = service.checkRetrieveStatus(requestId, true);


if(retrieveResult.done) {

retrievePollerEnabled = false;

// Errors?
if(retrieveResult.status != 'Succeeded') {
ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, retrieveResult.errorMessage));
} else {
batchPollerEnabled = true;

batchCommitController con = new batchCommitController(EncodingUtil.base64Decode(retrieveResult.zipFile));
batchId = Database.executeBatch(con, 1);
}
}

}

system.debug('retrievePollerEnabled : ' + retrievePollerEnabled);

}


public void checkBatchRequest() {
// Check the status of the batch request

MetadataService.MetadataPort service = createService();
retrievePollerEnabled = false;

if(batchPollerEnabled){

MetadataService.RetrieveResult batchResult;

try{
batchResult = service.checkRetrieveStatus(batchId, true);
} catch (exception e){

}

if(batchResult.done) {

batchPollerEnabled = false;
allJobsComplete = true;

// Errors?
if(batchResult.status != 'Succeeded') {
ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, batchResult.errorMessage));
} 

}
}

}*/
    
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
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////// GitHub API Methods //////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    
    public static map<string,string> params = new map<string,string>();
    public static List<commits> commitList {get;set;}
    public static string commitMessage {get;set;}
    
    public class commits {
        public String sha {get;set;}
        public cls_commit commit_x {get;set;}
    }
    
    class cls_commit {
        public cls_author author {get;set;}
        public string message {get;set;}
    }
    
    class cls_author {
        public String date_x {get;set;}
        
        public string getdate_x_formatted(){
            TimeZone tz = UserInfo.getTimeZone();
            
            datetime date_x_datetime = datetime.valueOf(date_x.replace('T',' ').replace('Z', ' '));
            date_x_dateTime = date_x_datetime.addSeconds(tz.getOffset(date_x_datetime)/1000);
            
            return date_x_datetime.format('d MMMM, yyyy') + ' @ '  + date_x_datetime.format('hh:mma');
        }
    }
    
    public static void getRepoCommits(){ 
        
        payload = githubUtility.doExecuteCallout('GET', 'repos/SystemLabsDeveloper/' + UserInfo.getOrganizationId() + '/commits', params);
        payload = payload.replaceAll('"commit"','"commit_x"').replaceAll('"date"', '"date_x"');
        try{
            commitList = (List<commits>)JSON.deserialize(payload, List<commits>.class);
            
            for(integer i = 0; i < commitList.size(); i++){
                if(commitList[i].commit_x.message.toLowerCase() == 'initial commit'){
                    commitList.remove(i);
                }
            }
        } catch (exception e){
            commitList = new List<commits>();
            system.debug('JSON Parsing Exception: ' + e.getMessage());
        }
    }
    
    public static void createRepo(){
        string body = '{'
            + '"name":"' + UserInfo.getOrganizationId() + '"'
            + ',"auto_init":true'
            + '}'; 
        
        doExecuteCallout('POST', '/user/repos', body);
        commitMessage = 'First time backup (automated)';
        //doCommitFlow();
        
    }
}