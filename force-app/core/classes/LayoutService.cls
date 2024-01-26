public with sharing class LayoutService {
    @AuraEnabled
    public static String getLayoutsForObject(
        ToolingAPIService.AUTH_METHOD authMethod,
        String domain,
        String username,
        String objectName
    ) {
        ToolingAPIService api = new ToolingAPIService(
            authMethod,
            domain,
            username,
            ToolingApiService.DEFAULT_VERSION
        );
        String path =
            'query?q=SELECT+Id,Name,NamespacePrefix,ManageableState,TableEnumOrId,LayoutType,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,ShowSubmitAndAttachButton,EntityDefinitionId+FROM+Layout+WHERE+EntityDefinition.QualifiedApiName=\'' +
            objectName +
            '\'';
        return api.makeCallout(path, 'application/json', 'GET');
    }

    public static LayoutDetail getLayoutDetailInfo(
        ToolingAPIService.AUTH_METHOD authMethod,
        String domain,
        String username,
        Id layoutId
    ) {
        ToolingAPIService api = new ToolingAPIService(
            authMethod,
            domain,
            username,
            ToolingApiService.DEFAULT_VERSION
        );
        String path = 'sobjects/layout/' + layoutId;
        String layoutJson = api.makeCallout(path, 'application/json', 'GET');
        return new LayoutDetail(
            (Layout) JSON.deserialize(layoutJson, Layout.class)
        );
    }
}