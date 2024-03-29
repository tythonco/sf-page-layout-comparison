@RestResource(urlMapping='/v1.0/oauth')
global with sharing class OAuthResource_v1_0 {
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, Object> responseMap = new Map<String, Object>();
        try {
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.request.requestBody.toString()
            );
            upsertOAuthCredsCMDT(params);
            responseMap.put('success', true);
            res.statusCode = 200;
        } catch (Exception e) {
            responseMap.put(
                'error',
                e.getMessage() +
                ' ' +
                e.getStackTraceString()
            );
            res.statusCode = 500;
        }
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(responseMap));
    }

    private static void upsertOAuthCredsCMDT(Map<String, Object> params) {
        OAuthService.OAuthCredentials creds = new OAuthService.OAuthCredentials();
        String cmdtUpsertMethod = (String) params.get('cmdt_upsert_method');
        OAuthService.CMDT_UPSERT_METHOD cmdtUpsertChannel;
        switch on cmdtUpsertMethod {
            when 'apex' {
                cmdtUpsertChannel = OAuthService.CMDT_UPSERT_METHOD.APEX;
            }
            when 'api' {
                cmdtUpsertChannel = OAuthService.CMDT_UPSERT_METHOD.API;
            }
        }
        String domain = (String) params.get('domain');
        creds.domain = domain;
        creds.is_dev_edition = domain.contains('.develop.');
        creds.is_sandbox = domain.contains('.sandbox.');
        creds.is_scratch = domain.contains('.scratch.');
        if (domain.substringBetween('--', '.sandbox.') != null) {
            creds.sandbox_name = domain.substringBetween('--', '.sandbox.');
        }
        String identityDomain = creds.is_sandbox || creds.is_scratch
            ? 'https://test.salesforce.com'
            : 'https://login.salesforce.com';
        creds.access_token = (String) params.get('access_token');
        creds.refresh_token = (String) params.get('refresh_token');
        creds.scope = (String) params.get('scope');
        creds.instance_url = (String) params.get('instance_url');
        creds.oauth_flow = 'web';
        creds.organization_id = (String) params.get('organization_id');
        creds.user_id = (String) params.get('user_id');
        creds.user_username = (String) params.get('user_username');
        creds.user_display_name = (String) params.get('user_display_name');
        creds.user_email = (String) params.get('user_email');
        creds.id =
            identityDomain +
            '/id/' +
            creds.organization_id +
            '/' +
            creds.user_id;
        OAuthService auth = new OAuthService(
            ToolingAPIService.AUTH_METHOD.OAUTH_WEB_SERVER,
            cmdtUpsertChannel,
            URL.getOrgDomainUrl().toExternalForm()
        );
        auth.upsertOAuthCredsCMDT(creds, (String) params.get('source_access_token'));
    }
}
