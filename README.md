test
```javascript
// RLW 21 May 2019
// Created for proving out the Accounting Seed API for posting JE records sourced from billing
// Database.executeBatch((new aMindCPQBill_AS_IntegratedJEPoster()), 2);
// TODO - add error handling and logging code when object and utility class is ready for it
// TODO - add test coverage

global class aMindCPQBill_AS_IntegratedJEPoster implements Database.Batchable<sObject>, Database.stateful {
    
    // Initialize Log object to track events
    private AMIND_OperationLogUtil.Log opLog = 
      new AMIND_OperationLogUtil.Log('IntegratedJEPoster' + Datetime.now(), 'BatchApex');
   
    global Database.QueryLocator  start (Database.BatchableContext bc) {
        // Set execution date and save log in DB
        opLog.ExecuteDate = Datetime.now();
        opLog.id = AMIND_OperationLogUtil.addLog(opLog);
        
        // get all the JE records where they're approved but not yet posted and sourced from billing
        return (Database.getQueryLocator('SELECT Id, Name FROM AcctSeed__Journal_Entry__c WHERE AcctSeed__Status__c = \'Approved\' AND aMindCPQBill_Sourced_from_SF_Billing__c = true'));
    }
    global void execute (Database.BatchableContext bc, List<AcctSeed__Journal_Entry__c> records){
        try {
        
            opLog.appendNotes('Number of Journal Entries:' + records.size());
            // process each batch of records
            AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(records);
            opLog.ItemsProcessed++;
            // TODO - do something intelligent with the results
        } catch (Exception ex) {
            // Count failed items
            opLog.FailureCount++;
            //Save log with latest updates
            AMIND_OperationLogUtil.finishLog(opLog, 'ERROR', 'ERROR:'+ex.getMessage());
        }

    }    
    global void finish (Database.BatchableContext bc){
        // execute any post-processing operations
        // nothing to do here
        
        String result = (this.opLog.FailureCount == 0) ?  'SUCCESS': 'ERROR';
        AMIND_OperationLogUtil.finishLog(this.opLog, result, 'Finished Successfully');
    }    

}
```
# aMind Operation Logger
This Utility exposes fields and methods that can be utilized by other Apex Classes to create Persistent Logs of type Error or Information as opposed to native Debug Logs. 

# link for unmanaged package

## Developer Edition
https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1v000002KQ3Z

## Sandbox
https://test.salesforce.com/packaging/installPackage.apexp?p0=04t1v000002KQ3Z

For Production recomendation is to use change sets instead of unmanaged package

# Examples
## Error case. Divide by 0
```javascript
global class TestOperationLogBatch implements Database.Batchable<sObject>, Database.stateful {

    //The class must implement Database.statful in order to share variable between transactions

    //Initialize Log object to track events
    private AMIND_OperationLogUtil.Log opLog = 
      new AMIND_OperationLogUtil.Log('TestOperationLogBatch', 'BatchApex');

    global Database.QueryLocator start(Database.BatchableContext BC){

      //Set execution date and save log in DB
      this.opLog.ExecuteDate = Datetime.now();
      this.opLog.id = AMIND_OperationLogUtil.addLog(this.opLog);
      return Database.getQueryLocator('SELECT Id FROM Account');
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){

      try {
        for(Account account : scope) {
          //append Notes, you can use this function when you want to save event in the log
          this.opLog.appendNotes(AMIND_OperationLogUtil.getURL(account.Id) +' test');
          //Divide by zero is not allowed so this will throw exception which will gonna be
          //saved in Operation Log object and FailureCount will be increased
          Integer test = 1/0;
          //Count successfully processed items
          this.opLog.ItemsProcessed++;
        }
        
      } catch (Exception ex) {
        //Count failed items
        this.opLog.FailureCount++;
        //Save log with latest updates
        AMIND_OperationLogUtil.finishLog(this.opLog, 'ERROR', 'ERROR:'+ex.getMessage());
      }

    }
    
    global void finish(Database.BatchableContext BC){
      String result = (this.opLog.FailureCount == 0) ?  'SUCCESS': 'ERROR';
      AMIND_OperationLogUtil.finishLog(this.opLog, result, 'Finished Successfully');
    }
}
```
## Success case.
```javascript
global class TestOperationLogBatch implements Database.Batchable<sObject>, Database.stateful {

    //The class must implement Database.statful in order to share variable between transactions

    //Initialize Log object to track events
    private AMIND_OperationLogUtil.Log opLog = 
      new AMIND_OperationLogUtil.Log('TestOperationLogBatch', 'BatchApex');

    global Database.QueryLocator start(Database.BatchableContext BC){

      //Set execution date and save log in DB
      this.opLog.ExecuteDate = Datetime.now();
      this.opLog.id = AMIND_OperationLogUtil.addLog(this.opLog);
      return Database.getQueryLocator('SELECT Id FROM Account');
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){

      try {
        for(Account account : scope) {
          //append Notes, you can use this function when you want to save event in the log
          this.opLog.appendNotes(AMIND_OperationLogUtil.getURL(account.Id) +' test');
          
          //Count successfully processed items
          this.opLog.ItemsProcessed++;
        }
        
      } catch (Exception ex) {
        //Count failed items
        this.opLog.FailureCount++;
        //Save log with latest updates
        AMIND_OperationLogUtil.finishLog(this.opLog, 'ERROR', 'ERROR:'+ex.getMessage());
      }

    }
    
    global void finish(Database.BatchableContext BC){
      String result = (this.opLog.FailureCount == 0) ?  'SUCCESS': 'ERROR';
      AMIND_OperationLogUtil.finishLog(this.opLog, result, 'Finished Successfully');
    }
}
```
## Trigger on Error or Success
```javascript
trigger testOperationLog on AMIND_Operation_log__c (after update) {
    AMIND_Operation_Log opLog = trigger.new[0];
    if(opLog.AMIND_Result__c == 'ERROR') { //OR 'SUCCESS'
        //do something
    }
}
```
## Log Hierarchy
Avoid use of hierarchy logs frequently, it consume DML operations;
```javascript
global class TestOperationLogBatch implements Database.Batchable<sObject>, Database.stateful {

    //The class must implement Database.statful in order to share variable between transactions

    //Initialize Log object to track events
    private AMIND_OperationLogUtil.Log opLog = 
      new AMIND_OperationLogUtil.Log('TestOperationLogBatch', 'BatchApex');

    global Database.QueryLocator start(Database.BatchableContext BC){

      //Set execution date and save log in DB
      this.opLog.ExecuteDate = Datetime.now();
      this.opLog.id = AMIND_OperationLogUtil.addLog(this.opLog);
      return Database.getQueryLocator('SELECT Id FROM Account');
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
      //append Notes, you can use this function when you want to save event in the log
      this.opLog.appendNotes('Transaction');

      AMIND_OperationLogUtil.Log childOpLog = 
        new AMIND_OperationLogUtil.Log('TestOperationLogBatch-child', 'BatchApex');
      childOpLog.Start = Datetime.now();
      childOpLog.ExecuteDate = Datetime.now();

      //assign parent log
      childOpLog.parentLog = this.opLog.Id;
      childOpLog.id = AMIND_OperationLogUtil.addLog(childOpLog);

      try {

        for(Account account : scope) {
          //append Notes, you can use this function when you want to save event in the log
          childOpLog.appendNotes(AMIND_OperationLogUtil.getURL(account.Id));

          //Count successfully processed items
          childOpLog.ItemsProcessed++;
          this.opLog.ItemsProcessed++;
        }
        childOpLog.Result = 'SUCCESS';
        childOpLog.Stop = Datetime.now();
        AMIND_OperationLogUtil.updateLog(childOpLog);
        
      } catch (Exception ex) {
        //Count failed items
        childOpLog.FailureCount++;
        this.opLog.FailureCount++;
        //Save log with latest updates
        AMIND_OperationLogUtil.finishLog(childOpLog, 'ERROR', 'ERROR:'+ex.getMessage());
      }

    }
    
    global void finish(Database.BatchableContext BC){
      String result = (this.opLog.FailureCount == 0) ?  'SUCCESS': 'ERROR';
      AMIND_OperationLogUtil.finishLog(this.opLog, result, 'Finished Successfully');
    }
}
```
