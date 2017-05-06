/* Developed by Prolytics
 * 
 * Description:
 * When the Opportuntiy has a Recurring Months value, the Opportunity is cloned once for each recurring 
 * month, less the current month (the current opportuntiy accounts for this.)
 *
 * Change Log:
 * 23/07/2015 - Created by Matt Bathersby
 *
 */

trigger createChildOpportuntities on Opportunity (after insert, after update) {

    List<Opportunity> opptyList = new List<Opportunity>();

    if(trigger.isInsert){
    
        //on insert, create child opportunities
        for(Opportunity o : trigger.new){
        
            if(o.Subscription_Term__c != null && o.Subscription_Term__c != 0){
        
                for(integer i = 0; i < o.Subscription_Term__c; i++){
                
                    Opportunity opp = new Opportunity();
                    
                    string dateString= DateTime.parse(o.CloseDate.addMonths(i).format() + ' 11:46 AM').format('MMM') + ', ' + o.CloseDate.addMonths(i).year();

                    
                    opp.Name = o.Name + ' - ' + dateString;
                    opp.CloseDate = o.CloseDate.addMonths(i+1).toStartOfMonth().addDays(-1);
                    opp.StageName = o.StageName;
                    opp.Parent_Opportunity__c = o.Id;
                    opp.Amount = o.Amount;
                    opp.AccountID = o.AccountId;
                    
                    opptyList.add(opp);
                    
                }
                
            }
            
        }
        
        database.insert(opptyList, true);
    
    }
    
    //if CloseDate updated, update children
    if(trigger.isUpdate){
    
    
    }
    
    // if child oppty deleted, update parent oppty amount
    if(trigger.isDelete){
    
    
    }
    
}