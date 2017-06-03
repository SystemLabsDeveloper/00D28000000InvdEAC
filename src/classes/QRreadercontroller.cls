public with sharing class  QRreadercontroller {
    
    public String qr{get;set;}
    public String subUrl{get;set;}      
    
    public QRreaderController (){
        // To get the host url of the instance the application is working on. 
        subUrl= URL.getSalesforceBaseUrl().getHost(); 
        
        // Setting the value passed as the parameter to string variable.
        // Parameter code is retured by the zxing app after reading the QR code.
        qr=apexpages.currentpage().getparameters().get('qr');
    }
    
    public PageReference scanCode() {
        
        PageReference scan = new PageReference('ilu://x-callback-url/scanner-go?x-source=a&x-success=http://www.google.com/?a=1&&sg-result=q');
        //PageReference scan = new PageReference('ilu://x-callback-url/scanner-go?x-source=salesforce1&x-success=https%3A%2F%2Fap2.salesforce.com%2Fapex%2FtestPage?sg-result=qr');
        //PageReference scan = new PageReference('zxing://scan/?ret=https://{!subUrl}/apex/testPage?qr={CODE}&SCAN_FORMATS=UPC_A,EAN_13');
        //PageReference scan = new PageReference('pic2shop://scan?callback=https%3A%2F%2F%7B!subURL%7D%2Fapex%2FtestPage%3Fid%3DEAN');
        //PageReference scan = new PageReference('pic2shop://scan?callback=https://{!subURL}/apex/qr_reader?EAN');
        return scan;
    }
    
}