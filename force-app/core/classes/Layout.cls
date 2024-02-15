public with sharing class Layout {
    public Map<String, String> attributes { get; set; }
    public Id id { get; set; }
    public String name { get; set; }
    public String namespacePrefix { get; set; }
    public String manageableState { get; set; }
    public String tableEnumOrId { get; set; }
    public String layoutType { get; set; }
    public DateTime createdDate { get; set; }
    public Id createdById { get; set; }
    public DateTime lastModifiedDate { get; set; }
    public Id lastModifiedById { get; set; }
    public Boolean showSubmitAndAttachButton { get; set; }
    public LayoutMetadata metadata { get; set; }
    public String fullName { get; set; }
    public String entityDefinitionId { get; set; }

    public with sharing class LayoutMetadata {
        public List<String> customButtons { get; set; }
        public CustomConsoleComponents customConsoleComponents { get; set; }
        public Boolean emailDefault { get; set; }
        public List<String> excludeButtons { get; set; }
        public FeedLayout feedLayout { get; set; }
        public List<String> headers { get; set; }
        public List<LayoutSection> layoutSections { get; set; }
        public MiniLayout miniLayout { get; set; }
        public List<String> multilineLayoutFields { get; set; }
        public PlatformActionList platformActionList { get; set; }
        public QuickActionList quickActionList { get; set; }
        public RelatedContent relatedContent { get; set; }
        public List<RelatedListItem> relatedLists { get; set; }
        public List<String> relatedObjects { get; set; }
        public Boolean runAssignmentRulesDefault { get; set; }
        public Boolean showEmailCheckbox { get; set; }
        public Boolean showHighlightsPanel { get; set; }
        public Boolean showInteractionLogPanel { get; set; }
        public Boolean showKnowledgeComponent { get; set; }
        public Boolean showRunAssignmentRulesCheckbox { get; set; }
        public Boolean showSolutionSection { get; set; }
        public Boolean showSubmitAndAttachButton { get; set; }
        public SummaryLayout summaryLayout { get; set; }
        public List<String> urls { get; set; }
    }

    public with sharing class CustomConsoleComponents {
        public PrimaryTabComponents primaryTabComponents { get; set; }
        public SubTabComponents subTabComponents { get; set; }
    }

    public with sharing class PrimaryTabComponents {
        public List<ConsoleComponent> component { get; set; }
        public List<Container> containers { get; set; }
    }

    public with sharing class ConsoleComponent {
        public Integer height { get; set; }
        public String location { get; set; }
        public String visualforcePage { get; set; }
        public Integer width { get; set; }
    }

    public with sharing class Container {
        public Integer height { get; set; }
        public Boolean isContainerAutoSizeEnabled { get; set; }
        public String region { get; set; }
        public List<SidebarComponent> sidebarComponents { get; set; }
        public String style { get; set; }
        public String unit { get; set; }
        public Integer width { get; set; }
    }

    public with sharing class SidebarComponent {
        public String componentType { get; set; }
        public String createAction { get; set; }
        public Boolean enableLinking { get; set; }
        public Integer height { get; set; }
        public String label { get; set; }
        public String lookup { get; set; }
        public String page { get; set; }
        public List<RelatedList> relatedLists { get; set; }
        public String unit { get; set; }
        public String updateAction { get; set; }
        public Integer width { get; set; }
    }

    public with sharing class RelatedList {
        public Boolean hideOnDetail { get; set; }
        public String name { get; set; }
    }

    public with sharing class SubTabComponents {
        public List<ConsoleComponent> component { get; set; }
        public List<Container> containers { get; set; }
    }

    public with sharing class FeedLayout {
        public Boolean autoCollapsePublisher { get; set; }
        public Boolean compactFeed { get; set; }
        public String feedFilterPosition { get; set; }
        public List<FeedLayoutFilter> feedFilters { get; set; }
        public Boolean fullWidthFeed { get; set; }
        public Boolean hideSidebar { get; set; }
        public List<FeedLayoutComponent> leftComponents { get; set; }
        public List<FeedLayoutComponent> rightComponents { get; set; }
    }

    public with sharing class FeedLayoutComponent {
        public String componentType { get; set; }
        public Integer height { get; set; }
        public String page { get; set; }
    }

    public with sharing class FeedLayoutFilter {
        public String feedFilterName { get; set; }
        public String feedFilterType { get; set; }
        public String feedItemType { get; set; }
    }

    public with sharing class MiniLayout {
        public List<String> fields { get; set; }
        public List<RelatedListItem> relatedLists { get; set; }
    }

    public with sharing class LayoutSection {
        public Boolean customLabel { get; set; }
        public Boolean detailHeading { get; set; }
        public Boolean editHeading { get; set; }
        public String label { get; set; }
        public List<LayoutColumn> layoutColumns { get; set; }
        public String style { get; set; }
    }

    public with sharing class LayoutColumn {
        public List<LayoutItem> layoutItems { get; set; }
        public String reserved { get; set; }
    }

    public with sharing class LayoutItem {
        public String behavior { get; set; }
        public String canvas { get; set; }
        public String component { get; set; }
        public String customLink { get; set; }
        public Boolean emptySpace { get; set; }
        public String field { get; set; }
        public Integer height { get; set; }
        public String page { get; set; }
        public String feedFilterName { get; set; }
        public AnalyticsCloudComponentLayoutItem analyticsCloudComponent { get; set; }
        public ReportChartComponentLayoutItem reportChartComponent { get; set; }
        public String sControl { get; set; }
        public Boolean showLabel { get; set; }
        public Boolean showScrollbars { get; set; }
        public String width { get; set; }
    }

    public with sharing class AnalyticsCloudComponentLayoutItem {
        public String assetType { get; set; }
        public String devName { get; set; }
        public String error { get; set; }
        public String filter { get; set; }
        public Integer height { get; set; }
        public Boolean hideOnError { get; set; }
        public Boolean showSharing { get; set; }
        public Boolean showTitle { get; set; }
        public String width { get; set; }
    }

    public with sharing class ReportChartComponentLayoutItem {
        public Boolean cacheData { get; set; }
        public String contextFilterableField { get; set; }
        public String error { get; set; }
        public Boolean hideOnError { get; set; }
        public Boolean includeContext { get; set; }
        public String reportName { get; set; }
        public Boolean showTitle { get; set; }
        public String size { get; set; }
    }

    public with sharing class PlatformActionList {
        public String actionListContext { get; set; }
        public List<PlatformActionListItem> platformActionListItems { get; set; }
        public String relatedSourceEntity { get; set; }
    }

    public with sharing class PlatformActionListItem {
        public String actionName { get; set; }
        public String actionType { get; set; }
        public Integer sortOrder { get; set; }
        public String subType { get; set; }
    }

    public with sharing class QuickActionList {
        public List<QuickActionListItem> quickActionListItems { get; set; }
    }

    public with sharing class QuickActionListItem {
        public String quickActionName { get; set; }
    }

    public with sharing class RelatedContent {
        public List<RelatedContentItem> relatedContentItems { get; set; }
    }

    public with sharing class RelatedContentItem {
        public LayoutItem layoutItem { get; set; }
    }

    public with sharing class RelatedListItem {
        public List<String> customButtons { get; set; }
        public List<String> excludeButtons { get; set; }
        public List<String> fields { get; set; }
        public List<String> quickActions { get; set; }
        public String relatedList { get; set; }
        public String sortField { get; set; }
        public String sortOrder { get; set; }
    }

    public with sharing class SummaryLayout {
        public String masterLabel { get; set; }
        public Integer sizeX { get; set; }
        public Integer sizeY { get; set; }
        public Integer sizeZ { get; set; }
        public List<SummaryLayoutItem> summaryLayoutItems { get; set; }
        public String summaryLayoutStyle { get; set; }
    }

    public with sharing class SummaryLayoutItem {
        public String customLink { get; set; }
        public String field { get; set; }
        public Integer posX { get; set; }
        public Integer posY { get; set; }
        public Integer posZ { get; set; }
    }
}
