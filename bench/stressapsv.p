
/*------------------------------------------------------------------------
    File        : stressapsv.p
    Purpose     : Stress-test an APSV with continual calls

    Syntax      :

    Description : Setup your tests here in the doTest procedure if you need
                  to try different things    

    Author(s)   : S.E. Southwell
    Created     : Wed Mar 05 15:24:21 CST 2025
    Notes       :
    To Do       : Add better error handling
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE iThreadNum   AS INTEGER   NO-UNDO.
DEFINE VARIABLE fMaxCalls    AS INTEGER   NO-UNDO.
DEFINE VARIABLE iCount       AS INTEGER   NO-UNDO.
DEFINE VARIABLE hSrv         AS HANDLE    NO-UNDO.
DEFINE VARIABLE fMin         AS DECIMAL INIT ? NO-UNDO.
DEFINE VARIABLE fMax         AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fAvg         AS DECIMAL DECIMALS 2 NO-UNDO.
DEFINE VARIABLE iStartTime   AS INTEGER   NO-UNDO.
DEFINE VARIABLE fElapsed     AS DECIMAL   NO-UNDO.
DEFINE VARIABLE fThisTime    AS DECIMAL   NO-UNDO.
DEFINE VARIABLE hTT          AS HANDLE    NO-UNDO.
DEFINE VARIABLE cApsvConnect AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTestID      AS CHARACTER NO-UNDO.

    
/* ********************  Preprocessor Definitions  ******************** */
{bench/ttObs.i}


/* ***************************  Main Block  *************************** */

ASSIGN
    cApsvConnect =  OS-GETENV("APSVCONNECTSTRING")
    iThreadNum = INTEGER(ENTRY(1,SESSION:PARAMETER,":"))
    fMaxCalls = INTEGER(ENTRY(2,SESSION:PARAMETER,":")) 
        WHEN NUM-ENTRIES(SESSION:PARAMETER,":") > 1
    cTestId = ENTRY(3,SESSION:PARAMETER,":")
        WHEN NUM-ENTRIES(SESSION:PARAMETER,":") > 2
    NO-ERROR.
    
IF fMaxCalls = 0 THEN fMaxCalls = 1.

RUN primePump. // Prepare to network
RUN doTests.

PROCEDURE doTests:
    MESSAGE "TestId:" cTestId.
    iStartTime = MTIME.
    DO iCount = 1 TO  fMaxCalls ON ERROR UNDO, THROW:
        ETIME(YES).
        CREATE SERVER hSrv.
        IF hSrv:CONNECT(cApsvConnect) THEN DO:
            // Below is an example of how to setup multiple tests that you can specify
            // from the commandline.  Just put a case for each thing you want to try
            CASE cTestId:
                WHEN "a" THEN DO:
                    RUN apsv/testproc.p ON hSrv (INPUT "S*", OUTPUT TABLE-HANDLE hTT).
                END. // A
                WHEN "b" THEN DO:
                    RUN apsv/testproc-oscommand.p ON hSrv (INPUT "S*", OUTPUT TABLE-HANDLE hTT).                    
                END.
                OTHERWISE RUN apsv/testproc.p ON hSrv (INPUT "*", OUTPUT TABLE-HANDLE hTT).
                
            END CASE.
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
    
    CATCH e AS Progress.Lang.Error :
        MESSAGE e:GetMessage(1).
    END CATCH.
    FINALLY:
        IF CAN-FIND(FIRST ttObs) THEN DO:
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
        END.
        MESSAGE "done".
    END FINALLY.
END PROCEDURE. // doTests

// Basically, this primes the pump by handling any sort of DNS or SSL-related delays
// before the clock starts ticking.  It also introduces a very short delay to stagger
// the requests a bit.
PROCEDURE primePump:
    DEFINE VARIABLE fPauseTime   AS DECIMAL NO-UNDO.
    DEFINE VARIABLE hSrv AS HANDLE NO-UNDO.
    // Insert a little pause here so we can stagger the clients a bit and avoid skewing our results
    fPauseTime = ((iThreadNum - 1) * 0.03).
    MESSAGE "pausing:" fPauseTime.
    PAUSE fPauseTime.
    // Connect and disconnect once
    CREATE SERVER hSrv.
    IF hSrv:CONNECT(cApsvConnect) THEN hSrv:DISCONNECT ().    
END PROCEDURE.

