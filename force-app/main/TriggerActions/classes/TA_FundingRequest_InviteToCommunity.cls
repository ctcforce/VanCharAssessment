//NOTE: this leverages the Trigger Actions Framework
// https://github.com/mitchspano/apex-trigger-actions-framework

public without sharing class TA_FundingRequest_InviteToCommunity implements TriggerAction.AfterUpdate {
	
	public void afterUpdate( List<Funding_Request__c> newList, List<Funding_Request__c> oldList ){
		Map<Id, Funding_Request__c> oldMap = new Map<Id, Funding_Request__c>(oldList);
		
		List<Funding_Request__c> targets = new List<Funding_Request__c>();
		
		for(Funding_Request__c funReq : newList){
			Boolean approvedChanged = (funReq.Approved__c != oldMap?.get(funReq.Id).Approved__c);
			if(funReq.Approved__c && approvedChanged){
				targets.add(funReq);
			}
		}
		
		if(!targets.isEmpty()) {
		}
	}
}