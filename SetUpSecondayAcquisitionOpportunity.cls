/***************************************************************************************************************************************
Class Name	: SetUpSecondayAcquisitionOpportunity    
Purpose		: This help class is used to setup the Seconday AcquisitionOpportunity.
			  It does the following operations:
			  - Create Properties of Sales Opportunity
			  - Create Opportunity team members from Sales Opportunity
			  - Create Opportunity Team
			  - Default Opportunity Team			  
         	  Please maintain only the last 5 history changes/modifications in the audit log.
History of Changes:                 
-----------------------------------------------------------------------------------------------------------------------------------
    Date                                Developer                                               Comments
-----------------------------------------------------------------------------------------------------------------------------------
01-March-2017                         Brahmaji Tammana                          Initial Code    
**************************************************************************************************************************************/
public without sharing class SetUpSecondayAcquisitionOpportunity {
	
	/**********************************************************************
    Method Name     - createOpportunityTeamMembers
    Access Modifier - public
    Purpose         - To create Opportunity Team Members of Sales Opportunity
    Params          - Trigger.new, Trigger.OldMap of Opportunity
    Output          - void
    ***********************************************************************/
	public static void createOTMAndProperties(List<Opportunity> opportunityList, Map<Id, Opportunity> opportunityOldMap) {

		ID acquisitionRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Constants.strAcquisitionRecordType).getRecordTypeId();

		//SalesOpportunities
		Set<Id> salesOpportunityIds = new Set<Id>();

		//Get Existing Opportunity team Members
		Map<Id, Set<Id>> opportunityTeamMembersMap = new Map<Id, Set<Id>>();

		for(Opportunity eachOpportunity : opportunityList){
			if(String.isNotBlank(eachOpportunity.SalesOpportunityId__c) && eachOpportunity.RecordTypeId == acquisitionRecordTypeId){
				
				if(eachOpportunity.SalesOpportunityId__c instanceOf Id){
					salesOpportunityIds.add((Id) eachOpportunity.SalesOpportunityId__c);
					Id salesId = (Id) eachOpportunity.SalesOpportunityId__c;
					//get all opportunity ids and store in map
					//Map with Sales Opportunity Id and current Opportunity (Seconday Acquisistion)
					if(opportunityTeamMembersMap.containsKey(eachOpportunity.Id)){
						Set<Id> existingIds = opportunityTeamMembersMap.get(salesId);
						existingIds.add(eachOpportunity.Id);
						opportunityTeamMembersMap.put(salesId, existingIds);
					}else{
						opportunityTeamMembersMap.put(salesId, new Set<Id> { eachOpportunity.Id });
					}
				
				}				
			}
		}		

		if(! opportunityTeamMembersMap.isEmpty() && ! salesOpportunityIds.isEmpty()){

			List<OpportunityTeamMember> membersToCreate = new List<OpportunityTeamMember>();
			List<Associate_Property__c> propertiesToCreate = new List<Associate_Property__c>();
			List<Opportunity_Sales_Team__c> salesTeamsToCreate = new List<Opportunity_Sales_Team__c>();

			//Get Existing Opportunity team Members
			Map<Id, List<OpportunityTeamMember>> opportunityWithMembers = new Map<Id, List<OpportunityTeamMember>>();

			Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity> ( [SELECT Id, (SELECT Id, UserId, OpportunityAccessLevel, TeamMemberRole
																							FROM OpportunityTeamMembers),
																						 (SELECT Id, Property__c, Opportunity__c
																						 	FROM Associate_Properties__r),
																						 (SELECT Id, Opportunity__c, Sales_Team__c
																						  	FROM Opportunity_Sales_Teams__r)
																				FROM Opportunity
																				WHERE Id IN: salesOpportunityIds] );

			//Iterate the map to create an entry in Teammembers
			for(Opportunity eachOpportunity : opportunityMap.values()){
				for(Id eachAcquisitionId : opportunityTeamMembersMap.get(eachOpportunity.Id)){
					//Create Opportunity team members
					for(OpportunityTeamMember eachMember : eachOpportunity.OpportunityTeamMembers){
						OpportunityTeamMember newMember = new OpportunityTeamMember();
						newMember.OpportunityId = eachAcquisitionId;
						newMember.OpportunityAccessLevel = eachMember.OpportunityAccessLevel;
						newMember.UserId = eachMember.UserId;
						newMember.TeamMemberRole = eachMember.TeamMemberRole;
						membersToCreate.add(newMember);
					}

					//Create Associate Property in Acquisistion
					for(Associate_Property__c eachProperty : eachOpportunity.Associate_Properties__r){
						Associate_Property__c newProperty = new Associate_Property__c();
						newProperty.Opportunity__c = eachAcquisitionId;
						newProperty.Property__c = eachProperty.Property__c;				
						propertiesToCreate.add(newProperty);
					}

					//Create Opportunity Default team in Acquisistion
					for(Opportunity_Sales_Team__c eachDefaultTeam : eachOpportunity.Opportunity_Sales_Teams__r){
						Opportunity_Sales_Team__c newTeam = new Opportunity_Sales_Team__c();
						newTeam.Opportunity__c = eachAcquisitionId;
						newTeam.Sales_Team__c = eachDefaultTeam.Sales_Team__c;				
						salesTeamsToCreate.add(newTeam);
					}
				}				
			}
			//To create Opportunity team members
			try{
				if(! membersToCreate.isEmpty()){
					Insert membersToCreate;
				}
			} catch(Exception ex){
				oneforceUtil exceptionUtilObj = new oneforceUtil();
	            Exception__c exceptionRec = exceptionUtilObj.createExceptionFromResp(SetUpSecondayAcquisitionOpportunity.class.getName(), 'createOpportunityTeamMembers', ex.getMessage());
	            insert exceptionRec;
			}

			//To create Properties
			try{
				if(! propertiesToCreate.isEmpty()){					
					Insert propertiesToCreate;					
				}
			} catch(Exception ex){
				oneforceUtil exceptionUtilObj = new oneforceUtil();
	            Exception__c exceptionRec = exceptionUtilObj.createExceptionFromResp(SetUpSecondayAcquisitionOpportunity.class.getName(), 'createOpportunityTeamMembers', ex.getMessage());
	            insert exceptionRec;
			}

			//To create Sales Team Members
			try{
				if(! salesTeamsToCreate.isEmpty()){
					Insert salesTeamsToCreate;
				}
			} catch(Exception ex){
				oneforceUtil exceptionUtilObj = new oneforceUtil();
	            Exception__c exceptionRec = exceptionUtilObj.createExceptionFromResp(SetUpSecondayAcquisitionOpportunity.class.getName(), 'createOpportunityTeamMembers', ex.getMessage());
	            insert exceptionRec;
			}

			//Create related opportunity 
			if(! opportunityTeamMembersMap.isEmpty()){
				createRelatedOpportunity(opportunityTeamMembersMap);
				updateStageName(opportunityTeamMembersMap);
			}
			
		}				
	}

	/**********************************************************************
    Method Name     - createOpportunityTeamMembers
    Access Modifier - public
    Purpose         - To create Opportunity Team Members of Sales Opportunity
    Params          - Trigger.new, Trigger.OldMap of Opportunity
    Output          - void
    ***********************************************************************/
	public static void createRelatedOpportunity(Map<Id, Set<Id>> salesAndAcquisitionOppMap) {

		List<Related_Opportunity__c> relatedOpportunityList = new List<Related_Opportunity__c>();
		for(Id eachSalesId : salesAndAcquisitionOppMap.keySet()){
			for(Id eachAcquisitionId : salesAndAcquisitionOppMap.get(eachSalesId)){
				Related_Opportunity__c newRelatedOpportunity = new Related_Opportunity__c();
				newRelatedOpportunity.Primary_Opportunity__c = eachSalesId;
				newRelatedOpportunity.Secondary_Opportunity__c = eachAcquisitionId;
				newRelatedOpportunity.Comments__c = 'Auto Created on click of Seconday Acquisistion Opportunity';
				relatedOpportunityList.add(newRelatedOpportunity);
			}			
		}
		
		try{
			if(! relatedOpportunityList.isEmpty()){
				Insert relatedOpportunityList;
			}
		} catch(Exception ex){
			oneforceUtil exceptionUtilObj = new oneforceUtil();
            Exception__c exceptionRec = exceptionUtilObj.createExceptionFromResp(SetUpSecondayAcquisitionOpportunity.class.getName(), 
            												'createRelatedOpportunity', ex.getMessage());
            insert exceptionRec;    
		}
	}

	/**********************************************************************
    Method Name     - createOpportunityTeamMembers
    Access Modifier - public
    Purpose         - To create Opportunity Team Members of Sales Opportunity
    Params          - Trigger.new, Trigger.OldMap of Opportunity
    Output          - void
    ***********************************************************************/
	public static void updateStageName(Map<Id, Set<Id>> salesAndAcquisitionOppMap) {

		List<Opportunity> opportunityList = new List<Opportunity>();

		Map<Id, Opportunity> salesOpportunities = new Map<Id, Opportunity>([SELECT Id, StageName 
																			FROM Opportunity
																			WHERE Id IN: salesAndAcquisitionOppMap.keySet()]);

		for(Id eachSalesId : salesAndAcquisitionOppMap.keySet()){
			for(Id eachAcquisitionId : salesAndAcquisitionOppMap.get(eachSalesId)){
				Opportunity newOpportunity = new Opportunity();
				newOpportunity.Id = eachAcquisitionId;
				newOpportunity.StageName = salesOpportunities.get(eachSalesId).StageName;				
				opportunityList.add(newOpportunity);
			}			
		}
		
		try{
			if(! opportunityList.isEmpty()){
				Constants.disableOpportunityTrigger = true;
				Update opportunityList;
			}
		} catch(Exception ex){
			oneforceUtil exceptionUtilObj = new oneforceUtil();
            Exception__c exceptionRec = exceptionUtilObj.createExceptionFromResp(SetUpSecondayAcquisitionOpportunity.class.getName(), 
            												'updateStageName', ex.getMessage());
            insert exceptionRec;    
		}
	}


}