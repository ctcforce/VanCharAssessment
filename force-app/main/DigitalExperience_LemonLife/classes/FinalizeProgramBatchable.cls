public class FinalizeProgramBatchable implements Database.Batchable<SObject>, Schedulable {

	public Database.QueryLocator start( Database.BatchableContext BC ){
		return Database.getQueryLocator([
				SELECT Id
				FROM Contact
				WHERE Lemonade_Grant_Program_Completed__c != TRUE
		]);
	}
	
	//Batchable execute
	public void execute( Database.BatchableContext BC, List<Contact> scope ){
		for(Contact con : scope){
			con.Lemonade_Grant_Program_Completed__c = true;
		}
		update scope;
	}

	public void finish( Database.BatchableContext BC ){ }

	//Schedulable execute
	public void execute( SchedulableContext sc ){
		Database.executeBatch(new FinalizeProgramBatchable());
	}

}