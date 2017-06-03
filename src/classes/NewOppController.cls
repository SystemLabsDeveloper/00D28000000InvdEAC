public class NewOppController {
    
    public string opptyType {get;set;}
    public static decimal opptyAmount {get;set;}
    public static integer subscriptionTerm {get;set;}

    public NewOppController(ApexPages.StandardController controller) {
        opptyType = '0';
        subscriptionTerm = 0;
    }
    
}