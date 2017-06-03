public class PropertySelectionWizardController {
    
    public Opportunity OPPORTUNITY {get;set;}
    public Project__c PROJECT {get;set;}

    public string BEDROOM_FILTER {get;set;}
    public string BATHROOM_FILTER {get;set;}
    public string CARSPACE_FILTER {get;set;}
    public string PRICE_FILTER {get;set;}
    
    public string SORT_BY {get;set;}
    public string SORT_DIRECTION {get;set;}
    
    
    public PropertySelectionWizardController(){
        
        OPPORTUNITY = [select Id, Account.Name, Project__c from Opportunity where Id = :apexPages.currentPage().getParameters().get('id')];
        PROJECT = [select Id, Name from Project__c where Id = :OPPORTUNITY.Project__c limit 1];
        
    }
    
    public List<Property__c> getPROPERTY_LIST(){
        
        system.debug('****************** getPROPERTY_LIST() ************************');
        system.debug('BEDROOM_FILTER =' + BEDROOM_FILTER);
        
        STRING PROPERTY_LIST_QUERY = 'select Id, Name, Bedrooms__c, Bathrooms__c, Car_Spaces__c, Price__c from Property__c where Project__c = \''+ PROJECT.Id +'\'';
        
        if(BEDROOM_FILTER != null)
            PROPERTY_LIST_QUERY += ' AND Bedrooms__c = \'' + BEDROOM_FILTER + '\'';
        
        if(BATHROOM_FILTER != null)
            PROPERTY_LIST_QUERY += ' AND Bathrooms__c = \'' + BATHROOM_FILTER + '\'';
        
        if(CARSPACE_FILTER != null)
            PROPERTY_LIST_QUERY += ' AND Car_Spaces__c = \'' + CARSPACE_FILTER + '\'';
        
        //PROPERTY_LIST_QUERY += ' ORDER BY '+ SORT_BY + ' ' + SORT_DIRECTION;
        
        system.debug('PROPERTY_LIST_QUERY: '+PROPERTY_LIST_QUERY);
        
        return database.query(PROPERTY_LIST_QUERY);
    }
    
    public List<SelectOption> getBED_BATH_SELECT(){
        
        List<SelectOption> BED_BATH_SELECT = new List<SelectOption>();
        
        BED_BATH_SELECT.add(new SelectOption('', '-- Show All --'));
        
        for(integer I = 1; I <=10; i++){
            
            BED_BATH_SELECT.add(new SelectOption(string.valueOf(I), string.valueOf(I)));
            
        }
        
        return BED_BATH_SELECT;
        
    }
    
    public List<SelectOption> getPRICE_SELECT(){
        
        List<SelectOption> PRICE_SELECT = new List<SelectOption>();
        
        PRICE_SELECT.add(new SelectOption('', '-- Show All --'));
        
        
        return PRICE_SELECT;
        
    }

}