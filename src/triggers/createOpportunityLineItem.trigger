/* Developed by Prolytics
* 
* Description:
* When the Product Lookup on Opportuntiy is populated, this trigger automatically creates an 
* OpportunityLineItem record with corresponding details
*
* Change Log:
* 23/07/2015 - Created by Matt Bathersby
*
*/

trigger createOpportunityLineItem on Opportunity (after insert, after update) {
    
    // Retrieve Standard Pricebook
    Pricebook2 stdPriceBook = [select Id from Pricebook2 where IsStandard = true limit 1];
    
    // Get a map of all Pricebook Entries in the Standard Pricebook
    Map<string, string> pbEntryMap = new Map<string, string>();
    for(PricebookEntry pbe : [select id, product2Id from PricebookEntry where Pricebook2Id = :stdPriceBook.Id]){
        stdPricebook.put(pbe.Product2Id, pbe.Id);
    }
    
    Opportunity o {get;set;}
    Opportunity oldo {get;set;}
    
    for(integer i = 0; i < trigger.new.size(); i++){
        
        // Get Old and New Opportunity Records
        o = trigger.new[i];
        if(trigger.isUpdate) oldo = trigger.old[i];
        
        // If Product is being added for the first time
        if(oldo.Product__c == null && o.Product__c != null){
            // Assign Standard PriceBook to Opportuntiy
            o.Pricebook2Id = stdPriceBook.Id;
            
            // Create OpportuntyLineItem using details from pbEntryMap
            OpportunityLineItem item = new OpportunityLineItem();
            
            item.OpportunityId = o.Id;
            item.PricebookEntryId = pbEntryMap.get(o.Product__c);
            item.Quantity = 1;
            item.UnitPrice = o.Amount;
            item.Price_Range_Min__c = o.Price_Range_Min__c;
            item.Price_Range_Max__c = o.Price_Range_Max__c;
            
            database.insert(item);
            
        }
        
        // If Product is removed and not replaced, remove existing OpportunityLineItem
        if(oldo.Product__c != null && o.Product__c == null){
            
            database.delete([select Id from OpportunityLineItem where Product2Id = :oldo.Product__c and OpportunityId = :o.Id limit 1]);
            
        }
        
        // If Product is updated, remove existing OpportunityLineItem and replace with new one
        if((oldo.Product__c != null && o.Product__c == null) && oldo.Product__c != o.Product__c){
            
            database.delete([select Id from OpportunityLineItem where Product2Id = :oldo.Product__c and OpportunityId = :o.Id limit 1]);
            
            o.Pricebook2Id = stdPriceBook.Id;
            
            // Create OpportuntyLineItem using details from pbEntryMap
            OpportunityLineItem item = new OpportunityLineItem();
            
            item.OpportunityId = o.Id;
            item.PricebookEntryId = pbEntryMap.get(o.Product__c);
            item.Quantity = 1;
            item.UnitPrice = o.Amount;
            item.Price_Range_Min__c = o.Price_Range_Min__c;
            item.Price_Range_Max__c = o.Price_Range_Max__c;
            
            database.insert(item);
            
        }
    }
    
}