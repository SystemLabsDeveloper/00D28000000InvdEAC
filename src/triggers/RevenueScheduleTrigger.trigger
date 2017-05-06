trigger RevenueScheduleTrigger on OpportunityLineItem (after insert) {
    
    OpportunityLineItem newItem;
    OpportunityLineItem oldItem;
    
    RevenueScheduleEngine rse = new RevenueScheduleEngine();
    
    for(integer i = 0; i < trigger.new.size(); i++){
        
        newItem = trigger.new[i];
        
        if(trigger.isInsert){
            
            rse.EstablishRevenueSchedule(newItem);
            
        }
        
         if(trigger.IsUpdate){
             
             oldItem = trigger.old[i];
             
             if(oldItem.TotalPrice != newItem.TotalPrice){
                 
                 rse.ReestablishRevenueSchedule(newItem);
                 
             }
             
         }
        
    }
    
}