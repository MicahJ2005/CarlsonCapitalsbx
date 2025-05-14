/**
 * @description       : 
 * @author            : Michael Lloyd (Demand Chain)
 * @group             : 
 * @last modified on  : 10-12-2022
 * @last modified by  : Michael Lloyd (Demand Chain)
**/
@isTest
global class MockBoxToolkitResponse implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if (req.getEndpoint() == 'getFolderIdByRecordId') {
            res.setBody('174571899157');
        } else if (req.getEndpoint() == 'sendRequestForFolderItems') {
            res.setBody('{"total_count":8,"entries":[{"type":"folder","id":"175796508981","sequence_id":"0","etag":"0","name":"Client Documentation"}]}');
        } else if (req.getEndpoint() == 'createFileFromAttachment') {
            res.setBody('175796501234');
        } else {
            res.setBody('');
        }
        return res;
    }
}