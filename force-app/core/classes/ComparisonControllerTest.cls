@isTest
public with sharing class ComparisonControllerTest {
    @isTest
    static void testFetchPageLayoutIncludedFields() {
        ComparisonController.fetchPageLayoutIncludedFields(
            'session_id',
            'api',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'session_id_from_vf',
            'api',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'creds',
            'api',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'device',
            'cmdt',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'jwt_ak',
            'cmdt',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'jwt_kp',
            'cmdt',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'web',
            'cmdt',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
        ComparisonController.fetchPageLayoutIncludedFields(
            'test',
            'cs',
            URL.getOrgDomainUrl().toExternalForm(),
            UserInfo.getUserName(),
            'Account',
            'Account Layout'
        );
    }
}