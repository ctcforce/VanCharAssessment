//NOTE: this leverages the Trigger Actions Framework
// https://github.com/mitchspano/apex-trigger-actions-framework

public without sharing class TA_FundingRequest_InviteToCommunity implements TriggerAction.AfterUpdate {
	
	public void afterUpdate( List<Funding_Request__c> newList, List<Funding_Request__c> oldList ){
		Map<Id, Funding_Request__c> oldMap = new Map<Id, Funding_Request__c>(oldList);
		
		List<Funding_Request__c> targets = new List<Funding_Request__c>();
		
		for(Funding_Request__c fundReq : newList){
			Boolean approvedChanged = (fundReq.Approved__c != oldMap?.get(fundReq.Id).Approved__c);
			if(fundReq.Approved__c && approvedChanged){
				targets.add(fundReq);
			}
		}
		if(!targets.isEmpty()) {
			createCommunityUsers(targets);
		}
	}
	
	private void createCommunityUsers(List<Funding_Request__c> fundReqs ) {
		List<User> usersToInsert = new List<User>();
		
		for(Funding_Request__c fundReq : fundReqs){
			Account personAccount = new Account(
					FirstName = fundReq.Applicant_First_Name__c,
					LastName = fundReq.Applicant_Last_Name__c,
					OwnerId = UserInfo.getUserId()
			);
			Database.insert(personAccount);

			User u = createPortalUser(fundReq, personAccount.Id);
			usersToInsert.add(u);
		}

		List<Database.SaveResult> saveResults = Database.insert(usersToInsert, false);
		for(Database.SaveResult sr : saveResults){
			if(sr.isSuccess()){
				System.debug('Successfully inserted user. User ID: ' + sr.getId());
			} else {
				for(Database.Error err : sr.getErrors()){
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('User fields that affected this error: ' + err.getFields());
				}
			}
		}
	}

	private User createPortalUser( Funding_Request__c fundReq, Id personAccountId){
		Profile p = [ SELECT Id FROM Profile WHERE Name = 'LemonLife Community Login User' ];

		User u = new User(
				UserName = UUID.randomUUID().toString() + '@lemonlife.com',
				FirstName = fundReq.Applicant_First_Name__c,
				LastName = fundReq.Applicant_First_Name__c,
				Alias = fundReq.Applicant_First_Name__c.substring(0, 1) + fundReq.Applicant_Last_Name__c.left(7),
				email = fundReq.Applicant_Email__c,
				CommunityNickName = string.valueOf(math.random()).substring(0, 6),
				ProfileID = p.id,
				ContactId = [ SELECT PersonContactId FROM Account WHERE Id = :personAccountId ].PersonContactId,
				TimeZoneSidKey = 'America/New_York',
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US'
		);
		return u;
	}
}