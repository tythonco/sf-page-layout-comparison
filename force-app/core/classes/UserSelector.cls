public with sharing class UserSelector {
    public static User fetchById(Id userId) {
        List<User> matchingUsers = fetchByIds(new List<Id>{ userId });
        return matchingUsers.isEmpty() ? null : matchingUsers[0];
    }

    public static List<User> fetchByIds(List<Id> userIds) {
        return [
            SELECT Id, Email, Name, Username
            FROM User
            WHERE Id IN :userIds
        ];
    }
}