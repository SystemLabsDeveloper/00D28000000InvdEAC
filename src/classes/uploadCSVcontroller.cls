public class uploadCSVcontroller {

        public blob contentFile { 
            get{
                StaticResource sr = [select Body from StaticResource where Name = 'relatedToCSV' limit 1][0];
                return sr.body;
            }
        }
        public String nameFile { get; set; }

       
        public pageReference insertRows() {
            List<List<String>> parsedCSV = new List<List<String>>();

            if (contentFile != null){
                String fileString = contentFile.toString();
                parsedCSV = parseCSV(fileString, false);
            }
            
            List<RelatedTo__c> rtList = new List<RelatedTo__c>();
            
            for(List<string> result : parsedCSV){
                system.debug(result); 
                
                RelatedTo__c rt = new RelatedTo__c();
                    rt.Name = result[0];
                    rt.Locked__c = boolean.valueOf(result[1]);
                    rt.Active__c = boolean.valueOf(result[2]);
                
                system.debug(rt);
                rtList.add(rt);
                
            }
            try{
                rtList.remove(0);
                insert rtList;
            } catch (exception e){
                system.debug(e);
            }
            
            pagereference retURL = new pagereference('/a00?fcf=00B28000001PNlx');
            return retURL;
        }

       
        /*
        Credit to
        http://wiki.developerforce.com/index.php/Code_Samples#Parse_a_CSV_with_APEX
        */
        public static List<List<String>> parseCSV(String contents,Boolean skipHeaders) {
            List<List<String>> allFields = new List<List<String>>();
       
            // replace instances where a double quote begins a field containing a comma
            // in this case you get a double quote followed by a doubled double quote
            // do this for beginning and end of a field
            contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
            // now replace all remaining double quotes - we do this so that we can reconstruct
            // fields with commas inside assuming they begin and end with a double quote
            contents = contents.replaceAll('""','DBLQT');
            // we are not attempting to handle fields with a newline inside of them
            // so, split on newline to get the spreadsheet rows
            List<String> lines = new List<String>();
            try {
                //lines = contents.split('\n'); //correction: this only accomodates windows files
                lines = contents.split('\r'); // using carriage return accomodates windows, unix, and mac files
                //http://www.maxi-pedia.com/Line+termination+line+feed+versus+carriage+return+0d0a
            } catch (System.ListException e) {
                System.debug('Limits exceeded?' + e.getMessage());
            }
            Integer num = 0;
            for(String line: lines) {
                // check for blank CSV lines (only commas)
                if (line.replaceAll(',','').trim().length() == 0) break;
               
                List<String> fields = line.split(','); 
                List<String> cleanFields = new List<String>();
                String compositeField;
                Boolean makeCompositeField = false;
                for(String field: fields) {
                    if (field.startsWith('"') && field.endsWith('"')) {
                        cleanFields.add(field.replaceAll('DBLQT','"'));
                    } else if (field.startsWith('"')) {
                        makeCompositeField = true;
                        compositeField = field;
                    } else if (field.endsWith('"')) {
                        compositeField += ',' + field;
                        cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                        makeCompositeField = false;
                    } else if (makeCompositeField) {
                        compositeField +=  ',' + field;
                    } else {
                        cleanFields.add(field.replaceAll('DBLQT','"'));
                    }
                }
               
                allFields.add(cleanFields);
            }
            if (skipHeaders) allFields.remove(0);
            return allFields;      
        }

    }