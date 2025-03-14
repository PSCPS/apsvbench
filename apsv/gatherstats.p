
/*------------------------------------------------------------------------
    File        : gatherstats.p
    Purpose     : APSV call that grabs stats collection after testing

    Syntax      : 

    Description :     

    Author(s)   : S.E. Southwell
    Created     : 2025-03-13
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER iSeconds AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER fCPU AS DECIMAL NO-UNDO.
DEFINE OUTPUT PARAMETER fMem AS DECIMAL NO-UNDO.
DEFINE OUTPUT PARAMETER fSwap AS DECIMAL NO-UNDO.

DEFINE VARIABLE cCatHome  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTextIn   AS CHARACTER NO-UNDO.
DEFINE VARIABLE iStartPos AS INTEGER   NO-UNDO.

DEFINE STREAM OSTREAM.

// Don't leave open-ended
IF NOT iSeconds > 0 THEN iSeconds = 20.
MESSAGE SUBSTITUTE("Gathering server stats collection for &1 seconds.",iSeconds).

cCatHome = OS-GETENV("CATALINA_BASE").

// CPU
INPUT STREAM OSTREAM THROUGH VALUE(SUBSTITUTE("&1/bin/showstats.sh &2 &3",cCatHome,"u",iSeconds)).
REPEAT:
    IMPORT STREAM OSTREAM UNFORMATTED cTextIn.
    // Looking for %idle as the last item
    IF cTextIn MATCHES "Average:*All*" THEN DO:
        fCPU = 100 - DECIMAL(ENTRY(NUM-ENTRIES(cTextin," "),cTextin," ")).
    END.
END.
INPUT STREAM OSTREAM CLOSE.

// MEM
INPUT STREAM OSTREAM THROUGH VALUE(SUBSTITUTE("&1/bin/showstats.sh &2 &3",cCatHome,"r",iSeconds)).
REPEAT:
    IMPORT STREAM OSTREAM UNFORMATTED cTextIn.
    // Parse the 5th thing
    IF cTextIn MATCHES "*%memused*" THEN DO:
        iStartPos = INDEX(cTextin,"%memused").
    END.
    IF cTextIn MATCHES "Average:*" THEN DO:
        fMem = DECIMAL(SUBSTRING(cTextIn,iStartPos,7)).
    END.    
END.
INPUT STREAM OSTREAM CLOSE.

// SWAP
INPUT STREAM OSTREAM THROUGH VALUE(SUBSTITUTE("&1/bin/showstats.sh &2 &3",cCatHome,"S",iSeconds)).
REPEAT:
    IMPORT STREAM OSTREAM UNFORMATTED cTextIn.
    IF cTextIn MATCHES "*%swpused*" THEN DO:
        iStartPos = INDEX(cTextin,"%swpused").
    END.
    IF cTextIn MATCHES "Average:*" THEN DO:
        fSwap = DECIMAL(SUBSTRING(cTextIn,iStartPos,7)).
    END.    
END.
INPUT STREAM OSTREAM CLOSE.
