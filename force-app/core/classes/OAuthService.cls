public with sharing class OAuthService {
    private static final ToolingAPIService.AUTH_METHOD DEFAULT_AUTH_METHOD = ToolingApiService.DEFAULT_AUTH_METHOD;
    private static final String DEFAULT_CA = 'PLC_Device_Flow';
    private static final String DEFAULT_DOMAIN = URL.getOrgDomainUrl()
        .toExternalForm();
    private static final String DEFAULT_USERNAME = UserInfo.getUserName();

    private String authEndpoint;
    private ToolingApiService.AUTH_METHOD authMethod;
    private ConnectedApp ca;
    private String nsPrefix;

    private static final OAuthResponse TEST_OAUTH_RESP_DEVICE_CODES = (OAuthResponse) JSON.deserialize(
        '{"device_code":"abc","user_code":"123"}',
        OAuthResponse.class
    );
    private static final OAuthResponse TEST_OAUTH_RESP_ACCESS_TOKEN = (OAuthResponse) JSON.deserialize(
        '{"access_token":"abc","refresh_token":"123"}',
        OAuthResponse.class
    );

    public OAuthService() {
        this(DEFAULT_AUTH_METHOD, DEFAULT_CA, DEFAULT_DOMAIN);
    }

    public OAuthService(String domain) {
        this(DEFAULT_AUTH_METHOD, DEFAULT_CA, domain);
    }

    public OAuthService(
        ToolingApiService.AUTH_METHOD authMethod,
        String domain
    ) {
        this(authMethod, DEFAULT_CA, domain);
    }

    public OAuthService(
        ToolingApiService.AUTH_METHOD authMethod,
        String caName,
        String domain
    ) {
        this.authEndpoint = domain + '/services/oauth2/token';
        this.authMethod = authMethod;
        ConnectedApp__mdt connectedApp = ConnectedAppSelector.fetchByName(
            caName
        );
        this.ca = (ConnectedApp) JSON.deserialize(
            connectedApp.Value__c,
            ConnectedApp.class
        );
        this.nsPrefix = connectedApp.QualifiedApiName.contains('__')
            ? connectedApp.QualifiedApiName.substringBefore('__')
            : null;
    }

    public static String getToken() {
        String oauthFlow;
        switch on DEFAULT_AUTH_METHOD {
            when OAUTH_DEVICE {
                oauthFlow = 'device';
            }
            when else {
                oauthFlow = 'unknown';
            }
        }
        return getToken(oauthFlow, DEFAULT_USERNAME);
    }

    public static String getToken(String oauthFlow, String username) {
        return (getOAuthCreds(oauthFlow, username)).access_token;
    }

    public static String getRefreshToken() {
        String oauthFlow;
        switch on DEFAULT_AUTH_METHOD {
            when OAUTH_DEVICE {
                oauthFlow = 'device';
            }
            when else {
                oauthFlow = 'unknown';
            }
        }
        return getRefreshToken(oauthFlow, DEFAULT_USERNAME);
    }

    public static String getRefreshToken(String oauthFlow, String userName) {
        return (getOAuthCreds(oauthFlow, username)).refresh_token;
    }

    public Map<String, String> generateCodesFromDeviceFlow() {
        String body =
            'response_type=device_code&client_id=' +
            EncodingUtil.urlEncode(this.ca.client_id, 'UTF-8') +
            '&scope=' +
            EncodingUtil.urlEncode(this.ca.scope, 'UTF-8');
        OAuthResponse resp = Test.isRunningTest()
            ? TEST_OAUTH_RESP_DEVICE_CODES
            : makeOAuthRequest(body);
        return new Map<String, String>{
            'device_code' => resp.device_code,
            'user_code' => resp.user_code
        };
    }

    public OAuthResponse generateAccessTokenFromDeviceFlow(String deviceCode) {
        String body =
            'grant_type=device&client_id=' +
            EncodingUtil.urlEncode(this.ca.client_id, 'UTF-8') +
            '&code=' +
            EncodingUtil.urlEncode(deviceCode, 'UTF-8');
        return Test.isRunningTest()
            ? TEST_OAUTH_RESP_ACCESS_TOKEN
            : makeOAuthRequest(body);
    }

    public OAuthResponse generateAccessTokenFromRefreshFlow(
        String refreshToken
    ) {
        String body =
            'grant_type=refresh_token&client_id=' +
            EncodingUtil.urlEncode(this.ca.client_id, 'UTF-8') +
            '&client_secret=' +
            EncodingUtil.urlEncode(this.ca.client_secret, 'UTF-8') +
            '&refresh_token=' +
            EncodingUtil.urlEncode(refreshToken, 'UTF-8');
        return Test.isRunningTest()
            ? TEST_OAUTH_RESP_ACCESS_TOKEN
            : makeOAuthRequest(body, false);
    }

    public void upsertOAuthCredsCMDT(OAuthCredentials creds) {
        upsertOAuthCredsCMDT(new List<OAuthCredentials>{ creds });
    }

    public void upsertOAuthCredsCMDT(List<OAuthCredentials> credsList) {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for (OAuthCredentials creds : credsList) {
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            String fullNameWithoutNS =
                'OAuthCreds.' +
                OAuthCredsSelector.sanitize(
                    creds.oauth_flow +
                    '_' +
                    creds.user_username
                );
            customMetadata.fullName = this.nsPrefix != null
                ? this.nsPrefix + '__' + fullNameWithoutNS
                : fullNameWithoutNS;
            customMetadata.label = creds.user_username;
            Metadata.CustomMetadataValue valueField = new Metadata.CustomMetadataValue();
            valueField.field = nsPrefix != null
                ? nsPrefix + '__' + 'Value__c'
                : 'Value__c';
            valueField.value = JSON.serialize(creds, true);
            customMetadata.values.add(valueField);
            mdContainer.addMetadata(customMetadata);
        }
        Metadata.Operations.enqueueDeployment(
            mdContainer,
            new CustomMetadataCallback()
        );
    }

    private static OAuthCredentials getOAuthCreds(
        String oauthFlow,
        String username
    ) {
        List<OAuthCreds__mdt> storedCreds = OAuthCredsSelector.fetchByUsername(
            oauthFlow,
            username
        );
        if (storedCreds.isEmpty()) {
            throwUnauthorizedUserError();
        }
        OAuthCredentials oauthCreds = (OAuthCredentials) JSON.deserialize(
            Test.isRunningTest()
                ? OAuthCredsSelector.TEST_OAUTH_CREDS_VALUE
                : storedCreds[0].Value__c,
            OAuthCredentials.class
        );
        if (oauthCreds == null || oauthCreds.access_token == null) {
            throwUnauthorizedUserError();
        }
        return oauthCreds;
    }

    private OAuthResponse makeOAuthRequest(String requestBody) {
        return makeOAuthRequest(requestBody, true);
    }

    private OAuthResponse makeOAuthRequest(
        String requestBody,
        Boolean saveOAuthResponse
    ) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(authEndpoint);
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        req.setBody(requestBody);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        try {
            OAuthResponse oauthResponse = (OAuthResponse) JSON.deserialize(
                res.getBody(),
                OAuthResponse.class
            );

            if (
                res.getStatusCode() == 200 &&
                oauthResponse.id != null &&
                saveOAuthResponse
            ) {
                saveOAuthResponse(oauthResponse);
            }

            return oauthResponse;
        } catch (System.Exception e) {
            throw new OAuthException(
                'OAuth Failure: ' +
                res.getStatusCode() +
                ' Body:' +
                res.getBody()
            );
        }
    }

    public void saveOAuthResponse(OAuthResponse oauthResponse) {
        String idRequestBody =
            'access_token=' +
            EncodingUtil.urlEncode(oauthResponse.access_token, 'UTF-8') +
            '&format=json';
        String idEndpoint = oauthResponse.id;
        idEndpoint =
            oauthResponse.instance_url +
            idEndpoint.substringAfter('.salesforce.com');
        HttpRequest idReq = new HttpRequest();
        idReq.setMethod('GET');
        idReq.setEndpoint(idEndpoint);
        idReq.setHeader('Content-type', 'application/x-www-form-urlencoded');
        idReq.setBody(idRequestBody);

        Http idHttp = new Http();
        HTTPResponse idRes = idHttp.send(idReq);

        if (idRes.getStatusCode() != 200) {
            throw new IdentityException(
                'Identity Failure: ' +
                idRes.getStatusCode() +
                ' Body:' +
                idRes.getBody()
            );
        }

        OAuthResponse idOauthResponse = (OAuthResponse) JSON.deserialize(
            idRes.getBody(),
            OAuthResponse.class
        );

        OAuthCredentials creds = new OAuthCredentials();
        creds.domain = authEndpoint;
        creds.is_sandbox = authEndpoint.contains('.sandbox.');
        creds.is_scratch = authEndpoint.contains('.scratch.');
        if (authEndpoint.substringBetween('--', '.sandbox.') != null) {
            creds.sandbox_name = authEndpoint.substringBetween(
                '--',
                '.sandbox.'
            );
        }
        creds.access_token = oauthResponse.access_token;
        creds.refresh_token = oauthResponse.refresh_token;
        creds.signature = oauthResponse.signature;
        creds.scope = oauthResponse.scope;
        creds.instance_url = oauthResponse.instance_url;
        creds.id = oauthResponse.id;
        creds.token_type = oauthResponse.token_type;
        creds.issued_at = oauthResponse.issued_at;
        switch on this.authMethod {
            when OAUTH_DEVICE {
                creds.oauth_flow = 'device';
            }
            when else {
                creds.oauth_flow = 'unknown';
            }
        }
        creds.organization_id = idOauthResponse.organization_id;
        creds.user_id = idOauthResponse.user_id;
        creds.user_username = idOauthResponse.username;
        creds.user_display_name = idOauthResponse.display_name;
        creds.user_email = idOauthResponse.email;

        upsertOAuthCredsCMDT(creds);
    }

    private static void throwUnauthorizedUserError() {
        throw new OAuthException(
            'OAuth Failure: User has not yet been authorized. Please authorize the user from app settings and then try again'
        );
    }

    class ConnectedApp {
        public String client_id { get; private set; }
        public String client_secret { get; private set; }
        public String scope;
        public String flow;
        public String name { get; private set; }
    }

    class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(
            Metadata.DeployResult result,
            Metadata.DeployCallbackContext context
        ) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                // Deployment was successful
            } else {
                throw new CustomMetadataException(
                    'Custom Metadata Failure: ' + result
                );
            }
        }
    }

    class CustomMetadataException extends Exception {
    }

    class IdentityException extends Exception {
    }

    public class OAuthCredentials {
        public String domain;
        public Boolean is_sandbox;
        public Boolean is_scratch;
        public String sandbox_name;
        public String access_token;
        public String refresh_token;
        public String signature;
        public String scope;
        public String instance_url;
        public String id;
        public String token_type;
        public Long issued_at;
        public String oauth_flow;
        public String organization_id;
        public String user_id;
        public String user_username;
        public String user_display_name;
        public String user_email;
    }

    class OAuthException extends Exception {
    }

    public class OAuthResponse {
        public String access_token { get; private set; }
        public String device_code { get; private set; }
        public String display_name { get; private set; }
        public String email { get; private set; }
        public String error { get; private set; }
        public String error_description { get; private set; }
        public String instance_url { get; private set; }
        public String id { get; private set; }
        public String interval { get; private set; }
        public Long issued_at { get; private set; }
        public String organization_id { get; private set; }
        public Map<String, String> photos { get; private set; }
        public String refresh_token { get; set; }
        public String scope { get; private set; }
        public String signature { get; private set; }
        public String token_type { get; private set; }
        public String user_code { get; private set; }
        public String user_id { get; private set; }
        public String username { get; private set; }
        public String verification_uri { get; private set; }
    }
}