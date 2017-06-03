global class testClass {

    public class address{
        public string street {get;set;}
        public string city {get;set;}
        public string state {get;set;}
        public string postcode {get;set;}
        
        public address(string st, string c, string s, string p){
            this.street = st;
            this.city = c;
            this.postcode = p;
            this.state = s;
        }
        
        public string format(){
            return this.street + ', ' + this.city + ', ' + this.state.toUpperCase() + ' ' + this.postcode;
        }
        
        public string formatEpoch(){
            return this.format() + ' ' + system.now().getTime();
        }
    }
    
    public static void formatAddy(){
        address a = new address(
            '88 Bradleys Head Rd',
            'Mosman',
            'nsw',
            '2088'
        );

        system.debug(a.formatEpoch());
    }
    
}