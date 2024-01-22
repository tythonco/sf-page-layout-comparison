public with sharing class ToolingAPIService {
    public enum AUTH_METHOD {
        CURRENT_USER_SESSIONID,
        CURRENT_USER_SESSIONID_FROM_VF,
        OAUTH
    }

    private static final AUTH_METHOD DEFAULT_AUTH_METHOD = AUTH_METHOD.OAUTH;
    private static final String DEFAULT_DOMAIN = URL.getOrgDomainUrl()
        .toExternalForm();
    private static final String DEFAULT_USERNAME = UserInfo.getUserName();
    private static final String DEFAULT_VERSION = '59.0';

    private final AUTH_METHOD authMethod;
    private final String url;
    private final String username;

    public ToolingAPIService() {
        this(
            DEFAULT_AUTH_METHOD,
            DEFAULT_DOMAIN,
            DEFAULT_USERNAME,
            DEFAULT_VERSION
        );
    }

    public ToolingAPIService(AUTH_METHOD authMethod) {
        this(authMethod, DEFAULT_DOMAIN, DEFAULT_USERNAME, DEFAULT_VERSION);
    }

    public ToolingAPIService(
        AUTH_METHOD authMethod,
        String domain,
        String username,
        String version
    ) {
        this.authMethod = authMethod;
        this.url = domain + '/services/data/v' + version + '/tooling/';
        this.username = username;
    }

    public String makeCallout(String path, String contentType, String method) {
        String accessToken;
        if (this.authMethod == AUTH_METHOD.OAUTH) {
            accessToken = OAuthService.getToken(this.username);
        } else if (this.authMethod == AUTH_METHOD.CURRENT_USER_SESSIONID) {
            accessToken = UserInfo.getSessionId();
        } else if (
            this.authMethod == AUTH_METHOD.CURRENT_USER_SESSIONID_FROM_VF
        ) {
            Map<String, Object> sessionIdInfo = (Map<String, Object>) JSON.deserializeUntyped(
                Page.SessionId.getContent().toString()
            );
            accessToken = (String) sessionIdInfo.get('sessionId');
        }
        return makeCallout(
            this.url + path,
            contentType,
            method,
            accessToken.replace('\n', ''),
            0
        );
    }

    private String makeCallout(
        String endpoint,
        String contentType,
        String method,
        String accessToken,
        Integer numAttempts
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
                    String refreshToken = OAuthService.getRefreshToken(
                        this.username
                    );
                    OAuthService oauth = new OAuthService(
                        this.url.substringBefore('/services')
                    );
                    OAuthService.OAuthResponse resp = oauth.generateAccessTokenFromRefreshFlow(
                        refreshToken
                    );
                    if (resp.access_token != null) {
                        String calloutResp = makeCallout(
                            endpoint,
                            contentType,
                            method,
                            resp.access_token,
                            1
                        );
                        // Saving the OAuth Response counts as a DML statement
                        // All DML must be done after the last callout completes
                        // This prevents the 'uncommitted work pending' error
                        resp.refresh_token = refreshToken;
                        oauth.saveOAuthResponse(resp);
                        return calloutResp;
                    } else if (
                        resp.error == 'invalid_grant' &&
                        resp.error_description == 'expired access/refresh token'
                    ) {
                        throw new AuraHandledException(
                            'Invalid/Expired refresh token for selected user; please reauthenticate from app settings and then try again.'
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