@isTest
global class ABNLookupMockResponse implements HttpCalloutMock {
    
    global static testMethod string getResponseString(){
        return [select Id, Body from StaticResource where Name = 'ABNLookupMockResponse' limit 1].Body.toString();
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody(getResponseString());
        res.setStatusCode(200);
        return res;
    }
}