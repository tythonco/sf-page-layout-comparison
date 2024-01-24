public with sharing class SetupController {
    @AuraEnabled
    public static List<AuthenticatedUser> fetchAuthenticatedUsers(
        String oauthFlow
    ) {
        List<AuthenticatedUser> authUsers = new List<AuthenticatedUser>();
        List<OAuthCreds__mdt> allCreds = OAuthCredsSelector.fetchAll();
        for (OAuthCreds__mdt credsCMDT : allCreds) {
            OAuthService.OAuthCredentials creds = (OAuthService.OAuthCredentials) JSON.deserialize(
                credsCMDT.Value__c,
                OAuthService.OAuthCredentials.class
            );
            if (creds.oauth_flow == oauthFlow) {
                if (creds.oauth_flow == 'jwt' || creds.access_token != null) {
                    authUsers.add(
                        new AuthenticatedUser(
                            creds.domain,
                            creds.user_username,
                            creds.user_display_name
                        )
                    );
                }
            }
        }
        return authUsers;
    }

    @AuraEnabled
    public static Map<String, Map<String, String>> fetchConnectedAppInfo() {
        Map<String, Map<String, String>> caInfoByName = new Map<String, Map<String, String>>();
        List<ConnectedApp__mdt> caCMDTs = ConnectedAppSelector.fetchAll();
        for (ConnectedApp__mdt caCMDT : caCMDTs) {
            OAuthService.ConnectedApp ca = (OAuthService.ConnectedApp) JSON.deserialize(
                caCMDT.Value__c,
                OAuthService.ConnectedApp.class
            );
            caInfoByName.put(
                ca.name,
                new Map<String, String>{
                    'client_id' => ca.client_id,
                    'flow' => ca.flow,
                    'id' => ca.id,
                    'name' => ca.name,
                    'org_id' => ca.org_id,
                    'scope' => ca.scope
                }
            );
        }
        return caInfoByName;
    }

    @AuraEnabled
    public static Map<String, String> fetchDeviceFlowAuthCodes(String domain) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_DEVICE,
                authEndpoint
            );
            return oauth.generateCodesFromDeviceFlow();
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error Fetching Auth Codes!' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String fetchOrgDomain() {
        try {
            return URL.getOrgDomainURL().toExternalForm();
        } catch (Exception e) {
            throw new AuraHandledException('Error Fetching Org Domain!');
        }
    }

    @AuraEnabled
    public static String fetchCurrentUsername() {
        try {
            return UserInfo.getUserName();
        } catch (Exception e) {
            throw new AuraHandledException('Error Fetching Current Username!');
        }
    }

    @AuraEnabled
    public static void revokeOAuthEnabledUserAccess(
        String oauthFlow,
        List<String> usernamesToRevoke
    ) {
        try {
            List<OAuthService.OAuthCredentials> credsToRevoke = new List<OAuthService.OAuthCredentials>();
            List<OAuthCreds__mdt> allOAuthCredCMDTsToRevoke = OAuthCredsSelector.fetchByUsernames(
                oauthFlow,
                userNamesToRevoke
            );
            for (OAuthCreds__mdt oauthCredCMDT : allOAuthCredCMDTsToRevoke) {
                OAuthService.OAuthCredentials creds = (OAuthService.OAuthCredentials) JSON.deserialize(
                    Test.isRunningTest()
                        ? OAuthCredsSelector.TEST_OAUTH_CREDS_VALUE
                        : oauthCredCMDT.Value__c,
                    OAuthService.OAuthCredentials.class
                );
                // Currently CMDTs cannot be deleted via Apex, but clearing the access & refresh tokens will serve to revoke access
                creds.access_token = null;
                creds.refresh_token = null;
                credsToRevoke.add(creds);
            }
            OAuthService oauth = new OAuthService();
            if (!Test.isRunningTest()) {
                oauth.upsertOAuthCredsCMDT(credsToRevoke);
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error Revoking Access for OAuth Enabled User(s)! ' +
                e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static Map<String, Object> testCredentialsFlowOrgDomainConnection(
        String domain
    ) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_CREDENTIALS,
                authEndpoint
            );
            OAuthService.OAuthResponse resp = oauth.generateAccessTokenFromCredentialsFlow();
            if (resp.access_token != null) {
                return new Map<String, Object>{
                    'status' => 'authenticated',
                    'is_authenticated' => true
                };
            } else if (resp.error != null && resp.error_description != null) {
                return new Map<String, Object>{
                    'status' => resp.error,
                    'error' => resp.error,
                    'error_description' => resp.error_description,
                    'is_authenticated' => false
                };
            } else {
                throw new AuraHandledException(
                    'Error validating authorization to org domain via Credentials flow!'
                );
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error validating authorization to org domain via Credentials flow!'
            );
        }
    }

    @AuraEnabled
    public static Map<String, Object> testJWTFlowOrgDomainConnection(
        String domain,
        String username
    ) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_JWT_KEY_PACKAGED,
                authEndpoint
            );
            OAuthService.OAuthResponse resp = oauth.generateAccessTokenFromJWTPackagedKeyFlow(
                username
            );
            if (resp.access_token != null) {
                return new Map<String, Object>{
                    'status' => 'authenticated',
                    'is_authenticated' => true
                };
            } else if (resp.error != null && resp.error_description != null) {
                return new Map<String, Object>{
                    'status' => resp.error,
                    'error' => resp.error,
                    'error_description' => resp.error_description,
                    'is_authenticated' => false
                };
            } else {
                throw new AuraHandledException(
                    'Error validating authorization to org domain via Credentials flow!'
                );
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error validating authorization to org domain via Credentials flow!'
            );
        }
    }

    @AuraEnabled
    public static Map<String, Object> validatePendingDeviceFlowAuthentication(
        String domain,
        String deviceCode
    ) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_DEVICE,
                authEndpoint
            );
            OAuthService.OAuthResponse resp = oauth.generateAccessTokenFromDeviceFlow(
                deviceCode
            );
            if (resp.access_token != null) {
                return new Map<String, Object>{
                    'status' => 'authenticated',
                    'is_authenticated' => true
                };
            } else if (resp.error != null && resp.error_description != null) {
                return new Map<String, Object>{
                    'status' => resp.error,
                    'error' => resp.error,
                    'error_description' => resp.error_description,
                    'is_authenticated' => false
                };
            } else {
                throw new AuraHandledException(
                    'Error validating pending authentication!'
                );
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error validating pending authentication!'
            );
        }
    }

    public with sharing class AuthenticatedUser {
        @AuraEnabled
        public String domain;
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String usernameForDisplay;

        public AuthenticatedUser(
            String domain,
            String username,
            String usernameForDisplay
        ) {
            this.domain = domain;
            this.username = username;
            this.usernameForDisplay = usernameForDisplay;
        }
    }
}