Public with sharing Class helpme {
    
    List<KnowledgeArticleVersion> mylist = new List<KnowledgeArticleVersion>();
    Asset theasset;    
    string srch;
    
     public string getSrch(){
         return srch;
         }
     
      public void setSrch(String s) {
      srch = s;
   }

    Public Asset getTheasset(){
        theasset = [select id, product_type__c, description from asset where id =: ApexPages.currentPage().getParameters().get('def_asset_id')];
        return theasset;
        }
        
    Public Pagereference dosearch(){
        
 
        return page.partresults;
    }
    
    Public List<KnowledgeArticleVersion> getMylist(){
    
        srch = srch + ',' + asset.description;
        List<List<SObject>> searchlist = [FIND :srch RETURNING KnowledgeArticleVersion
        (Id, Title, UrlName WHERE PublishStatus='online')
        ];
        KnowledgeArticleVersion [] mylist = ((List<KnowledgeArticleVersion>)searchList[0]);
         
        return mylist;
        }
    
}