public with sharing class LayoutService {
    private static final ToolingAPIService.AUTH_METHOD authMethod = ToolingAPIService.AUTH_METHOD.OAUTH;

    @AuraEnabled
    public static String getLayoutsForObject(String objectName) {
        ToolingAPIService api = new ToolingAPIService(authMethod);
        String path =
            'query?q=SELECT+Id,Name,NamespacePrefix,ManageableState,TableEnumOrId,LayoutType,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,ShowSubmitAndAttachButton,EntityDefinitionId+FROM+Layout+WHERE+EntityDefinition.QualifiedApiName=\'' +
            objectName +
            '\'';
        return api.makeCallout(path, 'application/json', 'GET');
    }

    @AuraEnabled
    public static LayoutDetail getLayoutDetailInfo(Id layoutId) {
        ToolingAPIService api = new ToolingAPIService(authMethod);
        String path = 'sobjects/layout/' + layoutId;
        String layoutJson = api.makeCallout(path, 'application/json', 'GET');
        return new LayoutDetail(
            (Layout) JSON.deserialize(layoutJson, Layout.class)
        );
    }
}