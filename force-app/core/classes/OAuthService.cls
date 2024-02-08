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
    private static final OAuthResponse TEST_ID_OAUTH_RESP = (OAuthResponse) JSON.deserialize(
        '{"organization_id":"00D000000000000","user_id":"005000000000000","username":"test@test.com","display_name":"User User","user_email":"test@test.com"}',
        OAuthResponse.class
    );
    private static final OAuthResponse TEST_OAUTH_RESP_ACCESS_TOKEN = (OAuthResponse) JSON.deserialize(
        '{"access_token":"abc","refresh_token":"123","display_name":"test","email":"test@test.com","instance_url":"https://test-test-123-dev-ed.scratch.my.salesforce.com","id":"00D000000000000/005000000000000","interval":"5","issued_at":"123","organization_id":"00D000000000000","user_id":"005000000000000"}',
        OAuthResponse.class
    );

    public OAuthService() {
        this(DEFAULT_AUTH_METHOD, DEFAULT_DOMAIN);
    }

    public OAuthService(String domain) {
        this(DEFAULT_AUTH_METHOD, domain);
    }

    public OAuthService(
        ToolingApiService.AUTH_METHOD authMethod,
        String domain
    ) {
        String caName;
        switch on authMethod {
            when OAUTH_CREDENTIALS {
                caName = 'PLC_Credentials_Flow';
            }
            when OAUTH_DEVICE {
                caName = 'PLC_Device_Flow';
            }
            when OAUTH_JWT_KEY_PACKAGED {
                caName = 'PLC_JWT_Key_Packaged_Flow';
            }
            when OAUTH_WEB_SERVER {
                caName = 'PLC_Web_Server_Flow';
            }
            when else {
                caName = DEFAULT_CA;
            }
        }
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
            when OAUTH_CREDENTIALS {
                oauthFlow = 'creds';
            }
            when OAUTH_DEVICE {
                oauthFlow = 'device';
            }
            when OAUTH_JWT_KEY_PACKAGED {
                oauthFlow = 'jwt_kp';
            }
            when OAUTH_JWT_ADMIN_KEY {
                oauthFlow = 'jwt_ak';
            }
            when OAUTH_WEB_SERVER {
                oauthFlow = 'web';
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
            when OAUTH_CREDENTIALS {
                oauthFlow = 'creds';
            }
            when OAUTH_DEVICE {
                oauthFlow = 'device';
            }
            when OAUTH_JWT_KEY_PACKAGED {
                oauthFlow = 'jwt_kp';
            }
            when OAUTH_JWT_ADMIN_KEY {
                oauthFlow = 'jwt_ak';
            }
            when OAUTH_WEB_SERVER {
                oauthFlow = 'web';
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

    public OAuthResponse generateAccessTokenFromCredentialsFlow() {
        return generateAccessTokenFromCredentialsFlow(true);
    }

    public OAuthResponse generateAccessTokenFromCredentialsFlow(Boolean saveOauthResponse) {
        String body =
            'grant_type=client_credentials&client_id=' +
            EncodingUtil.urlEncode(this.ca.client_id, 'UTF-8') +
            '&client_secret=' +
            EncodingUtil.urlEncode(this.ca.client_secret, 'UTF-8');
        return Test.isRunningTest()
            ? TEST_OAUTH_RESP_ACCESS_TOKEN
            : makeOAuthRequest(body, saveOAuthResponse);
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

    public OAuthResponse generateAccessTokenFromJWTAdminKeyFlow(
        String certName,
        String consumerKey,
        String username
    ) {
        return generateAccessTokenFromJWTAdminKeyFlow(certName, consumerKey, username, true);
    }

    public OAuthResponse generateAccessTokenFromJWTAdminKeyFlow(
        String certName,
        String consumerKey,
        String username,
        Boolean saveOAuthResponse
    ) {
        Auth.JWT jwt = new Auth.JWT();
        jwt.setIss(consumerKey);
        jwt.setSub(username);
        jwt.setAud(
            this.authEndpoint.contains('.sandbox.') ||
                this.authEndpoint.contains('.scratch.')
                ? 'https://test.salesforce.com'
                : 'https://login.salesforce.com'
        );
        Auth.JWS jws = new Auth.JWS(jwt, certName);
        if (Test.isRunningTest()) {
            return TEST_OAUTH_RESP_ACCESS_TOKEN;
        } else {
            Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(
                this.authEndpoint,
                jws
            );
            HttpResponse res = bearer.getHttpResponse();
            try {
                OAuthResponse oauthResponse = (OAuthResponse) JSON.deserialize(
                    res.getBody(),
                    OAuthResponse.class
                );

                if (res.getStatusCode() == 200 && oauthResponse.id != null && saveOAuthResponse) {
                    saveOAuthResponse(oauthResponse, certName, consumerKey);
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
    }

    public OAuthResponse generateAccessTokenFromJWTPackagedKeyFlow(
        String username
    ) {
        return generateAccessTokenFromJWTPackagedKeyFlow(username, true);
    }

    public OAuthResponse generateAccessTokenFromJWTPackagedKeyFlow(
        String username,
        Boolean saveOAuthResponse
    ) {
        JWTRaw jwt = new JWTRaw('RS256');
        jwt.pkcs8 = this.ca.jwt_private_key.replace('\n', '').replace('\r', '');
        jwt.iss = this.ca.client_id;
        jwt.sub = username;
        jwt.aud = this.authEndpoint.contains('.sandbox.') ||
            this.authEndpoint.contains('.scratch.')
            ? 'https://test.salesforce.com'
            : 'https://login.salesforce.com';
        String body =
            'grant_type=' +
            EncodingUtil.urlEncode(
                'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'UTF-8'
            ) +
            '&assertion=' +
            jwt.issue();
        return Test.isRunningTest()
            ? TEST_OAUTH_RESP_ACCESS_TOKEN
            : makeOAuthRequest(body, saveOAuthResponse);
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

    public static String getAdminProvidedCertificateName(String username) {
        return (getOAuthCreds('jwt_ak', username)).certificate_name;
    }

    public static String getAdminProvidedConsumerKey(String username) {
        return (getOAuthCreds('jwt_ak', username)).consumer_key;
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
        if (!Test.isRunningTest()) {
            Metadata.Operations.enqueueDeployment(
                mdContainer,
                new CustomMetadataCallback()
            );
        }
    }

    private static OAuthCredentials getOAuthCreds(
        String oauthFlow,
        String username
    ) {
        List<OAuthCreds__mdt> storedCreds = OAuthCredsSelector.fetchByUsername(
            oauthFlow,
            username
        );
        if (!Test.isRunningTest() && storedCreds.isEmpty()) {
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

    @TestVisible
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

        if (!Test.isRunningTest()) {
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
        } else {
            if (saveOAuthResponse) {
                saveOAuthResponse(TEST_OAUTH_RESP_ACCESS_TOKEN);
            }
            return TEST_OAUTH_RESP_ACCESS_TOKEN;
        }
    }

    public void saveOAuthResponse(OAuthResponse oauthResponse) {
        saveOAuthResponse(oauthResponse, null, null);
    }

    public void saveOAuthResponse(OAuthResponse oauthResponse, String adminProvidedCertName, String adminProvidedConsumerKey) {
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

        OAuthResponse idOauthResponse;

        if (!Test.isRunningTest()) {
            HTTPResponse idRes = idHttp.send(idReq);

            if (idRes.getStatusCode() != 200) {
                throw new IdentityException(
                    'Identity Failure: ' +
                    idRes.getStatusCode() +
                    ' Body:' +
                    idRes.getBody()
                );
            }

            idOauthResponse = (OAuthResponse) JSON.deserialize(
                idRes.getBody(),
                OAuthResponse.class
            );
        } else {
            idOauthResponse = TEST_ID_OAUTH_RESP;
        }

        OAuthCredentials creds = new OAuthCredentials();
        creds.domain = authEndpoint;
        creds.is_dev_edition = authEndpoint.contains('.develop.');
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
            when OAUTH_CREDENTIALS {
                creds.oauth_flow = 'creds';
            }
            when OAUTH_DEVICE {
                creds.oauth_flow = 'device';
            }
            when OAUTH_JWT_KEY_PACKAGED {
                creds.oauth_flow = 'jwt_kp';
            }
            when OAUTH_JWT_ADMIN_KEY {
                creds.oauth_flow = 'jwt_ak';
                creds.certificate_name = adminProvidedCertName;
                creds.consumer_key = adminProvidedConsumerKey;
            }
            when OAUTH_WEB_SERVER {
                creds.oauth_flow = 'web';
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

    public class ConnectedApp {
        public String client_id { get; private set; }
        public String client_secret { get; private set; }
        public String id { get; private set; }
        public String jwt_private_key { get; private set; }
        public String org_id { get; private set; }
        public String scope;
        public String server_domain { get; private set; }
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
        public Boolean is_dev_edition;
        public Boolean is_sandbox;
        public Boolean is_scratch;
        public String sandbox_name;
        public String access_token;
        public String refresh_token;
        public String certificate_name;
        public String consumer_key;
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
