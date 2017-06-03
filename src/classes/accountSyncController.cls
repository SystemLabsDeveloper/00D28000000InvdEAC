global class accountSyncController extends Utility {
    
    OAuth oauth = new OAuth();
    public String callbackUrl;
    public string message;
    
    public XeroSession__c session {get;set;}
    
    public Account acc{get;set;}
    public string primaryContactId {get;set;}
   
    public accountSyncController(ApexPages.StandardController con){
        
        session = XeroSession__c.getOrgDefaults();
        
        List<string> fields = new List<string>();
        	fields.add('Name');
        	fields.add('AccountNumber');
        	fields.add('Tax_Number__c');
        	fields.add('Sync_with_Xero__c');
        	fields.add('Sync_with_Xero__c');
        	fields.add('Default_Sales_Payment_Term__c');
        	fields.add('Default_Sales_Payment_Period__c');
        	fields.add('Default_Bill_Payment_Term__c');
        	fields.add('Default_Bill_Payment_Period__c');
        	fields.add('Xero_Network_Key__c');
        	fields.add('Last_Xero_Sync__c');
        	fields.add('Phone');
        	//fields.add('MobilePhone');
        	fields.add('Fax');
        	fields.add('Xero_Contact_Id__c');
        
        con.addFields(fields);
        this.acc = (Account) con.getRecord();
    }
    
    public final string ContactNumber {get;set;}
    public final string AccountNumber {get;set;}
    public string Name {get;set;}
    
    public string FirstName {get;set;}
    public string LastName {get;set;}
    public string EmailAddress {get;set;}
    public string SkypeUserName {get;set;}
    
    public List<SelectOption> contactsList {
        get{
            return getAccountContactsOptions(acc.Id);
        }
    }
    
    public List<ContactPersons> ContactPersons {get;set;}
    public class ContactPersons{
        public string FirstName;
        public string LastName;
        public string EmailAddress;
        public boolean IncludeInEmails;
    }

    public string TaxNumber {get;set;}// = acc.Tax_Number__c;
    
    public string AccountsReceivableTaxType = 'OUTPUT';
    public string AccountsPayableTaxType = 'INPUT';
    
    public List<Addresses> Addresses {get;set;}
    public class Addresses{
        public string AddressType;
        public string AddressLine1;
        public string AddressLine2;
        public string City;
        public string Region;
        public string PostalCode;
        public string Country;
        public string AttentionTo;
    }
    
    public List<Phones> Phones {get;set;}
    public class Phones{
        public string PhoneType;
        public string PhoneNumber;
        public string PhoneAreaCode;
        public string PhoneCountryCode;
    }

    public string DefaultCurrency {get;set;}
    
    public List<PaymentTerm> PaymentTerms {get;set;}
    public class PaymentTerm{
        public string termType;
        public integer day;
    }
    
    public string generateXML(){
        
        List<Contact> con = [select Id, FirstName, LastName, Email from Contact where Id = :primaryContactId limit 1];
        
        string xmlString = ''
            + '<Contacts>'
            + '<Contact>'
            + '<ContactNumber>' + acc.AccountNumber + '</ContactNumber>'
            + '<Name>' + acc.Name + '</Name>'
            /*+ '<ContactStatus>ACTIVE</ContactStatus>'
            + '<EmailAddress>' + (!con.isEmpty() ? con[0].Email : '') + '</EmailAddress>'
            + '<TaxNumber>' + acc.Tax_Number__c + '</TaxNumber>'
            + '<AccountsReceivableTaxType>OUTPUT</AccountsReceivableTaxType>'
            + '<AccountsPayableTaxType>INPUT</AccountsPayableTaxType>'
            + '<FirstName>' + (!con.isEmpty() ? con[0].FirstName : '') + '</FirstName>'
            + '<LastName>' + (!con.isEmpty() ? con[0].LastName : '') + '</LastName>'
            + '<DefaultCurrency>' + (DefaultCurrency != null ? DefaultCurrency : '') + '</DefaultCurrency>'
            + '<Addresses>'
            + '<Address>'
            + '<AddressType>STREET</AddressType>'
            + '<AttentionTo>' + (!con.isEmpty() ? con[0].FirstName + ' ' + con[0].LastName : '') + '</AttentionTo>'
            + '<AddressLine1>' + acc.ShippingStreet + '</AddressLine1>'
            + '<AddressLine2></AddressLine2>'
            + '<AddressLine3></AddressLine3>'
            + '<AddressLine4></AddressLine4>'
            + '<City>' + acc.ShippingCity + '</City>'
            + '<Region>' + acc.BillingState + '</Region>'
            + '<PostalCode>' + acc.ShippingPostalCode + '</PostalCode>'
            + '<Country>' + acc.ShippingCountry + '</Country>'
            + '</Address>'
            + '<Address>'
            + '<AddressType>POBOX</AddressType>'
            + '<AttentionTo>' + (!con.isEmpty() ? con[0].FirstName + ' ' + con[0].LastName : '') + '</AttentionTo>'
            + '<AddressLine1>' + acc.BillingStreet + '</AddressLine1>'
            + '<AddressLine2></AddressLine2>'
            + '<AddressLine3></AddressLine3>'
            + '<AddressLine4></AddressLine4>'
            + '<City>' + acc.BillingCity + '</City>'
            + '<Region>' + acc.BillingState + '</Region>'
            + '<PostalCode>' + acc.BillingPostalCode + '</PostalCode>'
            + '<Country>' + acc.BillingCountry + '</Country>'
            + '</Address>'
            + '</Addresses>'*/
            + '</Contact>'
            + '</Contacts>';
        
        return xmlString;
    }
    
    public string upsertContact(){
        
        if(oauth.callbackUrl==null) { 
            if(ApexPages.currentPage()==null || ApexPages.currentPage().getHeaders().get('Host')==null) {
                message = 'No callback page was set and it couldn\'t be generated from Apex context';
                System.debug(message);
                return null;
            }
    
            oauth.callbackUrl = EncodingUtil.urlEncode(
                'https://'+ApexPages.currentPage().getHeaders().get('Host') + Page.SyncAccount.getUrl(),'UTF-8'
                //'https://'+ApexPages.currentPage().getHeaders().get('Host'),'UTF-8'
            );
        }
        
        string endpoint = service.endpoint__c + 'contacts';
        
        if(acc.Xero_Contact_ID__c != null)
            endpoint += '/' + acc.Xero_Contact_ID__c;
        
        //string xmlPayload =  encodingUtil.urlEncode(generateXML(),'UTF-8').replace('+', '%20');
        
        //oauth.xmlString = xmlPayload;
        //endpoint += '?xml=' + xmlPayload;
        
        oauth.xmlString = generateXML();
        endpoint += '?xml=' + generateXML();
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded; charset=utf-8'); 
        //req.setHeader('Content-Length', '512');
        req.setTimeout(60000); 
        req.setEndpoint(endpoint);
        
        oauth.session = session;
        oauth.sign(req);
        
        HttpResponse res = h.send(req);
        
        system.debug('Auth Header : ' + req.getHeader('Authorization'));
        system.debug('Endpoint: ' + req.getEndpoint());
        system.debug('Response: ' + res.getBody());
        return res.getBody();
        
    }
    
}