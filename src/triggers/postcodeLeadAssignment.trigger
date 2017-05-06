trigger postcodeLeadAssignment on Lead (before insert, before update) {
    
    // is Active on leads?
    boolean active = [SELECT Active_on_Lead_Object__c
                      FROM PPS__mdt
                      WHERE DeveloperName = 'Default'
                      LIMIT 1].Active_on_Lead_Object__c;

    if(active == true){
        
        Map<string,id> pcMap = new Map<string,Id>();
        
        // create postcode map??
        for(Postcode__c pc : [select Postcode_Range__c, Assign_To__c from Postcode__c]){
            
            if(pc.Postcode_Range__c.length() == 4){
            	pcMap.put(pc.Postcode_Range__c, pc.Assign_To__c);
                
            } else if (pc.Postcode_Range__c.contains('-')){
                List<string> pcs = pc.Postcode_Range__c.split('-');
                
                for(integer i = integer.valueOf(pcs[0]); i <= integer.valueOf(pcs[1]); i++){
                    pcMap.put(string.valueOf(i), pc.Assign_To__c);
                    
                }
                
            } 
            
        }
        for(Lead l : trigger.new){
            if(pcMap.containsKey(l.Postalcode)){
                l.ownerId = pcMap.get(l.Postalcode);
            }
            
        }
        
    }
    
}