
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
DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
DEFINE VARIABLE iNumThreads AS INTEGER NO-UNDO.
DEFINE VARIABLE cTextIn AS CHARACTER NO-UNDO.
DEFINE VARIABLE iTotalCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE fTotalElapsed AS DECIMAL NO-UNDO.
DEFINE VARIABLE fAvgCall AS DECIMAL NO-UNDO.
DEFINE VARIABLE fMinCall AS DECIMAL INIT ? NO-UNDO.
DEFINE VARIABLE fMaxCall AS DECIMAL NO-UNDO.
DEFINE VARIABLE fThisNum AS DECIMAL NO-UNDO.
DEFINE VARIABLE fThroughput AS DECIMAL NO-UNDO.
DEFINE VARIABLE fSquaredDevs AS DECIMAL NO-UNDO.
DEFINE VARIABLE fStdDev AS DECIMAL NO-UNDO.

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

// Calc std. dev
FOR EACH ttObs:
    fSquaredDevs += EXP(ttObs.runtime - fAvgCall,2).
END.
fStdDev = SQRT(fSquaredDevs / iTotalCalls).

DISPLAY 
    fTotalElapsed LABEL "Total Runtime"
    iNumThreads LABEL "Thread Count"
    iTotalCalls LABEL "Samples"
    fAvgCall LABEL "Avg Call (sec)"
    fMinCall LABEL "Min Call (sec)"
    fMaxCall LABEL "Max Call (sec)"
    fStdDev LABEL "Std. Dev."
    fThroughPut LABEL "Throughput / sec"
    WITH 1 COL.
   
// Get the data in buckets to make a histogram
DEFINE VARIABLE iBucketCount AS INTEGER NO-UNDO INIT 10.
DEFINE VARIABLE iBucketNum   AS INTEGER NO-UNDO.
DEFINE VARIABLE fRange       AS DECIMAL NO-UNDO.
DEFINE VARIABLE fSlice       AS DECIMAL NO-UNDO.
DEFINE VARIABLE iBarScale    AS INTEGER NO-UNDO INIT 80.
DEFINE VARIABLE cHist        AS CHARACTER NO-UNDO.
DEFINE VARIABLE iNumEq       AS INTEGER NO-UNDO.



ASSIGN
    fRange = fMaxCall - fMinCall
    fSlice = fRange / iBucketCount
    iBarScale = MIN (iBarScale,iTotalCalls).
    
DO iBucketNum = 1 TO iBucketCount:
    CREATE ttBucket.
    ASSIGN
        ttBucket.BucketId = iBucketNum
        ttBucket.lowValue = fMinCall + (fSlice * (iBucketNum - 1))
        ttBucket.highValue = ttBucket.lowValue + fSlice.
    FOR EACH ttObs
        WHERE ttObs.runtime >= ttBucket.lowValue
        AND ttObs.runtime < ttBucket.highValue:
        ASSIGN ttBucket.obscount += 1.
    END.
    IF iBucketNum = iBucketCount 
        THEN FOR EACH ttObs
        WHERE ttObs.runtime = ttBucket.highValue:
        ASSIGN ttBucket.obscount += 1.
    END.
END.

// Draw a simple histogram
MESSAGE "Timing histogram:".
FOR EACH ttBucket:
    ASSIGN
        iNumEq = INTEGER(iBarScale * ttBucket.obsCount / iTotalCalls).
        IF iNumEq > 0 THEN cHist = FILL("*",iNumEq).
        ELSE IF ttBucket.obsCount > 0 THEN cHist = ".".
        ELSE cHist = "".
    IF ttBucket.bucketID < iBucketCount THEN    
        MESSAGE SUBSTITUTE ("&1 <= x <  &2: &3 &4",
            STRING(ttBucket.lowValue,"Z9.999"),
            STRING(ttBucket.highValue,"Z9.999"),
            STRING(ttBucket.obsCount,"Z,ZZ9"),
            cHist).
    ELSE
        MESSAGE SUBSTITUTE ("&1 <= x <= &2: &3 &4",
            STRING(ttBucket.lowValue,"Z9.999"),
            STRING(ttBucket.highValue,"Z9.999"),
            STRING(ttBucket.obsCount,"Z,ZZ9"),
            cHist).
    
END.    
    