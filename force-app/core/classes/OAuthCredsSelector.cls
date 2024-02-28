public with sharing class OAuthCredsSelector {
    public static final String TEST_OAUTH_CREDS_VALUE = '{"domain":"test","is_sandbox":false,"is_scratch":true,"access_token":"test","refresh_token":"test","scope":"test","instance_url":"test","id":"test"}';

    private static final List<OAuthCreds__mdt> TEST_OAUTH_CMDT_CREDS = (List<OAuthCreds__mdt>) JSON.deserialize(
        '[{"DeveloperName":"test@test.com","Label":"test@test.com","MasterLabel":"test@test.com","QualifiedApiName":"Test","SystemModStamp":"1702672841"}]',
        List<OAuthCreds__mdt>.class
    );

    private static final List<OAuthCredentials__c> TEST_OAUTH_CS_CREDS = (List<OAuthCredentials__c>) JSON.deserialize(
        '[{"Name":"test@test.com"}]',
        List<OAuthCredentials__c>.class
    );

    public static List<OAuthCreds__mdt> fetchAllCMDTs() {
        if (Test.isRunningTest())
            return TEST_OAUTH_CMDT_CREDS;
        return [
            SELECT
                DeveloperName,
                Label,
                MasterLabel,
                NamespacePrefix,
                QualifiedApiName,
                SystemModStamp,
                Value__c
            FROM OAuthCreds__mdt
        ];
    }

    public static List<OAuthCredentials__c> fetchAllCustomSettings() {
        return Test.isRunningTest()
            ? TEST_OAUTH_CS_CREDS
            : OAuthCredentials__c.getAll().values();
    }

    public static List<OAuthCredentials__c> fetchCustomSettingsByUsername(
        String oauthFlow,
        String username
    ) {
        String sanitizedUsername = sanitize(oauthFlow + '_' + username);
        return Test.isRunningTest()
            ? TEST_OAUTH_CS_CREDS
            : new List<OAuthCredentials__c>{
                  OAuthCredentials__c.getInstance(sanitizedUsername)
              };
    }

    public static List<OAuthCredentials__c> fetchCustomSettingsByUsernames(
        String oauthFlow,
        List<String> usernames
    ) {
        Set<String> sanitizedUsernames = new Set<String>();
        for (String un : usernames) {
            sanitizedUsernames.add(sanitize(oauthFlow + '_' + un));
        }
        List<OAuthCredentials__c> allCreds = fetchAllCustomSettings();
        List<OAuthCredentials__c> creds = new List<OAuthCredentials__c>();
        for (OAuthCredentials__c cred : allCreds) {
            if (sanitizedUsernames.contains(cred.Name)) {
                creds.add(cred);
            }
        }
        return Test.isRunningTest() ? TEST_OAUTH_CS_CREDS : creds;
    }

    public static List<OAuthCreds__mdt> fetchCMDTByUsername(
        String oauthFlow,
        String username
    ) {
        return fetchCMDTsByUsernames(oauthFlow, new List<String>{ username });
    }

    public static List<OAuthCreds__mdt> fetchCMDTsByUsernames(
        String oauthFlow,
        List<String> usernames
    ) {
        List<String> sanitizedUsernames = new List<String>();
        for (String un : usernames) {
            sanitizedUsernames.add(sanitize(oauthFlow + '_' + un));
        }
        if (Test.isRunningTest()) {
            return TEST_OAUTH_CMDT_CREDS;
        }
        return [
            SELECT
                DeveloperName,
                Label,
                MasterLabel,
                NamespacePrefix,
                QualifiedApiName,
                SystemModStamp,
                Value__c
            FROM OAuthCreds__mdt
            WHERE DeveloperName IN :sanitizedUsernames
        ];
    }

    public static String sanitize(String input) {
        // Record names cannot contain + / = - @ or . characters
        // This method replaces them with alphanumeric characters
        if (input == null)
            return input;
        return input
            .replace('+', 'A')
            .replace('/', 'B')
            .replace('=', 'C')
            .replace('-', 'D')
            .replace('@', 'E')
            .replace('.', 'F');
    }
}