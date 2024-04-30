public class FinalizeProgramBatchable implements Database.Batchable<SObject>, Schedulable {
	
	private static final String COMMUNITY_PROFILE_NAME = 'LemonLife Community Login User';

	public Database.QueryLocator start( Database.BatchableContext BC ){
		return Database.getQueryLocator([
				SELECT ContactId, Contact.Lemonade_Grant_Program_Completed__c
				FROM User
				WHERE Profile.Name = :COMMUNITY_PROFILE_NAME
				AND Contact.Lemonade_Grant_Program_Completed__c != TRUE
		]);
	}
	
	//Batchable execute
	public void execute( Database.BatchableContext BC, List<User> scope ){
		List<Contact> contactsToUpdate = new List<Contact>();
		
		for(User u : scope){
			contactsToUpdate.add(
					new Contact(
							Id = u.ContactId,
							Lemonade_Grant_Program_Completed__c = true
					)
			);
		}   
		update contactsToUpdate;
	}

	public void finish( Database.BatchableContext BC ){ }

	//Schedulable execute
	public void execute( SchedulableContext sc ){
		Database.executeBatch(new FinalizeProgramBatchable());
	}

}