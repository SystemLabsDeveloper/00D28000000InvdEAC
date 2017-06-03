public with sharing class AuthController extends Utility {
    
    public XeroSession__c session {get;set;}
    
	public String authUrl { get; set; }
    
    public boolean authSuccess { get; set; }
    public String message { get; set; }
    public datetime sessionExpires {get;set;}
    
    public boolean validSession {get;set;}
    
    public AuthController() { 
		session = XeroSession__c.getOrgDefaults();
    }

    public AuthController(ApexPages.StandardController controller) {
        
    }
    
    public void disconnect() {
        session.oauth_token__c = '';
        session.oauth_token_secret__c = '';
        session.connection_status__c = '';
        update session;
    }

    public PageReference authorize() {

        PageReference ref = ApexPages.currentPage(); 
        
        Id id = ref.getParameters().get('Id');
        ref.getParameters().clear();
        ref.getParameters().put('Id', id);  
        
        authUrl = newAuthorization();
        
        if (authUrl == null) {
            this.message = message;
            return null;
        } else {
            return new PageReference(authUrl);
        }
    }
    
    public PageReference completeAuthorization() {
        
        String token = ApexPages.currentPage().getParameters().get('oauth_token');
        
        if(token!=null){
            String verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
            
            authSuccess = completeAuthorization(token,verifier);
            this.message = message;
        } else {
            message = 'Invalid request. Missing parameter oauth_token';
        }
        
        PageReference retUrl = Page.admin;
        retUrl.setRedirect(true);
        return retUrl;
    }
    
}