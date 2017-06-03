public class sowBuilder {
    
    public Opportunity opp {
        get{
            return [select Id, AccountId, Account.Name, SOW_Number__c 
                    from Opportunity
                    where Id = :ApexPages.currentPage().getParameters().get('id') limit 1];
        }
    }
    
    public List<sowItem> psItems {get;set;}
    public List<sowItem> tcItems {get;set;}
    public List<sowItem> adItems {get;set;}
    
    public final boolean includeAcceptance {get;set;}
    public final boolean savePDF {get;set;}
    
    public boolean renderSectionOne {get;set;}
    public boolean renderSectionTwo {get;set;}
    public boolean renderSectionThree {get;set;}
    
    public map<string, string> psMapForEdit {get;set;}
    public map<string, string> tcMapForEdit {get;set;}
    public map<string, string> adMapForEdit {get;set;}
    
    public class sowItem{
        
        public  string Name {get;set;}
        public  string PlainText {get;set;}
        public  string HtmlText {get;set;}
        public  boolean selected {get;set;}
        public  boolean required {get;set;}
        public  integer sectionNumber {get;set;}
        
    }
    
    public void init(){
        
        psItems = new List<sowItem>();
        tcItems = new List<sowItem>();
        adItems = new List<sowItem>();
        
        for(SOW_Item__c sItem : [select Id, Name, Text__c, Default_Selected__c, Required__c, Section__c
                                 from SOW_Item__c 
                                 where Active__c  = true
                                 order by Name asc]){
                                     
                                     sowItem item = new sowItem();
                                     
                                     item.Selected = sItem.Default_Selected__c;
                                     item.Name = sItem.Name;
                                     item.PlainText = htmlStripper(sItem.Text__c.unescapeHtml4().ReplaceAll('<<AccountName>>', opp.Account.Name));
                                     item.HtmlText = sItem.Text__c.ReplaceAll('<<AccountName>>', opp.Account.Name);
                                     item.Required = sItem.Required__c;
                                     
                                     if(sItem.Section__c == '1. Professional Services'){	psItems.add(item);	}
                                     if(sItem.Section__c == '2. Terms & Conditions'){	tcItems.add(item);	}
                                     if(sItem.Section__c == '3. Addendums'){	adItems.add(item);	}
                                     
                                 }

    }
    
    public string htmlStripper(string htmlString){
        
        string result = htmlString.replaceAll('<br/>', '\n');
        result = result.replaceAll('<br />', '\n');
        //regular expression to match all HTML/XML tags
        string HTML_TAG_PATTERN = '<.*?>';
        
        // compile the pattern     
        pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
        
        // get your matcher instance
        matcher myMatcher = myPattern.matcher(result);
        
        //remove the tags     
        result = myMatcher.replaceAll('');
        system.debug('####'+result);
        
        return result;
        
    }
    
    public pagereference openForEdit(){
        
    	psMapForEdit = new Map<string, string>();
        tcMapForEdit = new Map<string, string>();
        adMapForEdit = new Map<string, string>();
        
        for(sowItem ps : psItems){
            if(ps.selected){
            	psMapForEdit.put(ps.Name, ps.htmlText.replaceAll('&lt;&lt;AccountName&gt;&gt;', opp.Account.Name));
                renderSectionOne = true;
            }
        }
        
        for(sowItem tc : tcItems){
            if(tc.selected){
            	tcMapForEdit.put(tc.Name, tc.htmlText.replaceAll('&lt;&lt;AccountName&gt;&gt;', opp.Account.Name));
                renderSectionTwo = true;
            }
        }
        
        for(sowItem ad : adItems){
            if(ad.selected){
            	adMapForEdit.put(ad.Name, ad.htmlText.replaceAll('&lt;&lt;AccountName&gt;&gt;', opp.Account.Name));
                renderSectionThree = true;
            }
        }
        
        //system.debug('>>>> editMap:'+mapForEdit+' <<<<');
        
        PageReference step2 = new PageReference('/apex/sowEditor');
        step2.setRedirect(false);
        return step2;
        
    }
    
    public pageReference generateSOW(){
        
        PageReference step3 = new PageReference('/apex/sowGenerator');
        step3.setRedirect(false);
        return step3;
        
    }
    
}