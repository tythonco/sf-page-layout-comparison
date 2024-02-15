public with sharing class LayoutService {
    private static final Map<String,Object> TEST_LAYOUTS_FOR_OBJECT = new Map<String,Object>{
        'records' => new List<Object>{
            new Map<String,String>{
                'Name' => 'Account Layout',
                'Id' => '00h000000000000'
            }
        }
    };
    private static final Map<String,Object> TEST_LAYOUT;
    static {
        Layout.LayoutItem testLayoutItem1 = new Layout.LayoutItem();
        testLayoutItem1.field = 'test_field_1';
        Layout.LayoutItem testLayoutItem2 = new Layout.LayoutItem();
        testLayoutItem2.field = 'test_field_2';
        Layout.LayoutColumn testLayoutColumn = new Layout.LayoutColumn();
        testLayoutColumn.layoutItems = new List<Layout.LayoutItem>{
            testLayoutItem1,
            testLayoutItem2
        };
        Layout.LayoutSection testLayoutSection = new Layout.LayoutSection();
        testLayoutSection.layoutColumns = new List<Layout.LayoutColumn>{
            testLayoutColumn
        };

        TEST_LAYOUT = new Map<String,Object>{
            'id' => '00h000000000000',
            'name' => 'Account Layout',
            'createdById' => '005000000000000',
            'createdDate' => Datetime.now().format('yyyy-MM-dd'),
            'fullName' => 'Account-Account Layout',
            'metadata' => new Map<String,Object>{
                'layoutSections' => new List<Layout.LayoutSection>{
                    testLayoutSection
                }
            }
        };
    }

    @AuraEnabled
    public static String getLayoutsForObject(
        ToolingAPIService.AUTH_METHOD authMethod,
        OAuthService.CMDT_UPSERT_METHOD cmdtUpsertMethod,
        String domain,
        String username,
        String objectName
    ) {
        ToolingAPIService api = new ToolingAPIService(
            authMethod,
            cmdtUpsertMethod,
            domain,
            username,
            ToolingApiService.DEFAULT_VERSION
        );
        String path =
            'query?q=SELECT+Id,Name,NamespacePrefix,ManageableState,TableEnumOrId,LayoutType,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,ShowSubmitAndAttachButton,EntityDefinitionId+FROM+Layout+WHERE+EntityDefinition.QualifiedApiName=\'' +
            objectName +
            '\'';
        return Test.isRunningTest()
            ? JSON.serialize(TEST_LAYOUTS_FOR_OBJECT)
            : api.makeCallout(path, 'application/json', 'GET', false);
    }

    public static LayoutDetail getLayoutDetailInfo(
        ToolingAPIService.AUTH_METHOD authMethod,
        OAuthService.CMDT_UPSERT_METHOD cmdtUpsertMethod,
        String domain,
        String username,
        Id layoutId
    ) {
        ToolingAPIService api = new ToolingAPIService(
            authMethod,
            cmdtUpsertMethod,
            domain,
            username,
            ToolingApiService.DEFAULT_VERSION
        );
        String path = 'sobjects/layout/' + layoutId;
        String layoutJson = Test.isRunningTest()
            ? JSON.serialize(TEST_LAYOUT)
            : api.makeCallout(path, 'application/json', 'GET', true);
        return new LayoutDetail(
            (Layout) JSON.deserialize(layoutJson, Layout.class)
        );
    }
}
