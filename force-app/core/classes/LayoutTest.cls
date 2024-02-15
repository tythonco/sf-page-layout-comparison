@isTest
public with sharing class LayoutTest {
    @isTest
    public static void testLayout() {
        Layout.SummaryLayoutItem sli = new Layout.SummaryLayoutItem();
        sli.customLink = 'test';
        sli.field = 'test';
        sli.posX = 1;
        sli.posY = 1;
        sli.posZ = 1;
        Layout.SummaryLayout sl = new Layout.SummaryLayout();
        sl.masterLabel = 'test';
        sl.sizeX = 1;
        sl.sizeY = 1;
        sl.sizeZ = 1;
        sl.summaryLayoutItems = new List<Layout.SummaryLayoutItem>{sli};
        sl.summaryLayoutStyle = 'test';
        Layout.RelatedListItem rli = new Layout.RelatedListItem();
        rli.customButtons = new List<String>{'test'};
        rli.excludeButtons = new List<String>{'test'};
        rli.fields = new List<String>{'test'};
        rli.quickActions = new List<String>{'test'};
        rli.relatedList = 'test';
        rli.sortField = 'test';
        rli.sortOrder = 'test';
        Layout.AnalyticsCloudComponentLayoutItem accli = new Layout.AnalyticsCloudComponentLayoutItem();
        accli.assetType = 'test';
        accli.devName = 'test';
        accli.error = 'test';
        accli.filter = 'test';
        accli.height = 1;
        accli.hideOnError = false;
        accli.showSharing = false;
        accli.showTitle = false;
        accli.width = '100';
        Layout.ReportChartComponentLayoutItem rccli = new Layout.ReportChartComponentLayoutItem();
        rccli.cacheData = false;
        rccli.contextFilterableField = 'test';
        rccli.error = 'teste';
        rccli.hideOnError = false;
        rccli.includeContext = false;
        rccli.reportName = 'test';
        rccli.showTitle = false;
        rccli.size = 'test';
        Layout.LayoutItem li = new Layout.LayoutItem();
        li.behavior = 'test';
        li.canvas = 'test';
        li.component = 'test';
        li.customLink = 'test';
        li.emptySpace = false;
        li.field = 'test';
        li.height = 1;
        li.page = 'test';
        li.feedFilterName = 'test';
        li.analyticsCloudComponent = accli;
        li.reportChartComponent = rccli;
        li.sControl = 'test';
        li.showLabel = false;
        li.showScrollbars = false;
        li.width = '100';
        Layout.RelatedContentItem rci = new Layout.RelatedContentItem();
        rci.layoutItem = li;
        Layout.RelatedContent rc = new Layout.RelatedContent();
        rc.relatedContentItems = new List<Layout.RelatedContentItem>{rci};
        Layout.QuickActionListItem qali = new Layout.QuickActionListItem();
        qali.quickActionName = 'test';
        Layout.QuickActionList qal = new Layout.QuickActionList();
        qal.quickActionListItems = new List<Layout.QuickActionListItem>{qali};
        Layout.PlatformActionListItem pali = new Layout.PlatformActionListItem();
        pali.actionName = 'test';
        pali.actionType = 'test';
        pali.sortOrder = 1;
        pali.subType = 'test';
        Layout.PlatformActionList pal = new Layout.PlatformActionList();
        pal.actionListContext = 'test';
        pal.platformActionListItems = new List<Layout.PlatformActionListItem>{pali};
        pal.relatedSourceEntity = 'test';
        Layout.LayoutColumn lc = new Layout.LayoutColumn();
        lc.layoutItems = new List<Layout.LayoutItem>{li};
        lc.reserved = 'test';
        Layout.LayoutSection ls = new Layout.LayoutSection();
        ls.customLabel = false;
        ls.detailHeading = false;
        ls.editHeading = false;
        ls.label = 'test';
        ls.layoutColumns = new List<Layout.LayoutColumn>{lc};
        ls.style = 'test';
        Layout.MiniLayout ml = new Layout.MiniLayout();
        ml.fields = new List<String>{'test'};
        ml.relatedLists = new List<Layout.RelatedListItem>{rli};
        Layout.FeedLayoutFilter flf = new Layout.FeedLayoutFilter();
        flf.feedFilterName = 'test';
        flf.feedFilterType = 'test';
        flf.feedItemType = 'test';
        Layout.FeedLayoutComponent flc = new Layout.FeedLayoutComponent();
        flc.componentType = 'test';
        flc.height = 100;
        flc.page = 'test';
        Layout.FeedLayout fl = new Layout.FeedLayout();
        fl.autoCollapsePublisher = false;
        fl.compactFeed = false;
        fl.feedFilterPosition = 'test';
        fl.feedFilters = new List<Layout.FeedLayoutFilter>{flf};
        fl.fullWidthFeed = false;
        fl.hideSidebar = false;
        fl.leftComponents = new List<Layout.FeedLayoutComponent>{flc};
        fl.rightComponents = new List<Layout.FeedLayoutComponent>{flc};
        Layout.RelatedList rl = new Layout.RelatedList();
        rl.hideOnDetail = false;
        rl.name = 'test';
        Layout.SidebarComponent sc = new Layout.SidebarComponent();
        sc.componentType = 'test';
        sc.createAction = 'test';
        sc.enableLinking = false;
        sc.height = 1;
        sc.label = 'test';
        sc.lookup = 'test';
        sc.page = 'test';
        sc.relatedLists = new List<Layout.RelatedList>{rl};
        sc.unit = 'test';
        sc.updateAction = 'test';
        sc.width = 1;
        Layout.Container c = new Layout.Container();
        c.height = 1;
        c.isContainerAutoSizeEnabled = false;
        c.region = 'test';
        c.sidebarComponents = new List<Layout.SidebarComponent>{sc};
        c.style = 'test';
        c.unit = 'test';
        c.width = 1;
        Layout.ConsoleComponent cc = new Layout.ConsoleComponent();
        cc.height = 100;
        cc.location = 'test';
        cc.visualforcePage = 'test';
        cc.width = 100;
        Layout.PrimaryTabComponents ptc = new Layout.PrimaryTabComponents();
        ptc.component = new List<Layout.ConsoleComponent>{cc};
        ptc.containers = new List<Layout.Container>{c};
        Layout.SubTabComponents stc = new Layout.SubTabComponents();
        stc.component = new List<Layout.ConsoleComponent>{cc};
        stc.containers = new List<Layout.Container>{c};
        Layout.CustomConsoleComponents ccc = new Layout.CustomConsoleComponents();
        ccc.primaryTabComponents = ptc;
        ccc.subTabComponents = stc;
        Layout.LayoutMetadata lm = new Layout.LayoutMetadata();
        lm.customButtons = new List<String>{'test'};
        lm.customConsoleComponents = ccc;
        lm.emailDefault = false;
        lm.excludeButtons = new List<String>{'test'};
        lm.feedLayout = fl;
        lm.headers = new List<String>{'test'};
        lm.layoutSections = new List<Layout.LayoutSection>{ls};
        lm.miniLayout = ml;
        lm.multilineLayoutFields = new List<String>{'test'};
        lm.platformActionList = pal;
        lm.quickActionList = qal;
        lm.relatedContent = rc;
        lm.relatedLists = new List<Layout.RelatedListItem>{rli};
        lm.relatedObjects = new List<String>{'test'};
        lm.runAssignmentRulesDefault = false;
        lm.showEmailCheckbox = false;
        lm.showHighlightsPanel = false;
        lm.showInteractionLogPanel = false;
        lm.showKnowledgeComponent = false;
        lm.showRunAssignmentRulesCheckbox = false;
        lm.showSolutionSection = false;
        lm.showSubmitAndAttachButton = false;
        lm.summaryLayout = sl;
        lm.urls = new List<String>{'test'};
        Layout l = new Layout();
        l.attributes = new Map<String,String>{'test' => 'test'};
        l.id = Id.valueOf('001000000000000');
        l.name = 'test';
        l.namespacePrefix = 'test';
        l.manageableState = 'test';
        l.tableEnumOrId = 'test';
        l.layoutType = 'test';
        l.createdDate = System.now();
        l.createdById = Id.valueOf('001000000000000');
        l.lastModifiedDate = System.now();
        l.lastModifiedById = Id.valueOf('001000000000000');
        l.showSubmitAndAttachButton = false;
        l.metadata = lm;
        l.fullName = 'test';
        l.entityDefinitionId = 'test';
        Assert.isNotNull(l);
    }
}