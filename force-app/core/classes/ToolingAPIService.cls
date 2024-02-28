public with sharing class ToolingAPIService {
    public enum AUTH_METHOD {
        CURRENT_USER_SESSIONID,
        CURRENT_USER_SESSIONID_FROM_VF,
        OAUTH_CREDENTIALS,
        OAUTH_DEVICE,
        OAUTH_JWT_ADMIN_KEY,
        OAUTH_JWT_KEY_PACKAGED,
        OAUTH_WEB_SERVER
    }

    public static final AUTH_METHOD DEFAULT_AUTH_METHOD = AUTH_METHOD.CURRENT_USER_SESSIONID_FROM_VF;
    public static final OAuthService.OAUTH_CREDS_UPSERT_METHOD DEFAULT_OAUTH_CREDS_UPSERT_METHOD = OAuthService.DEFAULT_OAUTH_CREDS_UPSERT_METHOD;
    public static final String DEFAULT_VERSION = '59.0';

    private static final String DEFAULT_DOMAIN = URL.getOrgDomainUrl()
        .toExternalForm();
    private static final String DEFAULT_USERNAME = UserInfo.getUserName();

    private final AUTH_METHOD authMethod;
    private final OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertMethod;
    private final Boolean refreshTokenExistsForGivenOAuthFlow;
    private final String oauthFlow;
    private final String url;
    private final String username;

    public ToolingAPIService() {
        this(
            DEFAULT_AUTH_METHOD,
            DEFAULT_OAUTH_CREDS_UPSERT_METHOD,
            DEFAULT_DOMAIN,
            DEFAULT_USERNAME,
            DEFAULT_VERSION
        );
    }

    public ToolingAPIService(AUTH_METHOD authMethod) {
        this(
            authMethod,
            DEFAULT_OAUTH_CREDS_UPSERT_METHOD,
            DEFAULT_DOMAIN,
            DEFAULT_USERNAME,
            DEFAULT_VERSION
        );
    }

    public ToolingAPIService(
        AUTH_METHOD authMethod,
        OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertMethod,
        String domain,
        String username,
        String version
    ) {
        this.authMethod = authMethod;
        switch on authMethod {
            when OAUTH_CREDENTIALS {
                this.oauthFlow = 'creds';
                this.refreshTokenExistsForGivenOAuthFlow = false;
            }
            when OAUTH_DEVICE {
                this.oauthFlow = 'device';
                this.refreshTokenExistsForGivenOAuthFlow = true;
            }
            when OAUTH_JWT_KEY_PACKAGED {
                this.oauthFlow = 'jwt_kp';
                this.refreshTokenExistsForGivenOAuthFlow = false;
            }
            when OAUTH_JWT_ADMIN_KEY {
                this.oauthFlow = 'jwt_ak';
                this.refreshTokenExistsForGivenOAuthFlow = false;
            }
            when OAUTH_WEB_SERVER {
                this.oauthFlow = 'web';
                this.refreshTokenExistsForGivenOAuthFlow = true;
            }
            when else {
                this.oauthFlow = 'unknown';
                this.refreshTokenExistsForGivenOAuthFlow = false;
            }
        }
        this.credsUpsertMethod = credsUpsertMethod;
        this.url = domain + '/services/data/v' + version + '/tooling/';
        this.username = username;
    }

    public String makeCallout(
        String path,
        String contentType,
        String method,
        Boolean saveOAuthResponse
    ) {
        String accessToken;
        switch on this.authMethod {
            when CURRENT_USER_SESSIONID {
                accessToken = UserInfo.getSessionId();
            }
            when CURRENT_USER_SESSIONID_FROM_VF {
                Map<String, Object> sessionIdInfo = (Map<String, Object>) JSON.deserializeUntyped(
                    Page.SessionId.getContent().toString()
                );
                accessToken = (String) sessionIdInfo.get('sessionId');
            }
            when else {
                accessToken = OAuthService.getToken(
                    this.oauthFlow,
                    this.username,
                    this.credsUpsertMethod
                );
            }
        }
        return makeCallout(
            this.url + path,
            contentType,
            method,
            accessToken.replace('\n', ''),
            0,
            saveOAuthResponse
        );
    }

    private String makeCallout(
        String endpoint,
        String contentType,
        String method,
        String accessToken,
        Integer numAttempts,
        Boolean saveOAuthResponse
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', contentType);
        req.setMethod(method);
        req.setTimeout(120000);
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 401 && numAttempts == 0) {
                List<AuthErrorResponse> errorResp = (List<AuthErrorResponse>) JSON.deserialize(
                    res.getBody(),
                    List<AuthErrorResponse>.class
                );
                if (errorResp[0].errorCode == 'INVALID_SESSION_ID') {
                    // Refresh access token and try again
                    OAuthService oauth = new OAuthService(
                        this.authMethod,
                        this.credsUpsertMethod,
                        this.url.substringBefore('/services')
                    );
                    OAuthService.OAuthResponse resp;
                    String refreshToken;
                    if (this.refreshTokenExistsForGivenOAuthFlow) {
                        refreshToken = OAuthService.getRefreshToken(
                            this.oauthFlow,
                            this.username
                        );
                        if (refreshToken == null) {
                            throw new AuraHandledException(
                                'No refresh token found for selected user; please reauthorize from app settings and then try again.'
                            );
                        }
                        resp = oauth.generateAccessTokenFromRefreshFlow(
                            refreshToken
                        );
                    } else {
                        if (this.oauthFlow == 'creds') {
                            resp = oauth.generateAccessTokenFromCredentialsFlow(
                                false
                            );
                        } else if (this.oauthFlow == 'jwt_kp') {
                            resp = oauth.generateAccessTokenFromJWTPackagedKeyFlow(
                                this.username,
                                false
                            );
                        } else if (this.oauthFlow == 'jwt_ak') {
                            resp = oauth.generateAccessTokenFromJWTAdminKeyFlow(
                                OAuthService.getAdminProvidedCertificateName(
                                    this.username
                                ),
                                OAuthService.getAdminProvidedConsumerKey(
                                    this.username
                                ),
                                this.username,
                                false
                            );
                        } else {
                            throw new AuraHandledException(
                                'Error: Session Id is invalid or not API-enabled!'
                            );
                        }
                    }
                    if (resp.access_token != null) {
                        String calloutResp = makeCallout(
                            endpoint,
                            contentType,
                            method,
                            resp.access_token,
                            1,
                            false
                        );
                        if (refreshToken != null) {
                            resp.refresh_token = refreshToken;
                        }
                        // Saving the OAuth Response counts as a DML statement
                        // All DML must be done after the last callout completes
                        // This prevents the 'uncommitted work pending' error
                        if (saveOAuthResponse) {
                            if (this.oauthFlow == 'jwt_ak') {
                                oauth.saveOAuthResponse(
                                    resp,
                                    OAuthService.getAdminProvidedCertificateName(
                                        this.username
                                    ),
                                    OAuthService.getAdminProvidedConsumerKey(
                                        this.username
                                    )
                                );
                            } else {
                                oauth.saveOAuthResponse(resp);
                            }
                        }
                        return calloutResp;
                    } else if (
                        resp.error == 'invalid_grant' &&
                        resp.error_description == 'expired access/refresh token'
                    ) {
                        throw new AuraHandledException(
                            'Invalid/Expired refresh token for selected user; please reauthorize from app settings and then try again.'
                        );
                    }
                    throw new AuraHandledException(
                        'Error: ' +
                        resp.error +
                        ' Description: ' +
                        resp.error_description
                    );
                }
            } else if (res.getStatusCode() != 200 && numAttempts > 0) {
                throw new AuraHandledException(
                    'Something whent wrong-please try again later!'
                );
            }
            return res.getBody();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            if (
                e.getMessage()
                    .contains('You might not have the required permissions')
            ) {
                throw new AuraHandledException(
                    'Your user does not have the required permissions to perform this action. Please ask your admin to assign the proper permission set to provide access to the Salesforce Tooling API.'
                );
            } else if (
                e.getMessage()
                    .contains(
                        'OAuth Failure: User has not yet been authorized. Please authorize the user from app settings and then try again'
                    )
            ) {
                throw new AuraHandledException(
                    'User has not yet been authorized or is missing a valid refresh token. Please (re)authorize the user from app settings and then try again.'
                );
            } else {
                throw new System.CalloutException(
                    'Error while making callout: ' +
                    e.getMessage() +
                    ' ... Stack trace: ' +
                    e.getStackTraceString()
                );
            }
        }
    }

    class AuthErrorResponse {
        public String errorCode { get; private set; }
        public String message { get; private set; }
    }
}