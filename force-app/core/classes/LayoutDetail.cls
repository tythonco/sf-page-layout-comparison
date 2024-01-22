public with sharing class LayoutDetail {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Id createdById;
    @AuraEnabled
    public DateTime createdDate;
    @AuraEnabled
    public List<String> includedFields;
    @AuraEnabled
    public string objectName;

    public LayoutDetail(Layout layout) {
        this.Id = layout.id;
        this.name = layout.name;
        this.createdById = layout.createdById;
        this.createdDate = layout.createdDate;
        this.objectName = layout.fullName.split('-', 2)[0];
        this.includedFields = new List<String>();
        if (layout.metadata != null && layout.metadata.layoutSections != null) {
            for (
                Layout.LayoutSection section : layout.metadata.layoutSections
            ) {
                if (section.layoutColumns != null) {
                    for (Layout.LayoutColumn column : section.layoutColumns) {
                        if (column.layoutItems != null) {
                            for (Layout.LayoutItem item : column.layoutItems) {
                                if (item.field != null) {
                                    this.includedFields.add(item.field);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}