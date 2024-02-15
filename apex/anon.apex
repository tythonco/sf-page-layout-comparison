List<String> includedFields = ComparisonController.fetchPageLayoutIncludedFields(
    'session_id',
    null,
    URL.getOrgDomainUrl().toExternalForm(),
    UserInfo.getUserName(),
    'Account',
    'Account Layout'
);
System.debug(includedFields);
