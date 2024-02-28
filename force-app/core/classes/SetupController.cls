public with sharing class SetupController {
    @AuraEnabled
    public static List<AuthorizedUser> fetchAuthorizedUsers(
        String credsUpsertMethod,
        String oauthFlow
    ) {
        List<AuthorizedUser> authUsers = new List<AuthorizedUser>();
        OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertChannel;
        switch on credsUpsertMethod {
            when 'cmdt' {
                credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT;
            }
            when 'cs' {
                credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS;
            }
        }
        if (credsUpsertChannel == OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT) {
            List<OAuthCreds__mdt> allCreds = OAuthCredsSelector.fetchAllCMDTs();
            for (OAuthCreds__mdt credsCMDT : allCreds) {
                OAuthService.OAuthCredentials creds = (OAuthService.OAuthCredentials) JSON.deserialize(
                    Test.isRunningTest()
                        ? OAuthCredsSelector.TEST_OAUTH_CREDS_VALUE
                        : credsCMDT.Value__c,
                    OAuthService.OAuthCredentials.class
                );
                if (creds.oauth_flow == oauthFlow) {
                    if (
                        creds.oauth_flow == 'jwt' ||
                        creds.access_token != null
                    ) {
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
        } else if (
            credsUpsertChannel ==
            OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS
        ) {
            List<OAuthCredentials__c> allCreds = OAuthCredsSelector.fetchAllCustomSettings();
            for (OAuthCredentials__c creds : allCreds) {
                String credsOauthFlow = creds.Name.substringBefore(
                    OAuthCredsSelector.sanitize('_' + creds.user_username__c)
                );
                if (credsOauthFlow == oauthFlow) {
                    if (
                        credsOauthFlow == 'jwt' ||
                        creds.access_token__c != null
                    ) {
                        authUsers.add(
                            new AuthorizedUser(
                                creds.instance_url__c,
                                creds.user_username__c,
                                creds.user_display_name__c
                            )
                        );
                    }
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
    public static Map<String, String> fetchDeviceFlowAuthCodes(
        String credsUpsertMethod,
        String domain
    ) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertChannel;
            switch on credsUpsertMethod {
                when 'cmdt' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT;
                }
                when 'cs' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS;
                }
            }
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_DEVICE,
                credsUpsertChannel,
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
        String credsUpsertMethod,
        String oauthFlow,
        List<String> usernamesToRevoke
    ) {
        try {
            OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertChannel;
            switch on credsUpsertMethod {
                when 'cmdt' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT;
                }
                when 'cs' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS;
                }
            }
            List<OAuthService.OAuthCredentials> credsToRevoke = new List<OAuthService.OAuthCredentials>();

            if (
                credsUpsertChannel ==
                OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT
            ) {
                // CMDTs cannot be deleted via the `Metadata` Apex class
                // Clearing the access & refresh tokens will serve to revoke access
                List<OAuthCreds__mdt> allOAuthCredCMDTsToRevoke = OAuthCredsSelector.fetchCMDTsByUsernames(
                    oauthFlow,
                    userNamesToRevoke
                );

                for (
                    OAuthCreds__mdt oauthCredCMDT : allOAuthCredCMDTsToRevoke
                ) {
                    OAuthService.OAuthCredentials creds = (OAuthService.OAuthCredentials) JSON.deserialize(
                        Test.isRunningTest()
                            ? OAuthCredsSelector.TEST_OAUTH_CREDS_VALUE
                            : oauthCredCMDT.Value__c,
                        OAuthService.OAuthCredentials.class
                    );
                    creds.access_token = null;
                    creds.refresh_token = null;
                    credsToRevoke.add(creds);
                }

                if (!Test.isRunningTest()) {
                    OAuthService oauth = new OAuthService(
                        OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT
                    );
                    oauth.upsertOAuthCreds(credsToRevoke);
                }
            }

            if (
                credsUpsertChannel ==
                OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS
            ) {
                List<OAuthCredentials__c> customSettingsToDelete = OAuthCredsSelector.fetchCustomSettingsByUsernames(
                    oauthFlow,
                    usernamesToRevoke
                );
                delete customSettingsToDelete;
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
        String credsUpsertMethod,
        String domain
    ) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertChannel;
            switch on credsUpsertMethod {
                when 'cmdt' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT;
                }
                when 'cs' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS;
                }
            }
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_CREDENTIALS,
                credsUpsertChannel,
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
            String credsUpsertMethod = params.get('credsUpsertMethod');
            OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertChannel;
            switch on credsUpsertMethod {
                when 'cmdt' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT;
                }
                when 'cs' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS;
                }
            }
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
                    credsUpsertChannel,
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
                    credsUpsertChannel,
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
        String credsUpsertMethod,
        String domain,
        String deviceCode
    ) {
        try {
            String authEndpoint = 'https://' + domain + '.my.salesforce.com';
            OAuthService.OAUTH_CREDS_UPSERT_METHOD credsUpsertChannel;
            switch on credsUpsertMethod {
                when 'cmdt' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CMDT;
                }
                when 'cs' {
                    credsUpsertChannel = OAuthService.OAUTH_CREDS_UPSERT_METHOD.CUSTOM_SETTINGS;
                }
            }
            OAuthService oauth = new OAuthService(
                ToolingApiService.AUTH_METHOD.OAUTH_DEVICE,
                credsUpsertChannel,
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