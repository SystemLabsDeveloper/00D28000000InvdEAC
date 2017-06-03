public class RevenueScheduleEngine {
    
    List<OpportunityLineItemSchedule> scheduleItems = new List<OpportunityLineItemSchedule>();
    
    public void EstablishRevenueSchedule(OpportunityLineItem item){
        
        Opportunity Opp = [select Id, Start_Date__c, Contract_Term__c from Opportunity where Id = :item.OpportunityId limit 1];
        
        date startDate = opp.Start_Date__c;
        decimal revenue = item.TotalPrice;
        integer instalments = integer.valueOf(opp.Contract_Term__c);
        
        if(instalments > 0){
        
            for(integer i=0; i<instalments; i++){
                
                OpportunityLineItemSchedule scheduleItem = new OpportunityLineItemSchedule();
                
                scheduleItem.OpportunityLineItemId = item.Id;
                //scheduleItem.Quantity = instalments;
                scheduleItem.Revenue = revenue;
                scheduleItem.ScheduleDate = startDate.addMonths(i);
                scheduleItem.Type = 'Revenue';
                
                scheduleItems.add(scheduleItem);
                
            }
        }
        
        if(scheduleItems.size() > 0)
            database.upsert(scheduleItems);
        
    }
    
    public void ReestablishRevenueSchedule(OpportunityLineItem item){
        
     	List<OpportunityLineItemSchedule> deleteList = [select Id from OpportunityLineItemSchedule where OpportunityLineItemId = :item.Id];
        database.delete(deleteList);
        
        EstablishRevenueSchedule(item);
        
    }
}