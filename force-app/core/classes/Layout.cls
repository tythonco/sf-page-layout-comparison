public with sharing class Layout {
    public Map<String, String> attributes;
    public Id id;
    public String name;
    public String namespacePrefix;
    public String manageableState;
    public String tableEnumOrId;
    public String layoutType;
    public DateTime createdDate;
    public Id createdById;
    public DateTime lastModifiedDate;
    public Id lastModifiedById;
    public Boolean showSubmitAndAttachButton;
    public LayoutMetadata metadata;
    public String fullName;
    public String entityDefinitionId;

    public with sharing class LayoutMetadata {
        public List<String> customButtons;
        public CustomConsoleComponents customConsoleComponents;
        public Boolean emailDefault;
        public List<String> excludeButtons;
        public FeedLayout feedLayout;
        public List<String> headers;
        public List<LayoutSection> layoutSections;
        public MiniLayout miniLayout;
        public List<String> multilineLayoutFields;
        public PlatformActionList platformActionList;
        public QuickActionList quickActionList;
        public RelatedContent relatedContent;
        public List<RelatedListItem> relatedLists;
        public List<String> relatedObjects;
        public Boolean runAssignmentRulesDefault;
        public Boolean showEmailCheckbox;
        public Boolean showHighlightsPanel;
        public Boolean showInteractionLogPanel;
        public Boolean showKnowledgeComponent;
        public Boolean showRunAssignmentRulesCheckbox;
        public Boolean showSolutionSection;
        public Boolean showSubmitAndAttachButton;
        public SummaryLayout summaryLayout;
        public List<String> urls;
    }

    public with sharing class CustomConsoleComponents {
        public PrimaryTabComponents primaryTabComponents;
        public SubTabComponents subTabComponents;
    }

    public with sharing class PrimaryTabComponents {
        public List<ConsoleComponent> component;
        public List<Container> containers;
    }

    public with sharing class ConsoleComponent {
        public Integer height;
        public String location;
        public String visualforcePage;
        public Integer width;
    }

    public with sharing class Container {
        public Integer height;
        public Boolean isContainerAutoSizeEnabled;
        public String region;
        public List<SidebarComponent> sidebarComponents;
        public String style;
        public String unit;
        public Integer width;
    }

    public with sharing class SidebarComponent {
        public String componentType;
        public String createAction;
        public Boolean enableLinking;
        public Integer height;
        public String label;
        public String lookup;
        public String page;
        public List<RelatedList> relatedLists;
        public String unit;
        public String updateAction;
        public Integer width;
    }

    public with sharing class RelatedList {
        public Boolean hideOnDetail;
        public String name;
    }

    public with sharing class SubTabComponents {
        public List<ConsoleComponent> component;
        public List<Container> containers;
    }

    public with sharing class FeedLayout {
        public Boolean autoCollapsePublisher;
        public Boolean compactFeed;
        public String feedFilterPosition;
        public List<FeedLayoutFilter> feedFilters;
        public Boolean fullWidthFeed;
        public Boolean hideSidebar;
        public List<FeedLayoutComponent> leftComponents;
        public List<FeedLayoutComponent> rightComponents;
    }

    public with sharing class FeedLayoutComponent {
        public String componentType;
        public Integer height;
        public String page;
    }

    public with sharing class FeedLayoutFilter {
        public String feedFilterName;
        public String feedFilterType;
        public String feedItemType;
    }

    public with sharing class MiniLayout {
        public List<String> fields;
        public List<RelatedListItem> relatedLists;
    }

    public with sharing class LayoutSection {
        public Boolean customLabel;
        public Boolean detailHeading;
        public Boolean editHeading;
        public String label;
        public List<LayoutColumn> layoutColumns;
        public String style;
    }

    public with sharing class LayoutColumn {
        public List<LayoutItem> layoutItems;
        public String reserved;
    }

    public with sharing class LayoutItem {
        public String behavior;
        public String canvas;
        public String component;
        public String customLink;
        public Boolean emptySpace;
        public String field;
        public Integer height;
        public String page;
        public String feedFilterName;
        public AnalyticsCloudComponentLayoutItem analyticsCloudComponent;
        public ReportChartComponentLayoutItem reportChartComponent;
        public String sControl;
        public Boolean showLabel;
        public Boolean showScrollbars;
        public String width;
    }

    public with sharing class AnalyticsCloudComponentLayoutItem {
        public String assetType;
        public String devName;
        public String error;
        public String filter;
        public Integer height;
        public Boolean hideOnError;
        public Boolean showSharing;
        public Boolean showTitle;
        public String width;
    }

    public with sharing class ReportChartComponentLayoutItem {
        public Boolean cacheData;
        public String contextFilterableField;
        public String error;
        public Boolean hideOnError;
        public Boolean includeContext;
        public String reportName;
        public Boolean showTitle;
        public String size;
    }

    public with sharing class PlatformActionList {
        public String actionListContext;
        public List<PlatformActionListItem> platformActionListItems;
        public String relatedSourceEntity;
    }

    public with sharing class PlatformActionListItem {
        public String actionName;
        public String actionType;
        public Integer sortOrder;
        public String subType;
    }

    public with sharing class QuickActionList {
        public List<QuickActionListItem> quickActionListItems;
    }

    public with sharing class QuickActionListItem {
        public String quickActionName;
    }

    public with sharing class RelatedContent {
        public List<RelatedContentItem> relatedContentItems;
    }

    public with sharing class RelatedContentItem {
        public LayoutItem layoutItem;
    }

    public with sharing class RelatedListItem {
        public List<String> customButtons;
        public List<String> excludeButtons;
        public List<String> fields;
        public List<String> quickActions;
        public String relatedList;
        public String sortField;
        public String sortOrder;
    }

    public with sharing class SummaryLayout {
        public String masterLabel;
        public Integer sizeX;
        public Integer sizeY;
        public Integer sizeZ;
        public List<SummaryLayoutItem> summaryLayoutItems;
        public String summaryLayoutStyle;
    }

    public with sharing class SummaryLayoutItem {
        public String customLink;
        public String field;
        public Integer posX;
        public Integer posY;
        public Integer posZ;
    }
}