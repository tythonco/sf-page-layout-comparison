public with sharing class ComparisonController {
    @AuraEnabled
    public static List<String> fetchPageLayoutIncludedFields(
        String authMethod,
        String cmdtUpsertMethod,
        String domain,
        String username,
        String objectName,
        String pageLayoutName
    ) {
        try {
            domain = domain != null
                ? domain
                : URL.getOrgDomainUrl().toExternalForm();
            List<String> includedFields = new List<String>();
            ToolingAPIService.AUTH_METHOD apiAuthMethod;
            switch on authMethod {
                when 'session_id' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.CURRENT_USER_SESSIONID;
                }
                when 'session_id_from_vf' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.CURRENT_USER_SESSIONID_FROM_VF;
                }
                when 'creds' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_CREDENTIALS;
                }
                when 'device' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_DEVICE;
                }
                when 'jwt_ak' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_JWT_ADMIN_KEY;
                }
                when 'jwt_kp' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_JWT_KEY_PACKAGED;
                }
                when 'web' {
                    apiAuthMethod = ToolingAPIService.AUTH_METHOD.OAUTH_WEB_SERVER;
                }
                when else {
                    apiAuthMethod = ToolingAPIService.DEFAULT_AUTH_METHOD;
                }
            }
            OAuthService.CMDT_UPSERT_METHOD cmdtUpsertChannel;            
            switch on cmdtUpsertMethod {
                when 'apex' {
                    cmdtUpsertChannel = OAuthService.CMDT_UPSERT_METHOD.APEX;
                }
                when 'api' {
                    cmdtUpsertChannel = OAuthService.CMDT_UPSERT_METHOD.API;
                }
            }
            String layoutsForObjectJson = LayoutService.getLayoutsForObject(
                apiAuthMethod,
                cmdtUpsertChannel,
                domain,
                username,
                objectName
            );
            Map<String, Object> layoutsForObjectInfo = (Map<String, Object>) JSON.deserializeUntyped(
                layoutsForObjectJson
            );
            List<Object> layoutsForObject = (List<Object>) layoutsForObjectInfo.get(
                'records'
            );
            Id matchingLayoutId;
            for (Object lObject : layoutsForObject) {
                Map<String, Object> l = (Map<String, Object>) lObject;
                String name = (String) l.get('Name');
                if (name == pageLayoutName) {
                    matchingLayoutId = (Id) l.get('Id');
                }
            }
            if (matchingLayoutId != null) {
                LayoutDetail layout = LayoutService.getLayoutDetailInfo(
                    apiAuthMethod,
                    cmdtUpsertChannel,
                    domain,
                    username,
                    matchingLayoutId
                );
                includedFields = layout.includedFields;
            }
            return includedFields;
        } catch (AuraHandledException ahe) {
            throw new AuraHandledException(ahe.getMessage());
        } catch (System.Exception e) {
            throw new AuraHandledException(
                e.getMessage() + e.getStackTraceString()
            );
        }
    }
}
