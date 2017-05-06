trigger PostcodeContactAssignment on Contact (before insert, before Update) {
    
    // is Active on Contacts?
    PPS__mdt settings = [SELECT Active_on_Contact_Object__c, Use_Other_Address__c
                         FROM PPS__mdt
                         WHERE DeveloperName = 'Default'
                         LIMIT 1];
    
    if(settings.Active_on_Contact_Object__c == true){
        
        Map<string,id> pcMap = new Map<string,Id>();
        
        // create postcode map
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
        
        if(trigger.isUpdate){
            
            for(integer i = 0; i < trigger.new.size(); i++){
                Contact newCon = trigger.new[i];
                Contact oldCon = trigger.old[i];
                
                if(settings.Use_Other_Address__c != true){
                    
                    if(oldCon.MailingPostalcode != newCon.MailingPostalcode){
                        
                        if(pcMap.containsKey(newCon.MailingPostalcode)){
                            newCon.ownerId = pcMap.get(newCon.MailingPostalcode);
                        }
                    }
                } else {
                    if(oldCon.OtherPostalcode != newCon.OtherPostalcode){
                        
                        if(pcMap.containsKey(newCon.OtherPostalcode)){
                            newCon.ownerId = pcMap.get(newCon.OtherPostalcode);
                        }
                    }
                }
            }
        }
        
        else if (trigger.isInsert){
            
            for(integer i = 0; i < trigger.new.size(); i++){
                Contact newCon = trigger.new[i];
                
                if(settings.Use_Other_Address__c != true){
                    
                    if(pcMap.containsKey(newCon.MailingPostalcode)){
                        newCon.ownerId = pcMap.get(newCon.MailingPostalcode);
                    }
                } else {                        
                    if(pcMap.containsKey(newCon.OtherPostalcode)){
                        newCon.ownerId = pcMap.get(newCon.OtherPostalcode);
                    }
                }
            }
            
        }
    }
}