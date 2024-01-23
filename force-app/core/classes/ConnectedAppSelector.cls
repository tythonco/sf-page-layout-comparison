public with sharing class ConnectedAppSelector {
    public static List<ConnectedApp__mdt> fetchAll() {
        return [
            SELECT
                DeveloperName,
                Label,
                MasterLabel,
                NamespacePrefix,
                QualifiedApiName,
                SystemModStamp,
                Value__c
            FROM ConnectedApp__mdt
        ];
    }

    public static ConnectedApp__mdt fetchByName(String developerName) {
        return [
            SELECT
                DeveloperName,
                Label,
                MasterLabel,
                NamespacePrefix,
                QualifiedApiName,
                SystemModStamp,
                Value__c
            FROM ConnectedApp__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
    }
}