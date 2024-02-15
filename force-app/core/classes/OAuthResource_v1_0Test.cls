@isTest
public with sharing class OAuthResource_v1_0Test {
    @isTest
    static void testHandlePost() {
        Map<String,Object> params = new Map<String,Object>{
            'domain' => URL.getOrgDomainURL().toExternalForm(),
            'access_token' => '12345',
            'refresh_token' => '54321',
            'scope' => 'api id refresh',
            'instance_url' => URL.getOrgDomainURL().toExternalForm(),
            'organization_id' => '00D000000000000',
            'user_id' => '005000000000000',
            'user_username' => 'test@test.com',
            'user_display_name' => 'User User',
            'user_email' => 'test@test.com'
        };
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1.0/oauth';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(params));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        OAuthResource_v1_0.handlePost();
        Test.stopTest();
    }
}
