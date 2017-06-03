global class batchCommitController implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {
    
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
    
    public final Zippex zip {get;set;}
    public newTree tree = new newTree();
    public final string latestCommitSha {get;set;}
    public string commitMsg {get;set;}
    
    global batchCommitController(string zipFile, string msg){
        
        system.debug('@@@ zipFile: ' + zipFile);
        
        blob encodedZip = encodingUtil.base64decode(zipFile); 
        zip = new Zippex(encodedZip);
        commitMsg = msg;
        
        githubUtility.getLatestCommit(); // gets SHA of most recent commit to master branch
        githubUtility.getBaseTree(); // gets sha of master branch tree to use as base
        
        latestCommitSha = githubUtility.latestCommitSha;
 
        tree.base_tree = gitHubUtility.baseTreeSha;
        tree.tree = new List<element>();
    }
    
    global Iterable<string> start(Database.BatchableContext bc){
        List<string> fileNames = new List<string>();
        fileNames.addAll(zip.getFileNames());
        return fileNames;
    }
    
    global void execute(Database.BatchableContext bc, string[] scope){

        for(string s : scope){
            
            element e = new element();
            e.path = 'src/' + s;
            e.content = zip.getFile(s).toString();

            tree.tree.add(e);
        }

    }
    
    global void finish(Database.BatchableContext bc){
        
        string jsonBody = json.serialize(tree);
        system.debug('NewTree Serialised (' + tree.tree.size() + ' records): ' + jsonBody); 
        
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
            + '"message": "' + commitMsg + '",'
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
        
        system.debug('*********************************************');
        system.debug('Batch Complete: ' + bc.getJobId());
        system.debug('*********************************************');
    }
    
}