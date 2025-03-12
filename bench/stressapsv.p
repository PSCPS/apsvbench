
/*------------------------------------------------------------------------
    File        : stressapsv.p
    Purpose     : Stress-test an APSV with continual calls

    Syntax      :

    Description :     

    Author(s)   : S.E. Southwell
    Created     : Wed Mar 05 15:24:21 CST 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE iThreadNum AS INTEGER NO-UNDO.
DEFINE VARIABLE fMaxCalls  AS INTEGER NO-UNDO.
DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
DEFINE VARIABLE hSrv AS HANDLE NO-UNDO.
DEFINE VARIABLE fMin AS DECIMAL INIT ? NO-UNDO.
DEFINE VARIABLE fMax AS DECIMAL NO-UNDO.
DEFINE VARIABLE fAvg AS DECIMAL DECIMALS 2 NO-UNDO.
DEFINE VARIABLE iStartTime AS INTEGER NO-UNDO.
DEFINE VARIABLE fElapsed AS DECIMAL NO-UNDO.
DEFINE VARIABLE fThisTime AS DECIMAL NO-UNDO.
DEFINE VARIABLE hTT AS HANDLE NO-UNDO.

//DEFINE TEMP-TABLE ttCustomer NO-UNDO LIKE Customer.
{bench/ttObs.i}
    
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
ASSIGN
    iThreadNum = INTEGER(ENTRY(1,SESSION:PARAMETER,":"))
    fMaxCalls = INTEGER(ENTRY(2,SESSION:PARAMETER,":")) 
        WHEN NUM-ENTRIES(SESSION:PARAMETER,":") > 1
    NO-ERROR.
IF fMaxCalls = 0 THEN fMaxCalls = 100.

iStartTime = MTIME.
DO iCount = 1 TO  fMaxCalls ON ERROR UNDO, THROW:
    ETIME(YES).
    CREATE SERVER hSrv.
    IF hSrv:CONNECT(OS-GETENV("APSVCONNECTSTRING"))
        THEN DO:
        RUN apsv/testproc.p ON hSrv (INPUT "S*", OUTPUT TABLE-HANDLE hTT).
    END.
    ELSE MESSAGE "FAILED TO CONNECT" iCount.
    FINALLY:
        hSrv:DISCONNECT().
        fThisTime = ETIME / 1000 .
        CREATE ttObs.
        ASSIGN
            ttObs.obsId = iCount
            ttObs.runtime = fThisTime.
    END FINALLY.
END.  

FOR EACH ttObs:
    MESSAGE SUBSTITUTE("OBSV:&1",ttObs.runtime).
        fElapsed = fElapsed + ttObs.runtime.
        IF fMin = ? OR ttObs.runtime < fMin THEN fMin = ttObs.runtime.
        IF ttObs.runtime > fMax THEN fMax = ttObs.runtime.     
END.  
ASSIGN
    iCount = iCount - 1
//    fElapsed = (MTIME - iStartTime) / 1000
    fAvg = fElapsed / iCount.

MESSAGE SUBSTITUTE("Thread#:&1", iThreadNum).
MESSAGE SUBSTITUTE("Calls:&1", iCount).
MESSAGE SUBSTITUTE("ELAPSED:&1",fElapsed).
MESSAGE SUBSTITUTE("AVG: &1",fAvg).
MESSAGE SUBSTITUTE("MIN: &1",fMin).
MESSAGE SUBSTITUTE("MAX: &1",fMax).
FINALLY:
    MESSAGE "done".
END FINALLY.