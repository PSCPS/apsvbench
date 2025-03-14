
/*------------------------------------------------------------------------
    File        : startgatherstats.p
    Purpose     : Call the appserver to finish stats collection

    Syntax      :

    Description :     

    Author(s)   : S.E. Southwell
    Created     : 2025-03-13
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE iSeconds AS INTEGER NO-UNDO.
DEFINE VARIABLE hSrv     AS HANDLE  NO-UNDO. 
DEFINE VARIABLE fCPU     AS DECIMAL NO-UNDO.
DEFINE VARIABLE fMem     AS DECIMAL NO-UNDO.
DEFINE VARIABLE fSwap    AS DECIMAL NO-UNDO.
    
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
ASSIGN
    iSeconds = INTEGER(SESSION:PARAMETER)
    NO-ERROR.
IF iSeconds = 0 THEN iSeconds = 20.

CREATE SERVER hSrv.
IF hSrv:CONNECT(OS-GETENV("APSVCONNECTSTRING"))
    THEN DO:
    RUN apsv/gatherstats.p ON hSrv (INPUT iSeconds, OUTPUT fCPU, OUTPUT fMem, OUTPUT fSwap).
END.
ELSE MESSAGE "FAILED TO CONNECT".
CATCH e AS Progress.Lang.Error :
    MESSAGE e:GetMessage(1).        
END CATCH.
FINALLY:
    MESSAGE SUBSTITUTE(" CPU Usage: &1%",STRING(fCPU,">>9.99")).
    MESSAGE SUBSTITUTE(" MEM Usage: &1%",STRING(fMem,">>9.99")).
    MESSAGE SUBSTITUTE("Swap Usage: &1%",STRING(fSwap,">>9.99")).
    hSrv:DISCONNECT().
    QUIT.
END FINALLY.
