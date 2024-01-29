List<String> includedFields = SetupController.fetchPageLayoutIncludedFields(
    'session_id',
    URL.getOrgDomainUrl().toExternalForm(),
    UserInfo.getUserName(),
    'Account',
    'Account Layout'
);
System.debug(includedFields);
