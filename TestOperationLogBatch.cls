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