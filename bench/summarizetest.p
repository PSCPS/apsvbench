
/*------------------------------------------------------------------------
    File        : summarizetest.p
    Purpose     : 

    Syntax      :

    Description : Analyze log files

    Author(s)   : S.E. Southwell - Progress
    Created     : Thu Mar 06 13:56:37 CST 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.
{bench/ttObs.i}

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
DEFINE VARIABLE iCount        AS INTEGER   NO-UNDO.
DEFINE VARIABLE iNumThreads   AS INTEGER   NO-UNDO.
DEFINE VARIABLE cTextIn       AS CHARACTER NO-UNDO.
DEFINE VARIABLE iTotalCalls   AS INTEGER   NO-UNDO.
DEFINE VARIABLE fTotalElapsed AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fAvgCall      AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fMinCall      AS DECIMAL INIT ? NO-UNDO.
DEFINE VARIABLE fMaxCall      AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fThisNum      AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fThroughput   AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fSquaredDevs  AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fStdDev       AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fSkewness     AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fSumCube      AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fMedian       AS DECIMAL   NO-UNDO.

iNumThreads = INTEGER(SESSION:PARAMETER).
IF iNumThreads = 0 THEN iNumThreads = 5.

DO iCount = 1 TO iNumThreads:
    INPUT FROM VALUE (SUBSTITUTE("&1\results\log_&2.txt",OS-GETENV("APSVBENCH"),iCount)).
    REPEAT ON ENDKEY UNDO, LEAVE:
        IMPORT UNFORMATTED cTextIn.
        IF cTextIn MATCHES "OBSV:*"
            THEN DO:
            CREATE ttObs.
            ASSIGN 
                iTotalCalls += 1
                ttObs.obsId = iTotalCalls
                ttObs.runtime = DECIMAL(ENTRY(2,cTextIn,":"))
                fTotalElapsed += ttObs.runtime
                fMaxCall = MAX(fMaxCall,ttObs.runtime).
            IF fMinCall = ? THEN fMinCall = ttObs.runtime.
            ELSE fMinCall = MIN(ttObs.runtime,fMinCall).      
              
        END.
    END.
    INPUT CLOSE.
END. 
ASSIGN
    fAvgCall = fTotalElapsed / iTotalCalls
    fThroughPut = iTotalCalls / (fTotalElapsed / iNumThreads).

// Calc std. dev and skewness
FOR EACH ttObs BY ttObs.runtime:
    ASSIGN
        iCount = iCount + 1
        fMedian = ttObs.runtime WHEN iCount = iTotalCalls / 2
        fMedian = fMedian + ttObs.runtime / 2 WHEN (iCount - .5 = iTotalCalls / 2)
        fMedian = fMedian + ttObs.runtime / 2 WHEN (iCount + .5 = iTotalCalls / 2)
        fSquaredDevs += EXP(ttObs.runtime - fAvgCall,2).
        fSumCube = fSumCube + EXP(ttObs.runtime - fAvgCall,3).
END.
fStdDev = SQRT(fSquaredDevs / iTotalCalls).

IF iTotalCalls > 2 AND fStdDev NE 0 THEN
    fSkewness = (iTotalCalls / ((iTotalCalls - 1) * (iTotalCalls - 2))) * (fSumCube / EXP(fStdDev,3)).
ELSE 
    fSkewness = 0.

MESSAGE SKIP "Summarizing Results".
DISPLAY 
    fTotalElapsed LABEL "Total Runtime"
    iNumThreads   LABEL "Client Threads"
    iTotalCalls   LABEL "Samples"
    fAvgCall      LABEL "Avg Call (sec)" FORMAT ">9.999"
    fMinCall      LABEL "Min Call (sec)" FORMAT ">9.999"
    fMaxCall      LABEL "Max Call (sec)" FORMAT ">9.999"
    fMedian       LABEL "Median (sec)" FORMAT ">9.999"
    fStdDev       LABEL "Std. Dev."
    fSkewness     LABEL "Skewness"
    fThroughPut   LABEL "Throughput / sec"
    WITH 1 COL.

IF OS-GETENV("HIST_SHOWHISTOGRAM") = "TRUE" THEN RUN showHistogram.   

MESSAGE SKIP "Server-side statistics:".
RUN VALUE(OS-GETENV("APSVBENCH") + "/bench/rungatherstats.p").    
RUN VALUE(OS-GETENV("APSVBENCH") + "/bench/rungetagentsessions.p").    
RUN VALUE(OS-GETENV("APSVBENCH") + "/bench/rungetmetrics.p").    

PROCEDURE showHistogram:
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
        iBarScale = MIN (10 * iBucketCount,iTotalCalls).
    END.
    
    IF cRangeType = "auto" THEN DO:
        ASSIGN
            fRange = fMaxCall - fMinCall
            fSlice = fRange / iBucketCount
            fHistLowRange = fMinCall.
    END.
    IF cRangeType = "fixed" THEN DO:
        ASSIGN
            fHistLowRange = DECIMAL(OS-GETENV("HIST_LOWRANGE"))
            fSlice = DECIMAL(OS-GETENV("HIST_BUCKETSIZE")).
    END.
        
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
    iCountPerStar = INTEGER(iTotalcalls / iBarscale).
    
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
        IF ttBucket.lowValue <= fMedian AND ttBucket.highValue >= fMedian
            THEN cHist = cHist + SUBSTITUTE(" (med=&1) ",TRIM(STRING(fMedian,">9.999"))).
        
        // Mark the average
        IF ttBucket.lowValue <= fAvgCall AND ttBucket.highValue >= fAvgCall
            THEN cHist = cHist + SUBSTITUTE(" (avg=&1) ",TRIM(STRING(fAvgCall,">9.999"))).
        
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
