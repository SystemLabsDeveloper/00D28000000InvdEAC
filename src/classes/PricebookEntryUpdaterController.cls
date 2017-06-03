public class PricebookEntryUpdaterController {
    
    @AuraEnabled
    public static string pricebookId {get;set;}
    
    public static blob fileblob {get;set;}
    
    public static string errorString {get;set;}
    
    public static map<string, string> pricebookEntryMap {get;set;}
    public static map<string, string> productMap {get;set;}

    @AuraEnabled
    public static List<Pricebook2> getActivePricebooks(){
        return [select Id, Name
                from Pricebook2
                where isActive = true];
    }
    
    @AuraEnabled
    public static List<string> getMatchingFields(){
        
        List<string> fieldNames = new List<string>();

        Map <String, Schema.SObjectField> fieldMap = PricebookEntry.sObjectType.getDescribe().fields.getMap();
        
        for(string field : fieldMap.keySet()){
            Schema.DescribeFieldResult dr = fieldMap.get(field).getDescribe();
            
            system.debug('field describe: ' + dr);
            
            if(dr.isUnique()){
                fieldNames.add(dr.getLabel()); 
            }
        }
        
        return fieldNames;
    }
    
    public static void getPricebookEntryMap(){
        pricebookEntryMap = new map<string, string>();
        
        List<PricebookEntry> pbeList = [select id, ProductCode, Product2Id from PricebookEntry where Pricebook2Id = :pricebookId];
        
        for(PricebookEntry pbe : pbeList){
            pricebookEntryMap.put(pbe.ProductCode, pbe.Id);
        }
        
        system.debug('pricebook entry map: ' + pricebookEntryMap);
    }
    
    public static void getProductMap() {
        productMap = new map<string,string>();
        
        List<Product2> productList = [select Id, ProductCode from Product2 where isActive = true];
        
        for(Product2 p : productList){
            productMap.put(p.ProductCode, p.Id);
        }
    }

    @AuraEnabled
    public static string updatePricebookEntries(string pbId, string fileContent, boolean updateInactive){
        
        system.debug('Pricebook Id : ' + pbId);
        system.debug('fileContent: ' + fileContent);
        
        pricebookId = pbId;
        
        HttpRequest tmp = new HttpRequest();
        tmp.setBodyAsBlob(blob.valueOf(fileContent));
        String filecsv = tmp.getBody(); //this seem to be a valid utf-8 string
        
        /*string filecsv = fileblob.toString().substringBeforeLast('\n');
        system.debug(filecsv);*/
        
        List<string> filerows = filecsv.split('\n');
        
        //validateHeader(filerows[0]);
        
        getPricebookEntryMap();
        getProductMap();
        return processrows(fileRows);
        
    }

    @AuraEnabled
    public static string processrows(List<string> filerows){
        
        errorString = 'Error,Pricebook Id, Item Number, Unit Price\n';
        
        set<PricebookEntry> pricebookEntriesForUpsert = new set<PricebookEntry>();
        set<id> entryIds = new set<id>();
        
        for(integer i = 1; i < filerows.size(); i++){
            List<string> cells = filerows[i].split(',');
            
            string itemNo = cells[0];
            string unitPrice = cells[1];
            
            boolean valid = true;
                        
            if(!cells.isEmpty()){

                PricebookEntry entry = new PricebookEntry();
                
                if(pricebookEntryMap.containsKey(itemNo)){
                    entry.Id = pricebookEntryMap.get(itemNo);
                } else {
                    if(productMap.containsKey(itemNo)){
                        entry.Pricebook2Id = pricebookId;
                        entry.Product2Id = productMap.get(itemNo);
                    } else {
                        errorString += 'Insert Error: No active product found with Item Number ' + itemNo + ',' + pricebookId + ',' + itemNo + ',' + unitPrice + '\n';
                        valid = false;
                    }
                }
                
                //system.debug('PricebookEntryMap.keySet(): ' + pricebookEntryMap.keySet());
                if(valid){
                    entry.UnitPrice = double.valueOf(unitPrice);
                    
                    system.debug('Entry Id: ' + entry.Id);
                    system.debug('EntryId already in set: ' + entryIds.contains(entry.id));
                    
                    if(entry.Id == null || (entry.Id != null && !entryIds.contains(entry.Id))){
                        pricebookEntriesForUpsert.add(entry);
                        entryIds.add(pricebookEntryMap.get(itemNo));
                    } else {
                        errorString += 'Error: Duplicate Item Number found in file: ' + itemNo + ',' + pricebookId + ',' + itemNo + ',' + unitPrice + '\n';
                        pricebookEntriesForUpsert.remove(entry);
                    }
                }
            }
        }

        if(!pricebookEntriesForUpsert.isEmpty()){
            List<PricebookEntry> upsertList = new List<PricebookEntry>();
            upsertList.addAll(pricebookEntriesForUpsert);
            
            system.debug(pricebookEntriesForUpsert);
            system.debug(upsertList);
            
            Database.UpsertResult[] upsertResults = database.upsert(upsertList, false);
            
            for(Database.UpsertResult result : upsertResults){
                if(!result.isSuccess()){
                    errorString += 'Upsert Error: ' + result.getErrors() + ',,,\n';
                }
            }
        }
        
        if(errorString != 'Error,Pricebook Id, Item Number, Unit Price\n'){
            errorString = 'Total Rows Uploaded: ' + (fileRows.size() - 1) + '\nTotal Error Rows: ' + (errorString.split('\n').size() - 1) + '\n' + errorString;
            
            system.debug('Total Rows Uploaded: ' + (fileRows.size() - 1));
            system.debug('Total Error Rows: ' + (errorString.split('\n').size() - 1));
            
            // create error attachment
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setBody(blob.valueOf(errorString));
            att.setFileName('PricebookUpsertErrors.csv');
            
            // send error email
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            // Set recipients to two contact IDs.
            // Replace IDs with valid record IDs in your org.
            message.toAddresses = new String[] { UserInfo.getUserEmail() };
            message.subject = 'Pricebook Upsert Errors';
            message.plainTextBody = 'There were errors during your upsert.';
            
            message.setFileAttachments(new Messaging.EmailFileAttachment[]{att});
            
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            messages.add(message);
                
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            
        }
        
        return 'There were ' + ((fileRows.size() - 1) - (errorString.split('\n').size() - 1)) + ' successful upserts and ' + (errorString.split('\n').size() - 1) + ' errors';
        
    }
    
    
}