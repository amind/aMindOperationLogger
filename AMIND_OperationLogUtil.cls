global with sharing class AMIND_OperationLogUtil {


  global class Log {
        
    public ID id { get; set; }
    public String Name { get; set; }
    public String Type { get; set; }
    public Datetime Start { get; set; }
    public Datetime Stop { get; set; }
    public Datetime ExecuteDate { get; set; }
    public String Status { get; set; }
    public String Scope { get; set; }
    public Integer ItemsProcessed { get; set; }
    public Integer FailureCount { get; set; }
    public String Result { get; set; }
    public String Notes { get; set; }
    
    public Log(String name, String jobType) {
        Datetime now = Datetime.now();
        this.Name = name;
        this.Type = jobType;
        this.Start = now;
        this.ItemsProcessed = 0;
        this.FailureCount = 0;
        this.Notes = '';
        this.Status = 'PROCESSING';
    }

    public void appendNotes(String note) {
      this.Notes += '<br/>' + note;
    }
    
    public AMIND_Operation_Log__c transform() {
        return new AMIND_Operation_Log__c (
            Id = this.id,
            Name = this.Name,
            AMIND_Type__c = this.Type,
            AMIND_Start_Date__c = this.Start,
            AMIND_Execute_Date__c = this.ExecuteDate,
            AMIND_End_Date__c = this.Stop,
            AMIND_Items_Processed__c = this.ItemsProcessed,
            AMIND_Failure_Count__c = this.FailureCount,
            AMIND_Result__c = this.Result,
            AMIND_Status__c = this.Status,
            AMIND_Notes__c = this.Notes
        );
    }

  }

  public static Id addLog(Log opLog) {
    AMIND_Operation_Log__c opLogObj = opLog.transform();
    insert opLogObj;
    return opLogObj.Id;
  }

  public static void updateLog(Log opLog) {
    AMIND_Operation_Log__c opLogObj = opLog.transform();
    update opLogObj;
  }

  public static void finishLog(Log opLog, String result, String notes) {
    opLog.Stop = datetime.now();
    opLog.Result = result;
    opLog.Status = 'COMPLETE';
    opLog.Notes += '<br/>' + notes;

    updateLog(opLog);
  }

  public static String getUrl(Id id) {
    String baseUrl = System.URL.getSalesforceBaseURL().toExternalForm();
    return '<a href="' + baseUrl + '/' + id + '" target="_blank"> ' + id + ' </a>';
  }
}