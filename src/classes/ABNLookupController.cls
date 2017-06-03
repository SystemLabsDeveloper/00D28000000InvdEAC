public with sharing class ABNLookupController {
    
    public sObject a {get;set;}
    public ABNLookupSettings__c settings = ABNLookupSettings__c.getOrgDefaults();
    public final string endpoint = 'http://abr.business.gov.au/abrxmlsearch/AbrXmlSearch.asmx/ABRSearchByNameAdvancedSimpleProtocol2012';
    public final string guid = 'f1a4e173-ac5b-4fdc-a9d6-128f66048de7';
    private final string ns = 'http://abr.business.gov.au/ABRXMLSearch/';
    
    public string searchTerm {get;set;}
    public string minScore {get;set;}
    public string maxResults {get;set;}
    
    public boolean NSW {get;set;}
    public boolean SA {get;set;}
    public boolean ACT {get;set;} 
    public boolean VIC {get;set;}
    public boolean WA {get;set;}
    public boolean NT {get;set;}
    public boolean QLD {get;set;}
    public boolean TAS {get;set;}
    
    public string rowCount {get;set;}
    
    public string selectedABN {get;set;}
    public string selectedLegalName {get;set;}
    
    public class result{
        public string ABN {get;set;}
        public string ORG_NAME{get;set;}
        public string SCORE {get;set;}
        public string STATUS {get;set;}
        public string IS_CURRENT {get;set;}
        public string STATE {get;set;}
        public string POSTCODE {get;set;}
        public string TYPE {get;set;}
    }
    
    public List<result> results {get;set;}
    
    public ABNLookupController(ApexPages.StandardController con){
        
        List<string> fieldsToAdd = new List<string>{'Name', settings.ABN_Field_Name__c};

        	if(settings.Legal_Name_Field_Name__c != null && settings.Legal_Name_Field_Name__c != 'Name')
                fieldsToAdd.add(settings.Legal_Name_Field_Name__c);

        if(!test.isRunningTest())
            con.addFields(fieldsToAdd);
        
        this.a = (Account) con.getRecord();
        searchTerm = string.valueOf(a.get('name'));
        
        minScore = '60';
        maxResults = '10';
        
        NSW = true;
        SA = true;
        ACT = true;
        VIC = true;
        WA = true;
        NT = true;
        QLD = true;
        TAS = true;
        
        results = new List<result>();
        
    }
    
    public void getABNResults(){ 
        
        results.clear();
                
        HTTPRequest req = new HTTPRequest();
        	req.setEndpoint(endpoint + getRequestBody());
        	req.setMethod('GET');
        	req.setTimeout(30000);
        
        HTTP http = new HTTP();
        system.debug('endpoint: ' + req.getEndpoint());
        
        HTTPResponse res = HTTP.send(req);
        parseXMLResponse(res.getBodyDocument());
        
        system.debug('a: ' + a);
        system.debug('a.Name: ' + a.get('Name'));
        
    }
    
    public void parseXMLResponse(DOM.Document XMLdoc){
        
        Dom.XmlNode response = XMLdoc.getRootElement()
            .getChildElement('response', ns)
            .getChildElement('searchResultsList', ns);

        //system.debug('response : ' + response);
        
        rowCount = response.getChildElement('numberOfRecords', ns).getText();
        //system.debug('rowCount: ' + rowCount);
        
        for(Dom.XMLNode child1 : response.getChildElements()){

            if(child1.getName() == 'searchResultsRecord'){
                
                result r = new result();
                
                r.ABN = child1.getChildElement('ABN', ns)
                    .getChildElement('identifierValue', ns)
                    .getText();

                r.ABN = formatABN(r.ABN);
                
               r.STATUS = child1.getChildElement('ABN', ns)
                    .getChildElement('identifierStatus', ns)
                    .getText();

                //system.debug(child1.getChildElements());
                //system.debug(child1.getChildElement('businessName', ns).getChildElements());

                if(child1.getChildElement('businessName', ns) != null){

                    r.ORG_NAME = child1.getChildElement('businessName', ns)
                        .getChildElement('organisationName', ns)
                        .getText();

                    r.SCORE = child1.getChildElement('businessName', ns)
                        .getChildElement('score', ns)
                        .getText();

                    r.IS_CURRENT = child1.getChildElement('businessName', ns)
                        .getChildElement('isCurrentIndicator', ns)
                        .getText();

                    r.TYPE = 'Business Name';
                }

                else if(child1.getChildElement('mainName', ns) != null){

                    r.ORG_NAME = child1.getChildElement('mainName', ns)
                        .getChildElement('organisationName', ns)
                        .getText();

                    r.SCORE = child1.getChildElement('mainName', ns)
                        .getChildElement('score', ns)
                        .getText();

                    r.IS_CURRENT = child1.getChildElement('mainName', ns)
                        .getChildElement('isCurrentIndicator', ns)
                        .getText();

                    r.TYPE = 'Entity Name';

                }

                else if(child1.getChildElement('mainTradingName', ns) != null){

                     r.ORG_NAME = child1.getChildElement('mainTradingName', ns)
                        .getChildElement('organisationName', ns)
                        .getText();

                    r.SCORE = child1.getChildElement('mainTradingName', ns)
                        .getChildElement('score', ns)
                        .getText();

                    r.IS_CURRENT = child1.getChildElement('mainTradingName', ns)
                        .getChildElement('isCurrentIndicator', ns)
                        .getText();

                    r.TYPE = 'Trading Name';

                }

                r.STATE = child1.getChildElement('mainBusinessPhysicalAddress', ns)
                        .getChildElement('stateCode', ns)
                        .getText();

                r.POSTCODE = child1.getChildElement('mainBusinessPhysicalAddress', ns)
                        .getChildElement('postcode', ns)
                        .getText();

                results.add(r);
                
            }
            
        }
        
        system.debug(results);
            
    }

    public string formatABN(string ABN){

        string part1 = ABN.left(2);
        string part2 = ABN.substring(2,5);
        string part3 = ABN.substring(5,8);
        string part4 = ABN.right(3);

        return part1+' '+part2+' '+part3+' '+part4;

    }
    
    public pagereference selectABN(){

        a.put(settings.ABN_Field_Name__c, selectedABN);
        a.put(settings.Legal_Name_Field_Name__c, selectedLegalName);
        database.update(a);
        
        return (new PageReference('/'+a.Id));
        
    }
    
    public string getRequestBody(){
                
        string url = '?name=' + EncodingUtil.urlEncode(searchTerm
                                                       .toLowerCase()
                                                       .replace('the trustee for', '')
                                                       .replace('trustee','')
                                                       .replace('trust','')
                                                       , 'UTF-8')
            + '&postcode='
            + '&legalName='
            + '&tradingName='
            + '&businessName='
        	+ (NSW ? '&NSW=Y' : '&NSW=N')
            + (SA ? '&SA=Y' : '&SA=N')
            + (VIC ? '&VIC=Y' : '&VIC=N')
            + (ACT ? '&ACT=Y' : '&ACT=N')
            + (WA ? '&WA=Y' : '&WA=N')
            + (NT ? '&NT=Y' : '&NT=N')
            + (QLD ? '&QLD=Y' : '&QLD=N')
            + (TAS ? '&TAS=Y' : '&TAS=N')
            + '&authenticationGuid=' + guid
            + '&searchWidth='
            + '&minimumScore='+minScore
            + '&maxSearchResults='+maxResults;
       
        system.debug('url: ' + url);
                
        return url;
        
    }
}