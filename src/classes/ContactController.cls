public with sharing class ContactController {

    @AuraEnabled
    public static List<Contact> findAll() {
        return [SELECT id, Name, FirstName, LastName, phone, email FROM Contact ORDER BY LastName ASC LIMIT 50];
    }

    @AuraEnabled
    public static List<Contact> findByName(String searchKey) {
        String name = '%' + searchKey + '%';
        return [SELECT id, Name, FirstName, LastName, phone, email FROM Contact WHERE name LIKE :name ORDER BY LastName ASC LIMIT 50];
    }

    @AuraEnabled
    public static Contact findById(String contactId) {
        return [SELECT id, name, FirstName, LastName, title, phone, mobilephone, Account.Name, email
                    FROM Contact WHERE Id = :contactId ]; 
    }

}