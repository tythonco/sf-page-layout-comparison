@isTest
public with sharing class SetupControllerTest {
    @isTest
    static void testFetchAuthorizedUsers() {
        List<SetupController.AuthorizedUser> authorizedUsers = SetupController.fetchAuthorizedUsers(null);
    }

    @isTest
    static void testFetchConnectedAppInfo() {
        Map<String, Map<String, String>> caInfoByName = SetupController.fetchConnectedAppInfo();
    }

    @isTest
    static void testFetchDeviceFlowAuthCodes() {
        Map<String, String> deviceCodesByName = SetupController.fetchDeviceFlowAuthCodes('api', URL.getOrgDomainUrl().toExternalForm());
    }

    @isTest
    static void testFetchOrgDomain() {
        String orgDomain = SetupController.fetchOrgDomain();
    }

    @isTest
    static void testFetchCurrentUsername() {
        String currentUsername = SetupController.fetchCurrentUsername();
    }

    @isTest
    static void testRevokeOAuthEnabledUserAccess() {
        SetupController.revokeOAuthEnabledUserAccess('apex', 'test', new List<String>{'test'});
    }

    @isTest
    static void testTestCredentialsFlowOrgDomainConnection() {
        SetupController.testCredentialsFlowOrgDomainConnection('api', URL.getOrgDomainUrl().toExternalForm());
    }

    @isTest
    static void testJWTFlorOrgDomainConnection() {
        SetupController.testJWTFlowOrgDomainConnection(new Map<String,String>{
            'domain' => URL.getOrgDomainURL().toExternalForm(),
            'flow' => 'jwt_kp',
            'username' => UserInfo.getUserName()
        });
    }

    @isTest
    static void testValidatePendingDeviceFlowAuthorization() {
        SetupController.validatePendingDeviceFlowAuthorization('apex', URL.getOrgDomainUrl().toExternalForm(), '12345');
    }

}
