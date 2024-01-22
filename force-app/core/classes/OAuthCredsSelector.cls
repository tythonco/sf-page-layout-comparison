public with sharing class OAuthCredsSelector {
    public static final String TEST_OAUTH_CREDS_VALUE = '{"domain":"test","is_sandbox":false,"is_scratch":true,"access_token":"test","refresh_token":"test","scope":"test","instance_url":"test","id":"test"}';

    private static final List<OAuthCreds__mdt> TEST_OAUTH_CREDS = (List<OAuthCreds__mdt>) JSON.deserialize(
        '[{"DeveloperName":"test@test.com","Label":"test@test.com","MasterLabel":"test@test.com","QualifiedApiName":"Test","SystemModStamp":"1702672841"}]',
        List<OAuthCreds__mdt>.class
    );

    public static List<OAuthCreds__mdt> fetchByUsername(String username) {
        return fetchByUsernames(new List<String>{ username });
    }

    public static List<OAuthCreds__mdt> fetchByUsernames(
        List<String> usernames
    ) {
        List<String> sanitizedUsernames = new List<String>();
        for (String un : usernames) {
            sanitizedUsernames.add(sanitize(un));
        }
        if (Test.isRunningTest()) {
            return TEST_OAUTH_CREDS;
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
        // CMDT record names cannot contain + / = - @ or . characters
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