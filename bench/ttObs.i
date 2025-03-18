
/*------------------------------------------------------------------------
    File        : ttObs.i
    Purpose     : Temp-table definitions for benchmarking stats

    Syntax      :

    Description : 

    Author(s)   : S.E. Southwell - Progress
    Created     : Wed Mar 12 08:42:02 CDT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE TEMP-TABLE ttObs NO-UNDO
    FIELD obsId   AS INTEGER
    FIELD runtime AS DECIMAL
    INDEX pkobsid IS PRIMARY UNIQUE obsid.

    
DEFINE TEMP-TABLE ttBucket NO-UNDO
    FIELD bucketID AS INTEGER
    FIELD lowValue AS DECIMAL FORMAT ">>>9.999"
    FIELD highValue AS DECIMAL FORMAT ">>>9.999"
    FIELD obscount AS INTEGER FORMAT ">>>,>>9"
    INDEX pkbucketId IS PRIMARY UNIQUE bucketid.

// Future - lets get all this into a table so we can export it    
DEFINE TEMP-TABLE ttTestRun NO-UNDO
    FIELD TotalElapsed    AS DECIMAL LABEL "Total Runtime"
    FIELD NumThreads      AS INTEGER LABEL "Client Threads"
    FIELD TotalCalls      AS INTEGER LABEL "Samples"
    FIELD AvgCall         AS DECIMAL LABEL "Avg Call (sec)"
    FIELD MinCall         AS DECIMAL LABEL "Min Call (sec)" 
    FIELD MaxCall         AS DECIMAL LABEL "Max Call (sec)"   
    FIELD StdDev          AS DECIMAL LABEL "Std Dev"
    FIELD Skewness        AS DECIMAL LABEL "Skewness"
    FIELD ThroughPut      AS DECIMAL LABEL "Throughput"
    // Server-side stats 
    FIELD CPUPercent      AS DECIMAL LABEL "CPU Usage"
    FIELD MemPercent      AS DECIMAL LABEL "MEM Usage"
    FIELD SwapPercent     AS DECIMAL LABEL "Swap Usage"
    FIELD AgentsRunning   AS INTEGER LABEL "APSV Agents Running"
    FIELD SessionsRunning AS INTEGER LABEL "APSV Sessions Running"
    FIELD Requests        AS INTEGER LABEL "Requests"
    FIELD MaxConcurrent   AS INTEGER LABEL "Max Concurrent"
    FIELD ResAblSessWaitS AS INTEGER LABEL "Reserve ABL Sess Waits"
    FIELD ResAblSessTO    AS INTEGER LABEL "Reserve ABL Sess Timeouts"
    
    .
    