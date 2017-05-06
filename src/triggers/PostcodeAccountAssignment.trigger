trigger PostcodeAccountAssignment on Account (before insert, before update, after update) {
    
    // is Active on Contacts?
    PPS__mdt settings = [SELECT Active_on_Account_Object__c, Use_Billing_Address__c, Assign_All_Contacts__c
                         FROM PPS__mdt
                         WHERE DeveloperName = 'Default'
                         LIMIT 1];
    
    string newAccId;
    
    if(settings.Active_on_Account_Object__c == true){
        
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
        if(trigger.isBefore){
            if(trigger.isUpdate){
                
                for(integer i = 0; i < trigger.new.size(); i++){
                    Account newAcc = trigger.new[i];
                    Account oldAcc = trigger.old[i];
                    
                    newAccId = newAcc.Id;
                    
                    if(settings.Use_Billing_Address__c != true){
                        
                        if(oldAcc.ShippingPostalcode != newAcc.ShippingPostalcode){
                            
                            if(pcMap.containsKey(newAcc.ShippingPostalcode)){
                                newAcc.ownerId = pcMap.get(newAcc.ShippingPostalcode);
                            }
                        }
                    } else {
                        if(oldAcc.BillingPostalcode != newAcc.BillingPostalcode){
                            
                            if(pcMap.containsKey(newAcc.BillingPostalcode)){
                                newAcc.ownerId = pcMap.get(newAcc.BillingPostalcode);
                            }
                        }
                    }
                }
            }
            
            else if (trigger.isInsert){
                
                for(integer i = 0; i < trigger.new.size(); i++){
                    Account newAcc = trigger.new[i];
                    
                    if(settings.Use_Billing_Address__c != true){
                        
                        if(pcMap.containsKey(newAcc.ShippingPostalcode)){
                            newAcc.ownerId = pcMap.get(newAcc.ShippingPostalcode);
                        }
                    } else {                        
                        if(pcMap.containsKey(newAcc.BillingPostalcode)){
                            newAcc.ownerId = pcMap.get(newAcc.BillingPostalcode);
                        }
                    }
                }
            }
        }
    }
}