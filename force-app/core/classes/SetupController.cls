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
                authUsers.add(
                    new AuthenticatedUser(
                        creds.domain,
                        creds.user_username,
                        creds.user_display_name
                    )
                );
            }
        }
        return authUsers;
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