//NOTE: this leverages the Trigger Actions Framework
// https://github.com/mitchspano/apex-trigger-actions-framework

public without sharing class TA_FundingRequest_InviteToCommunity implements TriggerAction.AfterUpdate {

	private static final String NO_ROLE_ERROR = 'Funding Request Approver\'s must have a Role selected on their User record';

	public void afterUpdate( List<Funding_Request__c> newList, List<Funding_Request__c> oldList ){
		Map<Id, Funding_Request__c> oldMap = new Map<Id, Funding_Request__c>(oldList);
		
		List<Funding_Request__c> targets = new List<Funding_Request__c>();
		Id userRoleId = UserInfo.getUserRoleId();
		Boolean errorDetected = false;
		
		for(Funding_Request__c fundReq : newList){
			Boolean approvedChanged = (fundReq.Approved__c != oldMap?.get(fundReq.Id).Approved__c);
			if(fundReq.Approved__c && approvedChanged){
				if(String.isBlank(userRoleId)) {
					fundReq.addError('Approved__c', NO_ROLE_ERROR);
					errorDetected = true;
					break;
				}
				targets.add(fundReq);
			}
		}
		if(!targets.isEmpty() && !errorDetected) {
			createCommunityUsers(targets);
		}
	}
	
	public class RoleMissingException extends Exception{}
	
	
	private void createCommunityUsers(List<Funding_Request__c> fundReqs ) {
		List<User> usersToInsert = new List<User>();
		Map<Id, User> fundRequestIdToUser = new Map<Id, User>();
		
		for(Funding_Request__c fundReq : fundReqs){
			Account personAccount = new Account(
					FirstName = fundReq.Applicant_First_Name__c,
					LastName = fundReq.Applicant_Last_Name__c,
					OwnerId = UserInfo.getUserId()
			);
			Database.SaveResult sr = Database.insert(personAccount);
			User u = createPortalUser(fundReq, personAccount.Id);
			usersToInsert.add(u);
			fundRequestIdToUser.put(fundReq.Id, u);
		}

		List<Database.SaveResult> saveResults = Database.insert(fundRequestIdToUser.values(), false);
		for(Database.SaveResult sr : saveResults){
			if(sr.isSuccess()){
				System.debug('Successfully inserted user. User ID: ' + sr.getId());
			} else {
				for(Database.Error err : sr.getErrors()){
					//TODO log these with NebulaLogger
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('User fields that affected this error: ' + err.getFields());
				}
			}
		}
		Map<Id, Id> fundIdToOwnerId = new Map<Id, Id>();
		
		for(Id fundReqId : fundRequestIdToUser.keySet()){
			if(fundRequestIdToUser?.get(fundReqId)?.Id != null) {
				fundIdToOwnerId.put(fundReqId, fundRequestIdToUser.get(fundReqId).Id);
			}
		}
		updateFundRequestOwners(fundIdToOwnerId);
	}

	private User createPortalUser( Funding_Request__c fundReq, Id personAccountId){
		Profile p = [ SELECT Id FROM Profile WHERE Name = 'LemonLife Community Login User' ];

		User u = new User(
				UserName = UUID.randomUUID().toString() + '@lemonlife.com',
				FirstName = fundReq.Applicant_First_Name__c,
				LastName = fundReq.Applicant_Last_Name__c,
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
	
	@Future
	private static void updateFundRequestOwners(Map<Id, Id> fundReqIdToOwnerId) {
		List<Funding_Request__c> fundingRequestsToUpdate = new List<Funding_Request__c>();

		for(Id fundRequestId : fundReqIdToOwnerId.keySet()){
			fundingRequestsToUpdate.add(
					new Funding_Request__c(
							Id = fundRequestId,
							OwnerId = fundReqIdToOwnerId.get(fundRequestId)
					)
			);
		}
		
		update fundingRequestsToUpdate;
	}
}