public class OAuth extends Utility{
    
    public XeroSession__c session {get;set;}
    public string xmlString;

    private Boolean isAccess = false;
    public String verifier;

    private String nonce;
    private String timestamp;
    private String signature;

    private Map<String,String> parameters = new Map<String,String>();
    
    public String message {get;set;}

    public String callbackUrl;
    
    public string getContacts(){
        
        session = XeroSession__c.getOrgDefaults();
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(service.endpoint__c + 'contacts');
        
        sign(req);
        
        HttpResponse res = h.send(req);
        return res.getBody();
    }

    public String newAuthorization() {

        session = XeroSession__c.getOrgDefaults();

        if(callbackUrl==null) { 
            if(ApexPages.currentPage()==null || ApexPages.currentPage().getHeaders().get('Host')==null) {
                message = 'No callback page was set and it couldn\'t be generated from Apex context';
                System.debug(message);
                return null;
            }
    
            callbackUrl = EncodingUtil.urlEncode(
                'https://'+ApexPages.currentPage().getHeaders().get('Host') + Page.CompleteAuth.getUrl(),'UTF-8'
                //'https://'+ApexPages.currentPage().getHeaders().get('Host'),'UTF-8'
            );
        }
        
        system.debug('callback URL : ' + callbackUrl);
                
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(service.request_token_url__c);
        
        System.debug('Request body set to: '+req.getBody());
        
        sign(req);
        HttpResponse res = null;

        res = h.send(req);

        System.debug('Response from request token request: ('+res.getStatusCode()+')'+res.getBody());
        
        if(res.getStatusCode()>299) {
            message = 'Failed getting a request token. HTTP Code = '+res.getStatusCode()+
                      '. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
            return null;
        }
        
        String resParams = res.getBody();
        
        Map<String,String> rp = getUrlParams(resParams);
        
        system.debug('@@@ Updating Session Data - Auth');
        
        session.oauth_token__c = rp.get('oauth_token');
        session.oauth_token_secret__c = rp.get('oauth_token_secret');
        session.Connection_Status__c = 'Authorized';
        
        update session;
        
        System.debug('Got request token: '+ session.oauth_token__c +'('+rp.get('oauth_token')+')');
        
        if(service.authorization_url__c.contains('?')) {
            return service.authorization_url__c + '&oauth_token=' + EncodingUtil.urlDecode(session.oauth_token__c,'UTF-8') + '&oauth_consumer_key=' + service.consumer_key__c;
        } else {
            return service.authorization_url__c + '?oauth_token=' + EncodingUtil.urlDecode(session.oauth_token__c,'UTF-8') + '&oauth_consumer_key=' + service.consumer_key__c;
        }
        
        return null;
    }
    
    public boolean completeAuthorization(String token, String verifier) {
        System.debug('Completing authorization for request token '+token+' with verifier '+verifier);
        
        if(verifier!=null) {
            this.verifier = EncodingUtil.urlEncode(verifier,'UTF-8');
        }
        
        session = XeroSession__c.getOrgDefaults();
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(service.access_token_url__c);
        req.setBody('');
        sign(req);
        
        HttpResponse res = null;

        res = h.send(req);
        System.debug('Response from request token request: ('+res.getStatusCode()+')'+res.getBody());
        
        if(res.getStatusCode()>299) {
            message = 'Failed getting an access token. HTTP Code = '+res.getStatusCode()+'. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
            return false;
        }

        String resParams = res.getBody();

        Map<String,String> rp = new Map<String,String>();
        for(String s : resParams.split('&')) {
            List<String> kv = s.split('=');
            rp.put(kv[0],kv[1]);
            System.debug('Access token response param: '+kv[0]+'='+kv[1]);
        }
        
        system.debug('@@@ Updating Session Data - AuthComplete');
        
        session.oauth_token__c = rp.get('oauth_token');
        session.oauth_token_secret__c = rp.get('oauth_token_secret');
        session.Connection_Status__c = 'Connected';
        session.Connection_Established__c = system.now();
        
        update session;
        
        return true;
    }
    
    /*public List<User> getUsersOfService(String serviceName) {
        List<OAuth_Token__c> l =
            [SELECT OAuth_Service__r.name, isAccess__c, Owner__r.name FROM OAuth_Token__c 
             WHERE OAuth_Service__r.name= :serviceName AND isAccess__c = true];
             
        List<User> result = new List<User>();
        for(OAuth_Token__c t : l) {
            result.add(t.owner__r);
        }
        return result;
    }*/

    /*public boolean setService(String serviceName) {
        return setService(serviceName,UserInfo.getUserId());
    }*/

    /*public boolean setService(String serviceName, ID userId) {
        OAuth_Token__c t = null;
        try {
            t =
            [SELECT OAuth_Service__r.name, OAuth_Service__r.consumer_key__c, OAuth_Service__r.consumer_secret__c, 
             token__c, secret__c, isAccess__c FROM OAuth_Token__c 
             WHERE OAuth_Service__r.name= :serviceName AND owner__c=:userId AND isAccess__c = true];
        } catch(System.QueryException e) {
            try {
                // Two-legged OAuth - try to find match on serviceName
                service = [SELECT id, name, consumer_key__c, consumer_secret__c 
                 FROM OAuthService__c 
                 WHERE name= :serviceName];
                
                System.debug('Preparing Two-legged OAuth request to service '+service.name);
                
                consumerKey = service.Consumer_Key__c;
                consumerSecret = service.Consumer_Secret__c;
                this.token = '';
                tokenSecret = '';       
                return true;
            } catch(System.QueryException e1) {
                message = 'Couldn\'t find service '+serviceName+'. ['+e1+']';
                System.debug(message);
                return false;
            }
        }

        service = t.Oauth_Service__r;
        
        System.debug('Preparing OAuth request to service '+service.name);
        
        consumerKey = service.Consumer_Key__c;
        consumerSecret = service.Consumer_Secret__c;
        this.token = t.token__c;
        tokenSecret = t.secret__c;      
        return true;
    }*/
    
    private void clearSession(){
        
        session.oauth_token__c = '';
        session.oauth_token_secret__c = '';
        session.connection_status__c = '';
        update session;
        
    }
        
    private void refreshParameters() {
        parameters.clear();
        parameters.put('oauth_consumer_key',service.consumer_key__c);
        if(session.oauth_token__c != null) {
            parameters.put('oauth_token',session.oauth_token__c);
        }
        if(verifier!=null) {
            parameters.put('oauth_verifier',verifier);
        }
        parameters.put('oauth_signature_method','HMAC-SHA1');
        parameters.put('oauth_timestamp',timestamp);
        parameters.put('oauth_nonce',nonce);
        parameters.put('oauth_callback',callbackUrl);
        
        if(xmlString != null)
            parameters.put('xml', encodingUtil.urlDecode(xmlString,'UTF-8'));
    }

    private Map<String,String> getUrlParams(String value) {

        Map<String,String> res = new Map<String,String>();
        if(value==null || value=='') {
            return res;
        }
        for(String s : value.split('&')) {
            System.debug('getUrlParams: '+s);
            List<String> kv = s.split('=');
            if(kv.size()>1) {
                //if(kv[0] != 'xml'){
                    // RFC 5849 section 3.4.1.3.1 and 3.4.1.3.2 specify that parameter names 
                    // and values are decoded then encoded before being sorted and concatenated
                    // Section 3.6 specifies that space must be encoded as %20 and not +
                    String encName = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[0], 'UTF-8'), 'UTF-8').replace('+','%20');
                    String encValue = EncodingUtil.urlEncode(kv[1], 'UTF-8').replace('+','%20');
                    System.debug('getUrlParams:  -> '+encName+','+encValue);
                    res.put(encName,encValue);
                //}
            }
        }
        return res;
    }

    private String createBaseString(Map<String,String> oauthParams, HttpRequest req) {
        
        Map<String,String> p = oauthParams.clone();
        
        if(req.getMethod().equalsIgnoreCase('post') && req.getBody()!=null && 
           req.getHeader('Content-Type')=='application/x-www-form-urlencoded') {
            p.putAll(getUrlParams(req.getBody()));
        }
        
        String host = req.getEndpoint();
        Integer n = host.indexOf('?');
        if(n>-1) {
            p.putAll(getUrlParams(host.substring(n+1)));
            host = host.substring(0,n);
        }
        List<String> keys = new List<String>();
        keys.addAll(p.keySet());
        keys.sort();
        String s = keys.get(0)+'='+p.get(keys.get(0));
        for(Integer i=1;i<keys.size();i++) {
            s = s + '&' + keys.get(i)+'='+p.get(keys.get(i));
        }

        // According to OAuth spec, host string should be lowercased, but Google and LinkedIn
        // both expect that case is preserved.
        return req.getMethod().toUpperCase()+ '&' + 
            EncodingUtil.urlEncode(host, 'UTF-8') + '&' +
            EncodingUtil.urlEncode(s, 'UTF-8');
    }
    
    public void sign(HttpRequest req) {
        
        nonce = String.valueOf(Crypto.getRandomLong());
        timestamp = String.valueOf(DateTime.now().getTime()/1000);

        refreshParameters();
        
        String s = createBaseString(parameters, req);
        
        System.debug('Signature base string: '+s);
        
        Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(s), Blob.valueOf(service.consumer_secret__c + '&' + (session.oauth_token_secret__c !=null ? session.oauth_token_secret__c : '')));
        signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        System.debug('Signature: '+signature);
        
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header + key + '="'+parameters.get(key)+'", ';
        }
        header = header + 'oauth_signature="'+signature+'"';
        System.debug('Authorization: '+header);
        
        req.setHeader('Authorization',header);
        req.setHeader('Accept','application/json');
    }
}