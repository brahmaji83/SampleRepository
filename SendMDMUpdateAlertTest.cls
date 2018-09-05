/**************************************************************************************
Apex Class Name :  SendMDMUpdateAlertTest
Version         : 1.0 
Created Date    : 09 May 2017
Function        : Test Class of SendMDMUpdateAlert 
Status to Initiated Account
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------                 
* Brahma Tammana         09/05/2017                Original Version
*************************************************************************************/
@isTest
private class SendMDMUpdateAlertTest {
    
    @isTest static void testUpdateAccount() {
        
        List <JLLOneforce_Customization_Settings__c> Customsettinglst = new List <JLLOneforce_Customization_Settings__c> ();
        Customsettinglst.add(New JLLOneforce_Customization_Settings__c(Name = 'PrivateinvestorRecType', Is_Active__c = true, Text_Value__c = '0127E0000003mR2'));
        Customsettinglst.add(New JLLOneforce_Customization_Settings__c(Name = 'PrivateInvestorCompanyType', Is_Active__c = true, Text_Value__c = 'Private'));
        insert Customsettinglst;

        //Added Country List custom settings by Brahmaji Tammana on April 12th 
         list < CountryList__c > countrylst = new list < CountryList__c > ();
        countrylst.add(new CountryList__c(name = 'Australia',Region__c = 'Americas'));
        countrylst.add(new CountryList__c(name = 'India',Region__c = 'APAC'));
        countrylst.add(New CountryList__c(Name = 'United States', Region__c = 'Americas'));
        insert countrylst;
        
        
        // Create a new record
        Account a = new Account();
        a.Name = 'Test Account';
        a.BillingCountry = 'Australia';
        a.BillingCity = 'Bangalore';
        a.BillingState = 'Karnataka';
        a.BillingPostalCode = '12345';
        a.BillingStreet = 'EGL';
        a.MDM_validated__c = true;
        insert a;


        Test.startTest();
        a.Name = 'Test Account upd';
        a.BillingCountry = 'United States';
        a.BillingCity = 'Bangalore upd';
        a.BillingState = 'Karnataka upd';
        a.BillingPostalCode = '123456';
        a.BillingStreet = 'EGL upd';

        update a;
        Test.stopTest();
    

        //Bulk Account Testing
        List<Account> accList = new List<Account>();
        for(integer i=0; i<200; i++){
            Account acc =new Account();
            acc.Name = '2Test Account '+i;
            acc.BillingCountry = 'India';
            acc.BillingCity = '2Bangalore upd'+i;
            acc.BillingState = '2Karnataka upd'+i;
            acc.BillingPostalCode = '2123456'+i;
            acc.BillingStreet = '2EGL upd'+i;
            accList.add(acc);
        }
        insert accList;
    }
}