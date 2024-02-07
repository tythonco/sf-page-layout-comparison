public with sharing class SetupController {
    @AuraEnabled
    public static List<AuthorizedUser> fetchAuthorizedUsers(String oauthFlow) {
        List<AuthorizedUser> authUsers = new List<AuthorizedUser>();
        List<OAuthCreds__mdt> allCreds = OAuthCredsSelector.fetchAll();
        for (OAuthCreds__mdt credsCMDT : allCreds) {
            OAuthService.OAuthCredentials creds = (OAuthService.OAuthCredentials) JSON.deserialize(
                Test.isRunningTest() ? OAuthCredsSelector.TEST_OAUTH_CREDS_VALUE : credsCMDT.Value__c,
                OAuthService.OAuthCredentials.class
            );
            if (creds.oauth_flow == oauthFlow) {
                if (creds.oauth_flow == 'jwt' || creds.access_token != null) {
                    authUsers.add(
                        new AuthorizedUser(
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
                    'scope' => ca.scope,
                    'server_domain' => ca.server_domain
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
    public static List<String> fetchPageLayoutIncludedFields(
        String authMethod,
        String domain,
        String username,
        String objectName,
        String pageLayoutName
    ) {
        try {
            domain = domain != null
                ? domain
                : URL.getOrgDomainUrl().toExternalForm();
            List<String> includedFields = new List<String>();
            ToolingAPIService.AUTH_METHOD apiAuthMethod;
            switch on authMethod {
                when 'session_id' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.CURRENT_USER_SESSIONID;
                }
                when 'session_id_from_vf' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.CURRENT_USER_SESSIONID_FROM_VF;
                }
                when 'creds' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_CREDENTIALS;
                }
                when 'device' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_DEVICE;
                }
                when 'jwt_ak' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_JWT_ADMIN_KEY;
                }
                when 'jwt_kp' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_JWT_KEY_PACKAGED;
                }
                when 'web' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_WEB_SERVER;
                }
                when else {
                    apiAuthMethod = ToolingAPIService.DEFAULT_AUTH_METHOD;
                }
            }
            String layoutsForObjectJson = LayoutService.getLayoutsForObject(
                apiAuthMethod,
                domain,
                username,
                objectName
            );
            Map<String, Object> layoutsForObjectInfo = (Map<String, Object>) JSON.deserializeUntyped(
                layoutsForObjectJson
            );
            List<Object> layoutsForObject = (List<Object>) layoutsForObjectInfo.get(
                'records'
            );
            Id matchingLayoutId;
            for (Object lObject : layoutsForObject) {
                Map<String, Object> l = (Map<String, Object>) lObject;
                String name = (String) l.get('Name');
                if (name == pageLayoutName) {
                    matchingLayoutId = (Id) l.get('Id');
                }
            }
            if (matchingLayoutId != null) {
                LayoutDetail layout = LayoutService.getLayoutDetailInfo(
                    apiAuthMethod,
                    domain,
                    username,
                    matchingLayoutId
                );
                includedFields = layout.includedFields;
            }
            return includedFields;
        } catch (AuraHandledException ahe) {
            throw new AuraHandledException(ahe.getMessage());
        } catch (System.Exception e) {
            throw new AuraHandledException(
                e.getMessage() + e.getStackTraceString()
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
                    'status' => 'authorized',
                    'is_authorized' => true
                };
            } else if (resp.error != null && resp.error_description != null) {
                return new Map<String, Object>{
                    'status' => resp.error,
                    'error' => resp.error,
                    'error_description' => resp.error_description,
                    'is_authorized' => false
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
        Map<String, String> params
    ) {
        try {
            String domain = params.get('domain');
            String flow = params.get('flow');
            String username = params.get('username');
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService oauth;
            OAuthService.OAuthResponse resp;
            if (flow == 'jwt_kp') {
                // Packaged Key
                oauth = new OAuthService(
                    ToolingApiService.AUTH_METHOD.OAUTH_JWT_KEY_PACKAGED,
                    authEndpoint
                );
                resp = oauth.generateAccessTokenFromJWTPackagedKeyFlow(
                    username
                );
            } else if (flow == 'jwt_ak') {
                // Admin Key
                String certName = params.get('certName');
                String consumerKey = params.get('consumerKey');
                oauth = new OAuthService(
                    ToolingApiService.AUTH_METHOD.OAUTH_JWT_ADMIN_KEY,
                    authEndpoint
                );
                resp = oauth.generateAccessTokenFromJWTAdminKeyFlow(
                    certName,
                    consumerKey,
                    username
                );
            }
            if (resp.access_token != null) {
                return new Map<String, Object>{
                    'status' => 'authorized',
                    'is_authorized' => true
                };
            } else if (resp.error != null && resp.error_description != null) {
                return new Map<String, Object>{
                    'status' => resp.error,
                    'error' => resp.error,
                    'error_description' => resp.error_description,
                    'is_authorized' => false
                };
            } else {
                throw new AuraHandledException(
                    'Error validating authorization to org domain via JWT flow!'
                );
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error validating authorization to org domain via JWT flow!'
            );
        }
    }

    @AuraEnabled
    public static Map<String, Object> validatePendingDeviceFlowAuthorization(
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
                    'status' => 'authorized',
                    'is_authorized' => true
                };
            } else if (resp.error != null && resp.error_description != null) {
                return new Map<String, Object>{
                    'status' => resp.error,
                    'error' => resp.error,
                    'error_description' => resp.error_description,
                    'is_authorized' => false
                };
            } else {
                throw new AuraHandledException(
                    'Error validating pending authorization!'
                );
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error validating pending authorization!'
            );
        }
    }

    public with sharing class AuthorizedUser {
        @AuraEnabled
        public String domain;
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String usernameForDisplay;

        public AuthorizedUser(
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
