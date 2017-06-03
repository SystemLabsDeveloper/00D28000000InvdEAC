public abstract class Utility {

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
    
    public final Xero_API_Setting__mdt service = [SELECT access_token_url__c,
                                                   authorization_url__c,
                                                   consumer_key__c,
                                                   consumer_secret__c,
                                                   request_token_url__c,
                                                   endpoint__c
                                                   FROM Xero_API_Setting__mdt
                                                   WHERE DeveloperName = 'defaults'
                                                   LIMIT 1];
    
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
    
    public List<SelectOption> getAccountContactsOptions(string AccountId){
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('','No Contact'));
        for(Contact c : [select Id, FirstName, LastName from Contact where AccountId = :AccountId]){
            options.add(new SelectOption(c.Id,c.FirstName + ' ' + c.LastName));
        }
        return options;
    }
    
    public List<SelectOption> getBillPaymentTermOptions(){
        
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('OFFOLLOWINGMONTH','of the following month'));
        options.add(new SelectOption('DAYSAFTERBILLDATE','day(s) after the bill date'));
        options.add(new SelectOption('DAYSAFTERBILLMONTH','day(s) after the end of the bill month'));
        options.add(new SelectOption('OFCURRENTMONTH','of the current month'));
        
        return options;
    }
    
    public List<SelectOption> getInvoicePaymentTermOptions(){
        
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('OFFOLLOWINGMONTH','of the following month'));
        options.add(new SelectOption('DAYSAFTERBILLDATE','day(s) after the invoice date'));
        options.add(new SelectOption('DAYSAFTERBILLMONTH','day(s) after the end of the invoice month'));
        options.add(new SelectOption('OFCURRENTMONTH','of the current month'));
        
        return options;
    }
    
    public List<SelectOption> getCurrencyCodeOptions(){
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('AUD','AUD'));
        options.add(new SelectOption('---','', true));
        
        options.add(new SelectOption('AED','AED'));
        options.add(new SelectOption('AFN','AFN'));
        options.add(new SelectOption('ALL','ALL'));
        options.add(new SelectOption('AMD','AMD'));
        options.add(new SelectOption('ANG','ANG'));
        options.add(new SelectOption('AOA','AOA'));
        options.add(new SelectOption('ARS','ARS'));
        options.add(new SelectOption('AWG','AWG'));
        options.add(new SelectOption('AZN','AZN'));
        options.add(new SelectOption('BAM','BAM'));
        options.add(new SelectOption('BBD','BBD'));
        options.add(new SelectOption('BDT','BDT'));
        options.add(new SelectOption('BGN','BGN'));
        options.add(new SelectOption('BHD','BHD'));
        options.add(new SelectOption('BIF','BIF'));
        options.add(new SelectOption('BMD','BMD'));
        options.add(new SelectOption('BND','BND'));
        options.add(new SelectOption('BOB','BOB'));
        options.add(new SelectOption('BRL','BRL'));
        options.add(new SelectOption('BSD','BSD'));
        options.add(new SelectOption('BTN','BTN'));
        options.add(new SelectOption('BWP','BWP'));
        options.add(new SelectOption('BYN','BYN'));
        options.add(new SelectOption('BZD','BZD'));
        options.add(new SelectOption('CAD','CAD'));
        options.add(new SelectOption('CDF','CDF'));
        options.add(new SelectOption('CHF','CHF'));
        options.add(new SelectOption('CLP','CLP'));
        options.add(new SelectOption('CNY','CNY'));
        options.add(new SelectOption('COP','COP'));
        options.add(new SelectOption('CRC','CRC'));
        options.add(new SelectOption('CUC','CUC'));
        options.add(new SelectOption('CUP','CUP'));
        options.add(new SelectOption('CVE','CVE'));
        options.add(new SelectOption('CZK','CZK'));
        options.add(new SelectOption('DJF','DJF'));
        options.add(new SelectOption('DKK','DKK'));
        options.add(new SelectOption('DOP','DOP'));
        options.add(new SelectOption('DZD','DZD'));
        options.add(new SelectOption('EGP','EGP'));
        options.add(new SelectOption('ERN','ERN'));
        options.add(new SelectOption('ETB','ETB'));
        options.add(new SelectOption('EUR','EUR'));
        options.add(new SelectOption('FJD','FJD'));
        options.add(new SelectOption('FKP','FKP'));
        options.add(new SelectOption('GBP','GBP'));
        options.add(new SelectOption('GEL','GEL'));
        options.add(new SelectOption('GGP','GGP'));
        options.add(new SelectOption('GHS','GHS'));
        options.add(new SelectOption('GIP','GIP'));
        options.add(new SelectOption('GMD','GMD'));
        options.add(new SelectOption('GNF','GNF'));
        options.add(new SelectOption('GTQ','GTQ'));
        options.add(new SelectOption('GYD','GYD'));
        options.add(new SelectOption('HKD','HKD'));
        options.add(new SelectOption('HNL','HNL'));
        options.add(new SelectOption('HRK','HRK'));
        options.add(new SelectOption('HTG','HTG'));
        options.add(new SelectOption('HUF','HUF'));
        options.add(new SelectOption('IDR','IDR'));
        options.add(new SelectOption('ILS','ILS'));
        options.add(new SelectOption('IMP','IMP'));
        options.add(new SelectOption('INR','INR'));
        options.add(new SelectOption('IQD','IQD'));
        options.add(new SelectOption('IRR','IRR'));
        options.add(new SelectOption('ISK','ISK'));
        options.add(new SelectOption('JEP','JEP'));
        options.add(new SelectOption('JMD','JMD'));
        options.add(new SelectOption('JOD','JOD'));
        options.add(new SelectOption('JPY','JPY'));
        options.add(new SelectOption('KES','KES'));
        options.add(new SelectOption('KGS','KGS'));
        options.add(new SelectOption('KHR','KHR'));
        options.add(new SelectOption('KMF','KMF'));
        options.add(new SelectOption('KPW','KPW'));
        options.add(new SelectOption('KRW','KRW'));
        options.add(new SelectOption('KWD','KWD'));
        options.add(new SelectOption('KYD','KYD'));
        options.add(new SelectOption('KZT','KZT'));
        options.add(new SelectOption('LAK','LAK'));
        options.add(new SelectOption('LBP','LBP'));
        options.add(new SelectOption('LKR','LKR'));
        options.add(new SelectOption('LRD','LRD'));
        options.add(new SelectOption('LSL','LSL'));
        options.add(new SelectOption('LYD','LYD'));
        options.add(new SelectOption('MAD','MAD'));
        options.add(new SelectOption('MDL','MDL'));
        options.add(new SelectOption('MGA','MGA'));
        options.add(new SelectOption('MKD','MKD'));
        options.add(new SelectOption('MMK','MMK'));
        options.add(new SelectOption('MNT','MNT'));
        options.add(new SelectOption('MOP','MOP'));
        options.add(new SelectOption('MRO','MRO'));
        options.add(new SelectOption('MUR','MUR'));
        options.add(new SelectOption('MVR','MVR'));
        options.add(new SelectOption('MWK','MWK'));
        options.add(new SelectOption('MXN','MXN'));
        options.add(new SelectOption('MYR','MYR'));
        options.add(new SelectOption('MZN','MZN'));
        options.add(new SelectOption('NAD','NAD'));
        options.add(new SelectOption('NGN','NGN'));
        options.add(new SelectOption('NIO','NIO'));
        options.add(new SelectOption('NOK','NOK'));
        options.add(new SelectOption('NPR','NPR'));
        options.add(new SelectOption('NZD','NZD'));
        options.add(new SelectOption('OMR','OMR'));
        options.add(new SelectOption('PAB','PAB'));
        options.add(new SelectOption('PEN','PEN'));
        options.add(new SelectOption('PGK','PGK'));
        options.add(new SelectOption('PHP','PHP'));
        options.add(new SelectOption('PKR','PKR'));
        options.add(new SelectOption('PLN','PLN'));
        options.add(new SelectOption('PYG','PYG'));
        options.add(new SelectOption('QAR','QAR'));
        options.add(new SelectOption('RON','RON'));
        options.add(new SelectOption('RSD','RSD'));
        options.add(new SelectOption('RUB','RUB'));
        options.add(new SelectOption('RWF','RWF'));
        options.add(new SelectOption('SAR','SAR'));
        options.add(new SelectOption('SBD','SBD'));
        options.add(new SelectOption('SCR','SCR'));
        options.add(new SelectOption('SDG','SDG'));
        options.add(new SelectOption('SEK','SEK'));
        options.add(new SelectOption('SGD','SGD'));
        options.add(new SelectOption('SHP','SHP'));
        options.add(new SelectOption('SLL','SLL'));
        options.add(new SelectOption('SOS','SOS'));
        options.add(new SelectOption('SPL','SPL'));
        options.add(new SelectOption('SRD','SRD'));
        options.add(new SelectOption('STD','STD'));
        options.add(new SelectOption('SVC','SVC'));
        options.add(new SelectOption('SYP','SYP'));
        options.add(new SelectOption('SZL','SZL'));
        options.add(new SelectOption('THB','THB'));
        options.add(new SelectOption('TJS','TJS'));
        options.add(new SelectOption('TMT','TMT'));
        options.add(new SelectOption('TND','TND'));
        options.add(new SelectOption('TOP','TOP'));
        options.add(new SelectOption('TRY','TRY'));
        options.add(new SelectOption('TTD','TTD'));
        options.add(new SelectOption('TVD','TVD'));
        options.add(new SelectOption('TWD','TWD'));
        options.add(new SelectOption('TZS','TZS'));
        options.add(new SelectOption('UAH','UAH'));
        options.add(new SelectOption('UGX','UGX'));
        options.add(new SelectOption('USD','USD'));
        options.add(new SelectOption('UYU','UYU'));
        options.add(new SelectOption('UZS','UZS'));
        options.add(new SelectOption('VEF','VEF'));
        options.add(new SelectOption('VND','VND'));
        options.add(new SelectOption('VUV','VUV'));
        options.add(new SelectOption('WST','WST'));
        options.add(new SelectOption('XAF','XAF'));
        options.add(new SelectOption('XCD','XCD'));
        options.add(new SelectOption('XDR','XDR'));
        options.add(new SelectOption('XOF','XOF'));
        options.add(new SelectOption('XPF','XPF'));
        options.add(new SelectOption('YER','YER'));
        options.add(new SelectOption('ZAR','ZAR'));
        options.add(new SelectOption('ZMW','ZMW'));
        options.add(new SelectOption('ZWD','ZWD'));

        return options;
    }
    
    public List<SelectOption> getSyncDirectionOptions(){ 
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('salesforce','Salesforce Always Wins'));
        options.add(new SelectOption('xero','Xero Always Wins'));
        
        return options;
    }
    
    

}