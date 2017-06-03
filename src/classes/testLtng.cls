global class testLtng {

	
	@AuraEnabled
	global static List<Contact> getContacts(string accId, string sortBy, string sortOrder){

		string q = 'select Id, FirstName, LastName, Email '
			+ 'from Contact '
			+ 'where AccountId = \'' + accId + '\' '
			+ 'order by ' + sortBy + ' ' + sortOrder.toUpperCase();

		List<Contact> contacts = database.query(q);
		return contacts;
	}
}