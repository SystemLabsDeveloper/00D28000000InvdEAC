public class DailyRoutineController {
    
    public class result{
        public date routineDate {get;set;}
        public list<resultItem> resultItems {get;set;}
        public string status {get;set;}
    }
    
    public class resultItem{
        public Routine_Item__c item {get;set;}
        public string status {get;set;}
        public datetime startTime {get;set;}
        public datetime endTime {get;set;}
        public integer timeTaken {get;set;}
    }
    
    public static Day_Of_Week__c dayOfWeek {get;set;}
    public static List<Day_Of_Week_Routine_Item__c> routineItems {get;set;}
    
    public static result result {get;set;}
    
    public DailyRoutineController(){
        dayOfWeek = [select Id, Name, (select Id, Routine_Item__r.Time_Allowed_mins__c, Routine_Item__r.Name, Time_Allowed_mins__c from Day_Of_Week_Routine_Items__r Order By Order__c ASC) from Day_Of_Week__c where Name = :system.now().format('EEEE') limit 1];
        routineItems = dayOfWeek.Day_Of_Week_Routine_Items__r;
        
        result = new Result();
        result.resultItems = new List<resultItem>();
        
        doGetResults();
        system.debug('result : ' + result);
    }
    
    public static void doGetResults(){
        
        List<Routine_Result__c> existingResult = [select Id, Routine_Date__c, Status__c, (select Id, Routine_Item__r.Time_Allowed_mins__c, Start_Time__c, End_Time__c from Routine_Result_Items__r) from Routine_Result__c where Routine_Date__c = :system.today() limit 1];
        
        if(!existingResult.isEmpty()){
            
            result.routineDate = existingResult[0].Routine_Date__c;
            result.Status = existingResult[0].Status__c;
            
            List<Routine_Result_Item__c> routineResultItems = existingResult[0].Routine_Result_Items__r;
            
            if(!routineResultItems.isEmpty()){
                for(Routine_Result_Item__c rri : routineResultItems){
                    resultItem ri = new ResultItem();
                    ri.item = rri.Routine_Item__r;
                    ri.status = rri.Status__c;
                    ri.startTime = rri.Start_Time__c;
                    ri.endTime = rri.End_Time__c;
                    
                    result.resultItems.add(ri);
                } 
            } else {
                for(Day_Of_Week_Routine_Item__c dwri : routineItems){
                    
                    resultItem ri = new ResultItem();
                    ri.item = dwri.Routine_Item__r;
                    ri.status = 'Not Started';
                    
                    result.resultItems.add(ri);
                }
            }
        } else {
            
            result.routineDate = system.today();
            result.Status = 'Pending';
            
            for(Day_Of_Week_Routine_Item__c dwri : dayOfWeek.Day_Of_Week_Routine_Items__r){
                
                resultItem ri = new resultItem();
                
                ri.item = dwri.Routine_Item__r;
                ri.status = 'Not Started';

                result.resultItems.add(ri);
            }
        }
    }
}