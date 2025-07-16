
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
    FIELD ABLAppName      AS CHARACTER LABEL "ABL Appname" FORMAT "X(15)"
    FIELD TestDateTime    AS DATETIME LABEL "Tested on"
    FIELD TotalElapsed    AS DECIMAL LABEL "Tot. Runtime"
    FIELD NumThreads      AS INTEGER LABEL "Cli. Threads"
    FIELD TotalCalls      AS INTEGER LABEL "Samples"
    FIELD AvgCall         AS DECIMAL LABEL "Avg Call" FORMAT ">9.999"
    FIELD MinCall         AS DECIMAL LABEL "Min Call" FORMAT ">9.999" INIT ?
    FIELD MaxCall         AS DECIMAL LABEL "Max Call" FORMAT ">9.999"   
    FIELD StdDev          AS DECIMAL LABEL "Std Dev"   FORMAT ">9.999"
    FIELD Median          AS DECIMAL LABEL "Median"    FORMAT ">9.999"
    FIELD Skewness        AS DECIMAL LABEL "Skewness"  FORMAT "->9.999"
    FIELD ThroughPut      AS DECIMAL LABEL "Throughput"
    FIELD CoeffVariation  AS DECIMAL LABEL "CoeffVar" FORMAT "->9.999"
    FIELD IQR             AS DECIMAL LABEL "IQR" FORMAT ">9.999"
    FIELD CI95            AS DECIMAL LABEL "CI 95%" FORMAT ">9.999"
    FIELD P90             AS DECIMAL LABEL "P90" FORMAT ">9.999"
    FIELD P95             AS DECIMAL LABEL "P95" FORMAT ">9.999"
    // Server-side stats 
    FIELD CPUPercent      AS DECIMAL LABEL "CPU Usage"   FORMAT ">9.99%"
    FIELD MemPercent      AS DECIMAL LABEL "MEM Usage"   FORMAT ">9.99%"
    FIELD SwapPercent     AS DECIMAL LABEL "Swap Usage"  FORMAT ">9.99%"
    FIELD AgentsRunning   AS INTEGER LABEL "APSV Agents Running"
    FIELD SessionsRunning AS INTEGER LABEL "APSV Sessions Running"
    FIELD Requests        AS INTEGER LABEL "Requests"
    FIELD MaxConcurrent   AS INTEGER LABEL "Max Concurrent"
    FIELD ResAblSessWaits AS INTEGER LABEL "Sess. Waits"
    FIELD ResAblSessTO    AS INTEGER LABEL "Sess. Timeouts"
    FIELD ErrorCount      AS INTEGER LABEL "Errors"
    .
    