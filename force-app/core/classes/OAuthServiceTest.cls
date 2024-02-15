@isTest
public with sharing class OAuthServiceTest {
    @isTest
    static void testOAuthServiceConstructors() {
        OAuthService oa = new OAuthService();
        OAuthService oa2 = new OAuthService(URL.getOrgDomainUrl().toExternalForm());
        OAuthService oa3 = new OAuthService(null, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService oaCredentialsFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_CREDENTIALS, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService oaDeviceFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_DEVICE, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService oaJWTAdminKeyFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_JWT_ADMIN_KEY, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService oaJWTPackagedKeyFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_JWT_KEY_PACKAGED, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService oaServerFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_WEB_SERVER, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
    }

    @isTest
    static void testGetToken() {
        String oaToken = OAuthService.getToken();
        String oaCredentialsFlowToken = OAuthService.getToken('creds', UserInfo.getUserName());
        String oaDeviceFlowToken = OAuthService.getToken('device', UserInfo.getUserName());
        String oaJWTAdminKeyFlowToken = OAuthService.getToken('jwt_ak', UserInfo.getUserName());
        String oaJWTPackagedKeyFlowToken = OAuthService.getToken('jwt_kp', UserInfo.getUserName());
        String oaServerFlowToken = OAuthService.getToken('web', UserInfo.getUserName());
    }

    @isTest
    static void testGetRefreshToken() {
        String oaRefreshToken = OAuthService.getRefreshToken();
        String oaCredentialsFlowRefreshToken = OAuthService.getRefreshToken('creds', UserInfo.getUserName());
        String oaDeviceFlowRefreshToken = OAuthService.getRefreshToken('device', UserInfo.getUserName());
        String oaJWTAdminKeyFlowRefreshToken = OAuthService.getRefreshToken('jwt_ak', UserInfo.getUserName());
        String oaJWTPackagedKeyFlowRefreshToken = OAuthService.getRefreshToken('jwt_kp', UserInfo.getUserName());
        String oaServerFlowRefreshToken = OAuthService.getRefreshToken('web', UserInfo.getUserName());
    }

    @isTest
    static void testGenerateAccessTokenFromCredentialsFlow() {
        OAuthService oaCredentialsFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_CREDENTIALS, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService.OAuthResponse oaResp = oaCredentialsFlow.generateAccessTokenFromCredentialsFlow();
    }

    @isTest
    static void testGenerateCodesFromDeviceFlow() {
        OAuthService oaDeviceFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_DEVICE, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        Map<String,String> codesByType = oaDeviceFlow.generateCodesFromDeviceFlow();
    }

    @isTest
    static void testGenerateAccessTokenFromDeviceFlow() {
        OAuthService oaDeviceFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_DEVICE, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService.OAuthResponse oaResp = oaDeviceFlow.generateAccessTokenFromDeviceFlow('device_code');
    }

    @isTest
    static void testGenerateAccessTokenFromJWTAdminKeyFlow() {
        OAuthService oaJWTAdminKeyFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_JWT_ADMIN_KEY, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService.OAuthResponse oaResp = oaJWTAdminKeyFlow.generateAccessTokenFromJWTAdminKeyFlow('cert_name','consumer_key','username');
    }

    @isTest
    static void testGenerateAccessTokenFromJWTPackagedKeyFlow() {
        OAuthService oaJWTPackagedKeyFlow = new OAuthService(ToolingApiService.AUTH_METHOD.OAUTH_JWT_KEY_PACKAGED, OAuthService.DEFAULT_CMDT_UPSERT_METHOD, URL.getOrgDomainUrl().toExternalForm());
        OAuthService.OAuthResponse oaResp = oaJWTPackagedKeyFlow.generateAccessTokenFromJWTPackagedKeyFlow('username');
    }

    @isTest
    static void testGenerateAccessTokenFromRefreshFlow() {
        OAuthService oa = new OAuthService();
        OAuthService.OAuthResponse oaResp = oa.generateAccessTokenFromRefreshFlow('refresh_token');
    }

    @isTest
    static void testOAuthResponse() {
        OAuthService oa = new OAuthService();
        OAuthService.OAuthResponse oaResp = oa.generateAccessTokenFromRefreshFlow('refresh_token');
        String access_token = oaResp.access_token;
        String device_code = oaResp.device_code;
        String display_name = oaResp.display_name;
        String email = oaResp.email;
        String error = oaResp.error;
        String error_description = oaResp.error_description;
        String instance_url = oaResp.instance_url;
        String id = oaResp.id;
        String interval = oaResp.interval;
        Long issued_at = oaResp.issued_at;
        String organization_id = oaResp.organization_id;
        Map<String, String> photos = oaResp.photos;
        String refresh_token = oaResp.refresh_token;
        String scope = oaResp.scope;
        String signature = oaResp.signature;
        String token_type = oaResp.token_type;
        String user_code = oaResp.user_code;
        String user_id = oaResp.user_id;
        String username = oaResp.username;
        String verification_uri = oaResp.verification_uri;
    }

    @isTest
    static void testMakeOAuthRequest() {
        OAuthService oa = new OAuthService();
        OAuthService.OAuthResponse oaResp = oa.makeOAuthRequest('test_body');
    }

}
