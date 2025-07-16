/*------------------------------------------------------------------------
    File        : summarizetest.p
    Purpose     : Gather up data about both the tests and how the server responded

    Syntax      :

    Description : Analyze log files

    Author(s)   : S.E. Southwell - Progress
    Created     : Thu Mar 06 13:56:37 CST 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING OpenEdge.Core.Session FROM PROPATH.
USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.
USING Progress.Lang.AppError FROM PROPATH.

/* ********************  Preprocessor Definitions  ******************** */
{bench/ttObs.i}

/* ***************************  Main Block  *************************** */
DEFINE VARIABLE iCount             AS INTEGER   NO-UNDO.
DEFINE VARIABLE cTextIn            AS CHARACTER NO-UNDO.
DEFINE VARIABLE fThisNum           AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fSquaredDevs       AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fSumCube           AS DECIMAL   NO-UNDO.
DEFINE VARIABLE cTestlog           AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAPSVConnectString AS CHARACTER NO-UNDO.
DEFINE VARIABLE hSrv               AS HANDLE    NO-UNDO. 
DEFINE VARIABLE iRepsPerThread     AS INTEGER   NO-UNDO.
DEFINE VARIABLE lDiscardOutliers   AS LOGICAL   NO-UNDO.
DEFINE VARIABLE cDiscardType       AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTrustLevel        AS CHARACTER NO-UNDO.
DEFINE VARIABLE iWarmupRuns        AS INTEGER   NO-UNDO.
DEFINE VARIABLE iThisThreadCount   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iNumToDiscard      AS INTEGER   NO-UNDO.
DEFINE VARIABLE iNumDiscarded      AS INTEGER   NO-UNDO. 
DEFINE VARIABLE fLowerIQRFence     AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fUpperIQRFence     AS DECIMAL   NO-UNDO.

ASSIGN
    cApsvConnectString = OS-GETENV("APSVCONNECTSTRING")
    cDiscardType       = OS-GETENV("DISCARDTYPE")
    lDiscardOutliers   = LOGICAL(OS-GETENV("DISCARDOUTLIERS"))
    iWarmupRuns        = INTEGER(OS-GETENV("WARMUPRUNS"))
    cTestLog           = SUBSTITUTE("&1\results\testlog.csv",OS-GETENV("APSVBENCH")).

RUN initLog.

CREATE ttTestRun.
ASSIGN
    ttTestRun.ABLAppName = OS-GETENV("ABLAPPNAME")      
    ttTestRun.TestDateTime = NOW
    ttTestRun.NumThreads = INTEGER(ENTRY(1,SESSION:PARAMETER,":"))
    iRepsPerThread = INTEGER(ENTRY(2,SESSION:PARAMETER,":"))
    NO-ERROR.
IF ttTestRun.NumThreads = 0 
    OR iRepsPerThread = 0
    THEN UNDO, THROW NEW AppError("The number of threads and reps per thread must be passed in using format N:R as a session parameter.",400).


DO iCount = 1 TO ttTestRun.NumThreads:
    iThisThreadCount = 0.
    INPUT FROM VALUE (SUBSTITUTE("&1\results\log_&2.txt",OS-GETENV("APSVBENCH"),iCount)).
    REPEAT ON ENDKEY UNDO, LEAVE:
        IMPORT UNFORMATTED cTextIn.
        IF cTextIn MATCHES "OBSV:*"
            THEN DO:
            iThisThreadCount += 1.    
            IF iThisThreadCount <= iWarmupRuns THEN NEXT. // Ignore some number of initial requests to "warm up" the server.
            CREATE ttObs.
            ASSIGN 
                ttTestRun.TotalCalls += 1
                ttObs.obsId = ttTestRun.TotalCalls
                ttObs.runtime = DECIMAL(ENTRY(2,cTextIn,":")).
        END.
    END.
    INPUT CLOSE.
    iNumDiscarded += iWarmupRuns.
END.
// Compute InterQuartile Range, P90 and P95 - Use closest integer for N instead of trying to split the difference.
iThisThreadCount = 0.
FOR EACH ttObs BY ttObs.runtime:
    iThisThreadCount += 1.
    IF iThisThreadCount = INTEGER(ttTestRun.TotalCalls / 4) 
        THEN ASSIGN
            fLowerIQRFence = ttObs.runtime
            ttTestRun.IQR = ttObs.runtime. // ~ 25th percentile
    IF iThisThreadCount = INTEGER(3 * ttTestRun.TotalCalls / 4) 
        THEN ASSIGN
            ttTestRun.IQR = ttObs.runtime - ttTestRun.IQR // ~ 75th percentile
            fUpperIQRFence = ttObs.runtime.
    IF iThisThreadCount = INTEGER(ttTestRun.TotalCalls * .9) // 90th percentile
        THEN ttTestRun.P90 = ttObs.runtime.            
    IF iThisThreadCount = INTEGER(ttTestRun.TotalCalls * .95) // 95th percentile
        THEN ttTestRun.P95 = ttObs.runtime.            
END.

// Delete the highest and lowest values, if requested
IF lDiscardOutliers AND cDiscardType MATCHES "PERCENT:*" 
    OR cDiscardType MATCHES "FIXED:*" THEN DO:
    IF cDiscardType MATCHES "PERCENT:*" 
        THEN iNumToDiscard =  INTEGER(INTEGER(ENTRY(2,cDiscardType,":")) * .01 * ttTestRun.TotalCalls).
    ELSE iNumToDiscard = INTEGER(ENTRY(2,cDiscardType,":")).
    PUT UNFORMATTED SKIP(2).
    MESSAGE "Deleting top and bottom outliers." cDiscardType.
    FOR EACH ttObs BY ttObs.runtime iThisThreadCount = 1 TO iNumToDiscard:
//        MESSAGE "Deleting low outlier: " ttObs.runtime.
        DELETE ttObs.
        ASSIGN
            iNumDiscarded += 1
            ttTestRun.TotalCalls -= 1.
    END.
    
    FOR EACH ttObs BY ttObs.runtime DESCENDING iThisThreadCount = 1 TO iNumToDiscard:
//        MESSAGE "Deleting high outlier: " ttObs.runtime.
        DELETE ttObs.
        ASSIGN
            iNumDiscarded += 1
            ttTestRun.TotalCalls -= 1.
    END.
END.

// Delete the highest and lowest values, if requested
IF lDiscardOutliers AND cDiscardType MATCHES "IQR:*" THEN DO:
    fLowerIQRFence = MAXIMUM(0,fLowerIQRFence - (DECIMAL(ENTRY(2,cDiscardType,":")) * ttTestRun.IQR)).
    fUpperIQRFence = fUpperIQRFence + (DECIMAL(ENTRY(2,cDiscardType,":")) * ttTestRun.IQR).
    PUT UNFORMATTED SKIP(2).
    MESSAGE "Deleting outliers:" cDiscardType "Lower fence:" fLowerIQRFence "Upper fence:" fUpperIQRFence.
    FOR EACH ttObs WHERE ttObs.runtime < fLowerIQRFence
        OR ttObs.runtime > fUpperIQRFence:
        MESSAGE "Deleting IQR outlier: " ttObs.runtime.
        DELETE ttObs.
        ASSIGN
            iNumDiscarded += 1
            ttTestRun.TotalCalls -= 1.
    END.
END.
FOR EACH ttObs:
    ASSIGN 
        ttTestRun.TotalElapsed += ttObs.runtime
        ttTestRun.MaxCall = MAX(ttTestRun.MaxCall,ttObs.runtime).
    IF ttTestRun.MinCall = ? THEN ttTestRun.MinCall = ttObs.runtime.
    ELSE ttTestRun.MinCall = MIN(ttObs.runtime,ttTestRun.MinCall).      
END. 
ASSIGN
    ttTestRun.AvgCall = ttTestRun.TotalElapsed / ttTestRun.TotalCalls
    ttTestRun.Throughput = ttTestRun.TotalCalls / (ttTestRun.TotalElapsed / ttTestRun.NumThreads)
    ttTestRun.ErrorCount = (ttTestRun.NumThreads * iRepsPerThread) - ttTestRun.TotalCalls - iNumDiscarded.

// Calc std. dev and skewness
FOR EACH ttObs BY ttObs.runtime:
    ASSIGN
        iCount = iCount + 1
        ttTestRun.Median = ttObs.runtime WHEN iCount = ttTestRun.TotalCalls / 2
        ttTestRun.Median = ttTestRun.Median + ttObs.runtime / 2 WHEN (iCount - .5 = ttTestRun.TotalCalls / 2)
        ttTestRun.Median = ttTestRun.Median + ttObs.runtime / 2 WHEN (iCount + .5 = ttTestRun.TotalCalls / 2)
        fSquaredDevs += EXP(ttObs.runtime - ttTestRun.AvgCall,2).
        fSumCube = fSumCube + EXP(ttObs.runtime - ttTestRun.AvgCall,3).
END.
ASSIGN
    ttTestRun.StdDev = SQRT(fSquaredDevs / ttTestRun.TotalCalls)
    ttTestRun.CoeffVariation = ttTestRun.StdDev / ttTestRun.AvgCall.
IF ttTestRun.CoeffVariation <= 0.0125 THEN cTrustLevel = "Ultra Tight".
ELSE IF ttTestRun.CoeffVariation <= 0.025 THEN cTrustLevel = "Very Tight".
ELSE IF ttTestRun.CoeffVariation <= 0.05 THEN cTrustLevel = "Tight".
ELSE IF ttTestRun.CoeffVariation <= 0.10 THEN cTrustLevel = "Acceptable".
ELSE IF ttTestRun.CoeffVariation <= 0.20 THEN cTrustLevel = "Noisy".
ELSE cTrustLevel = "Too Noisy".

IF ttTestRun.TotalCalls > 2 AND ttTestRun.StdDev NE 0 THEN
    ttTestRun.Skewness = (ttTestRun.TotalCalls / ((ttTestRun.TotalCalls - 1) * (ttTestRun.TotalCalls - 2))) * (fSumCube / EXP(ttTestRun.StdDev,3)).
ELSE 
    ttTestRun.Skewness = 0.
    
// Confidence interval
ttTestRun.CI95 = 1.96 * (ttTestRun.StdDev / SQRT(ttTestRun.TotalCalls)).

MESSAGE SKIP "Summarizing Results".
DEFINE VARIABLE ciformat AS CHARACTER NO-UNDO.
ciformat = ">>9.999".
DISPLAY 
    ttTestRun.TotalElapsed 
    ttTestRun.NumThreads   
    ttTestRun.TotalCalls   
    ttTestRun.AvgCall     
    "+/-" + TRIM(STRING(ttTestRun.CI95,ciformat)) LABEL "95% CI"
    ttTestRun.MinCall     
    ttTestRun.P90
    ttTestRun.P95
    ttTestRun.MaxCall     
    ttTestRun.Median      
    ttTestRun.StdDev      
    ttTestRun.Skewness    
    ttTestRun.Throughput   
    ttTestRun.CoeffVariation
    ttTestRun.IQR
    cTrustLevel FORMAT "X(12)" LABEL "Result Trust"
    WITH 3 COL WIDTH 100 FRAME test.

IF OS-GETENV("HIST_SHOWHISTOGRAM") = "TRUE" 
    AND ttTestRun.TotalCalls > 0
    THEN RUN showHistogram.   

MESSAGE SKIP "Server-side statistics:".
RUN ConnectAPSV.
RUN GatherStats.
RUN GetAgentSessions.
RUN GetMetrics.

DISPLAY 
    ttTestRun.CPUPercent
    ttTestRun.MemPercent
    ttTestRun.SwapPercent
    ttTestRun.AgentsRunning
    ttTestRun.SessionsRunning
    ttTestRun.ABLAppname
    ttTestRun.Requests
    ttTestRun.MaxConcurrent
    ttTestRun.ResAblSessWaits
    ttTestRun.ResAblSessTO
    ttTestRun.ErrorCount
    WITH 3 COL WIDTH 100 FRAME server.

OUTPUT TO VALUE (cTestLog) APPEND.
EXPORT DELIMITER "," ttTestRun.
OUTPUT CLOSE.

FINALLY:
    hSrv:DISCONNECT() NO-ERROR.
END FINALLY.

/* **********************  Internal Procedures  *********************** */
PROCEDURE ConnectAPSV:
/*------------------------------------------------------------------------------
 Purpose: Connect to the appserver to gather info
 Notes:
------------------------------------------------------------------------------*/
    DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
    DO iCount = 1 TO 20 ON ERROR UNDO, NEXT:
        PAUSE 0.05 * iCount.
        CREATE SERVER hSrv.
        IF hSrv:CONNECT(cAPSVConnectString) THEN RETURN.
        CATCH e AS Progress.Lang.Error :
            MESSAGE "apsv connect failed - trying again" iCount.        
        END CATCH.
    END.
    MESSAGE "FAILED TO CONNECT TO APPSERVER FOR STATS".
END PROCEDURE.

PROCEDURE GatherStats:
/*------------------------------------------------------------------------------
 Purpose: Get CPU, Mem, and Swap stats
 Notes:
------------------------------------------------------------------------------*/
    DEFINE VARIABLE iSeconds AS INTEGER NO-UNDO.
    DEFINE VARIABLE fCPU     AS DECIMAL NO-UNDO.
    DEFINE VARIABLE fMem     AS DECIMAL NO-UNDO.
    DEFINE VARIABLE fSwap    AS DECIMAL NO-UNDO.
        
    ASSIGN
        iSeconds = INTEGER(OS-GETENV("SERVERSTATSSECONDS"))
        NO-ERROR.
    IF iSeconds = 0 THEN iSeconds = 20.
    
        RUN apsv/gatherstats.p ON hSrv (INPUT iSeconds, OUTPUT fCPU, OUTPUT fMem, OUTPUT fSwap).
        IF fCPU = 0 AND fMem = 0 AND fSwap = 0 
            THEN DO:
            MESSAGE "**CPU, MEM, Swap are unavailable.  Start bin/sar_startup.sh in instance".
            ASSIGN
                fCPU = ?
                fMem = ?
                fSwap = ?.
            
        END.
        ASSIGN
            ttTestRun.CPUPercent = fCPU
            ttTestRun.MemPercent = fMem
            ttTestRun.SwapPercent = fSwap.
    CATCH e AS Progress.Lang.Error :
        MESSAGE e:GetMessage(1).        
    END CATCH.
    FINALLY:

    END FINALLY.

END PROCEDURE.

PROCEDURE GetAgentSessions:
/*------------------------------------------------------------------------------
 Purpose: Get how many agents the service has, and how many sessions
 Notes:
------------------------------------------------------------------------------*/
    DEFINE VARIABLE iAgentCount   AS INTEGER NO-UNDO.
    DEFINE VARIABLE iSessionCount AS INTEGER NO-UNDO.
    
    DEFINE VARIABLE oJMXQuery AS JsonObject NO-UNDO.
    DEFINE VARIABLE oJMXM     AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oJMXOut   AS JsonObject NO-UNDO.
    DEFINE VARIABLE iCount    AS INTEGER    NO-UNDO.

    // Build Query for agents
    oJMXQuery = NEW JsonObject().
    oJMXM = NEW JsonArray().
    oJMXQuery:Add("O","PASOE:type=OEManager,name=AgentManager").
    oJMXM:Add("getAgentSessions").
    oJMXM:Add(OS-GETENV("ABLAPPNAME")).
    oJMXQuery:Add("M",oJMXM).
    
    
    // Run the query on the server
    RUN apsv/executejmx.p ON hSrv (INPUT oJMXQuery, OUTPUT oJMXOut).
    
    // Now parse the results
    iAgentcount = oJMXOut:GetJsonObject("getAgentSessions"):GetJsonArray("agents"):Length.
    IF iAgentCount > 0 THEN
    DO iCount = 1 TO iAgentCount:
        iSessionCount = iSessionCount + oJMXOut:GetJsonObject("getAgentSessions"):GetJsonArray("agents"):GetJsonObject(iCount):GetJsonArray("sessions"):Length.
    END.    
    
    ASSIGN
        ttTestRun.AgentsRunning = iAgentCount
        ttTestRun.SessionsRunning = iSessionCount.
    
    CATCH e AS Progress.Lang.Error :
        MESSAGE e:GetMessage(1).        
    END CATCH.
    FINALLY:
        DELETE OBJECT oJMXQuery NO-ERROR.
        DELETE OBJECT oJMXM     NO-ERROR.
        DELETE OBJECT oJMXOut   NO-ERROR.
    END FINALLY.
    
END PROCEDURE.

PROCEDURE getMetrics:
/*------------------------------------------------------------------------------
 Purpose: Get metrics from our server
 Notes:
------------------------------------------------------------------------------*/
    DEFINE VARIABLE iAgentCount   AS INTEGER NO-UNDO.
    DEFINE VARIABLE iSessionCount AS INTEGER NO-UNDO.
    
    DEFINE VARIABLE oJMXQuery AS JsonObject NO-UNDO.
    DEFINE VARIABLE oJMXM     AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oJMXOut   AS JsonObject NO-UNDO.
    DEFINE VARIABLE iCount    AS INTEGER    NO-UNDO.
    DEFINE VARIABLE oMetrics  AS JsonObject NO-UNDO.    
    DEFINE VARIABLE cNames    AS CHARACTER  EXTENT NO-UNDO.
    
    // Build Query for agents
    oJMXQuery = NEW JsonObject().
    oJMXM = NEW JsonArray().
    oJMXQuery:Add("O","PASOE:type=OEManager,name=SessionManager").
    oJMXM:Add("getMetrics").
    oJMXM:Add(OS-GETENV("ABLAPPNAME")).
    oJMXQuery:Add("M",oJMXM).
    
    // Run the query on the server
    RUN apsv/executejmx.p ON hSrv (INPUT oJMXQuery, OUTPUT oJMXOut).
    oMetrics = oJMXOut:GetJsonObject("getMetrics").
    
    ASSIGN
        ttTestRun.Requests        = INTEGER(oMetrics:GetCharacter("requests"))
        ttTestRun.MaxConcurrent   = INTEGER(oMetrics:GetCharacter("maxConcurrentClients"))
        ttTestRun.ResAblSessWaits = INTEGER(oMetrics:GetCharacter("numReserveABLSessionWaits"))
        ttTestRun.ResAblSessTO    = INTEGER(oMetrics:GetCharacter("numReserveABLSessionTimeouts")).
        
    CATCH e AS Progress.Lang.Error :
        MESSAGE e:GetMessage(1).        
    END CATCH.
    FINALLY:
        DELETE OBJECT oJMXQuery NO-ERROR.
        DELETE OBJECT oJMXM     NO-ERROR.
        DELETE OBJECT oJMXOut   NO-ERROR.
    END FINALLY.
    
END PROCEDURE.

PROCEDURE InitLog:
/*------------------------------------------------------------------------------
 Purpose: Initialize the log file with header row
 Notes:
------------------------------------------------------------------------------*/
DEFINE VARIABLE hBuf AS HANDLE NO-UNDO.
DEFINE VARIABLE i    AS INTEGER NO-UNDO.
DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.


FILE-INFO:FILE-NAME = cTestLog.
IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
    OUTPUT TO VALUE (cTestLog).
    CREATE BUFFER hBuf FOR TABLE "ttTestRun".
    DO i = 1 TO hBuf:NUM-FIELDS:
        cOut = SUBSTITUTE("&1,&2",cOut,QUOTER(hBuf:BUFFER-FIELD(i):LABEL)).
    END.      
    cOut = TRIM(cOut,",").    
    PUT UNFORMATTED cOut SKIP.
    OUTPUT CLOSE.
END.

END PROCEDURE.

PROCEDURE showHistogram:
/*------------------------------------------------------------------------------
 Purpose: Draw a simple character histogram to illustrate the distributions of timings
 Notes: To do: Consider making this its own generalized class
------------------------------------------------------------------------------*/
    // Get the data in buckets to make a histogram
    DEFINE VARIABLE iBucketCount  AS INTEGER   NO-UNDO INIT 10.
    DEFINE VARIABLE iBucketNum    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE fRange        AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE fSlice        AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE iBarScale     AS INTEGER   NO-UNDO INIT 80.
    DEFINE VARIABLE cHist         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iNumEq        AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cBarscaleType AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cRangeType    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE fHistLowRange AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cHistTemplate AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iCountPerStar AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iModeBucketId AS INTEGER   NO-UNDO.

    // Histogram control
    ASSIGN
        iBucketCount  = INTEGER(OS-GETENV("HIST_NUMBUCKETS")) 
        cBarscaleType = OS-GETENV("HIST_BARSCALE")
        cRangeType    = OS-GETENV("HIST_RANGETYPE")
        NO-ERROR.
    
    IF iBucketCount < 1 THEN iBucketCount = 10.
    
    IF cBarscaleType = "auto" THEN DO:
        iBarScale = MIN (10 * iBucketCount,ttTestRun.TotalCalls).
    END.
    
    IF cRangeType = "auto" THEN DO:
        ASSIGN
            fRange = ttTestRun.MaxCall - ttTestRun.MinCall
            fSlice = fRange / iBucketCount
            fHistLowRange = ttTestRun.MinCall.
    END.
    IF cRangeType = "fixed" THEN DO:
        ASSIGN
            fHistLowRange = DECIMAL(OS-GETENV("HIST_LOWRANGE"))
            fSlice = DECIMAL(OS-GETENV("HIST_BUCKETSIZE")).
    END.
    FIND FIRST ttTestRun.
    ASSIGN iBucketCount = MIN(ttTestRun.TotalCalls,iBucketCount).  // Can't have more buckets than observations.
        
    DO iBucketNum = 1 TO iBucketCount:
        CREATE ttBucket.
        ASSIGN
            ttBucket.BucketId = iBucketNum
            ttBucket.lowValue = fHistLowRange + (fSlice * (iBucketNum - 1))
            ttBucket.highValue = ttBucket.lowValue + fSlice.
        FOR EACH ttObs
            WHERE ttObs.runtime >= ttBucket.lowValue
            AND ttObs.runtime < ttBucket.highValue:
            ASSIGN ttBucket.obscount += 1.
        END.
        IF iBucketNum = iBucketCount 
            THEN FOR EACH ttObs
            WHERE ttObs.runtime >= ttBucket.highValue:
            ASSIGN ttBucket.obscount += 1.
        END.
        IF iBucketNum = 1 
            THEN FOR EACH ttObs
            WHERE ttObs.runtime < ttBucket.lowValue:
            ASSIGN ttBucket.obscount += 1.
        END.     
    END.
    
    // Draw a simple histogram
    iCountPerStar = INTEGER(ttTestRun.TotalCalls / iBarscale).
    
    MESSAGE SKIP SUBSTITUTE("Timing histogram: (@=&1, *=&2, .>=1)",iCountPerStar,iCountPerStar / 2).
    FOR EACH ttBucket BY ttBucket.ObsCount DESCENDING:
        iModeBucketId = ttBucket.bucketID.
        LEAVE.
    END.
    
    FOR EACH ttBucket:
        ASSIGN
            iNumEq = TRUNCATE(ttBucket.obsCount / iCountPerStar,0).
        IF iNumEq > 0 THEN DO:
            cHist = FILL("@",iNumEq).
            IF ttBucket.obsCount MODULO iCountPerStar > iCountPerStar / 2 
                THEN cHist = cHist + "*".
            ELSE IF ttBucket.obsCount MODULO iCountPerStar > 0
                THEN cHist = cHist + ".".
        END.
        ELSE IF ttBucket.obsCount > iCountPerStar / 2 THEN cHist = "*".
        ELSE IF ttBucket.obsCount > 0 THEN cHist = ".".
        ELSE cHist = "".
        
        // Mark the median
        IF ttBucket.lowValue <= ttTestRun.Median AND ttBucket.highValue >= ttTestRun.Median
            THEN cHist = cHist + SUBSTITUTE(" (med=&1) ",TRIM(STRING(ttTestRun.Median,">9.999"))).
        
        // Mark the average
        IF ttBucket.lowValue <= ttTestRun.AvgCall AND ttBucket.highValue >= ttTestRun.AvgCall
            THEN cHist = cHist + SUBSTITUTE(" (avg=&1) ",TRIM(STRING(ttTestRun.AvgCall,">9.999"))).
        
        // Mark the mode
        IF ttBucket.bucketID = iModeBucketId THEN cHist = cHist + " (mode)".
        
        IF cRangeType = "fixed" THEN DO:
        CASE ttBucket.bucketID:
            WHEN 1 
                THEN  cHistTemplate = "      <  &2: &3 |&4".
            WHEN iBucketCount 
                THEN  cHistTemplate = "   > &1:     &3 |&4".
            OTHERWISE cHistTemplate = "&1 - &2: &3 |&4".
        END CASE.
        END.
        ELSE DO: // auto
            cHistTemplate = "&1 - &2: &3 |&4".        
        END.
        MESSAGE SUBSTITUTE (cHistTemplate,
            STRING(ttBucket.lowValue,"Z9.999"),
            STRING(ttBucket.highValue,"Z9.999"),
            STRING(ttBucket.obsCount,"Z,ZZ9"),
            cHist).        
    END.       
END PROCEDURE. // showHistogram
