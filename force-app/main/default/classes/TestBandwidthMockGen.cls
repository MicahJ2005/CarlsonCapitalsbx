@isTest 
global class TestBandwidthMockGen implements HttpCalloutMock {

    global static HTTPResponse respond(HTTPRequest req) {
        String endpoint = req.getEndpoint();
        HTTPResponse resp = new HTTPResponse();
        System.debug(endpoint);
        if(endpoint == 'https://api.catapult.inetwork.com/v1/users/u-aqb2en3yrnnfz27tgavdgti/phoneNumbers') {
            resp.setStatus('OK');
            resp.setBody('[{"application":"https://api.catapult.inetwork.com/v1/users/u-aqb2en3yrnnfz27tgavdgti/applications/a-2rs6y3ahd662toosh3dj5na","id":"n-taarvianqfzsvivmqqsnzoq","applicationId":"a-2rs6y3ahd662toosh3dj5na","number":"+15074030864","nationalNumber":"(507) 403-0864","createdTime":"2017-11-08T20:19:48Z","city":"NORTHFIELD","state":"MN","price":"0.35","numberState":"enabled"},{"application":"https://api.catapult.inetwork.com/v1/users/u-aqb2en3yrnnfz27tgavdgti/applications/a-2rs6y3ahd662toosh3dj5na","id":"n-rucfnuld27nmjxcwhwahffi","applicationId":"a-2rs6y3ahd662toosh3dj5na","number":"+15074037157","nationalNumber":"(507) 403-7157","createdTime":"2017-09-20T18:57:02Z","city":"NORTHFIELD","state":"MN","price":"0.35","numberState":"enabled"}]');
        } else if(endpoint == 'https://messaging.bandwidth.com/api/v2/users/5005537/messages') {
            resp.setStatus('Created');
        } else if(endpoint == 'https://api.catapult.inetwork.com/v1/users/u-aqb2en3yrnnfz27tgavdgti/calls/123456789') {
            resp.SetStatus('Created');
        }
        return resp;
    }
}