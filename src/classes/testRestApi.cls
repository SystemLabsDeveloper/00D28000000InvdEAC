@RestResource(urlMapping='/repro-form-handler/*')
global class testRestApi {
    
    @HttpPost  
    global static string postSobjectData(string req){
        
        system.debug(req);
        return 'Completed Dude';
        
    }

}