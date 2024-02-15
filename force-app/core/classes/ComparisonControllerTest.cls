@isTest
public with sharing class ComparisonControllerTest {
    @isTest
    static void testFetchPageLayoutIncludedFields() {
        ComparisonController.fetchPageLayoutIncludedFields('session_id', 'api', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('session_id_from_vf', 'api', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('creds', 'api', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('device', 'apex', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('jwt_ak', 'apex', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('jwt_kp', 'apex', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('web', 'apex', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
        ComparisonController.fetchPageLayoutIncludedFields('test', 'api', URL.getOrgDomainUrl().toExternalForm(), UserInfo.getUserName(), 'Account', 'Account Layout');
    }
}
