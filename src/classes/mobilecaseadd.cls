Public with Sharing Class mobilecaseadd {




    private final case mycase;
    
    public mobilecaseadd(ApexPages.StandardController stdController) {
           this.mycase = (case)stdController.getRecord();
           }
           
     public PageReference addcase() {
         mycase.assetID = ApexPages.currentPage().getParameters().get('def_asset_id');        
         insert mycase;                
         return Page.partcasecreated;     }

}