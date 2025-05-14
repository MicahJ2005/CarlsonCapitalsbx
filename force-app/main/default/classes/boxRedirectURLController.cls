/**
 * @description       : 
 * @author            : micahj@demandchain.com
 * @group             : 
 * @last modified on  : 11-30-2022
 * @last modified by  : Michael Lloyd (Demand Chain)
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   11-23-2022   micahj@demandchain.com   Initial Version
**/
global class boxRedirectURLController {
    @InvocableMethod(label='Box Redirect' description='For Redirecting Box to a New Browser Window')
    public static list<string> redirectBoxInNewWindow(List<String> objId){
        box.ToolKit toolkit = new box.ToolKit();

        String folderId = Test.isRunningTest() ? sendTestBoxCallout('getFolderIdByRecordId').getBody() : toolkit.getFolderIdByRecordId(objId[0]);
        String endpoint = 'https://carlsoncap.app.box.com/folder/' + folderId;
        list<string> endpointList = new list<string>();
        endpointList.add(endpoint);
        return endpointList;
    }

    public static HttpResponse sendTestBoxCallout(String endpoint) {
        HttpRequest testReq = new HttpRequest();
        testReq.setEndpoint(endpoint);
        Http http = new Http();
        HttpResponse testResp = http.send(testReq);
        return testResp;
    }
}