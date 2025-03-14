
/*------------------------------------------------------------------------
    File        : runresetmetrics.p
    Purpose     : Call the appserver to get reset the metrics

    Syntax      :

    Description :     

    Author(s)   : S.E. Southwell
    Created     : 2025-03-13
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.
USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.

DEFINE VARIABLE hSrv          AS HANDLE  NO-UNDO. 
DEFINE VARIABLE iAgentCount   AS INTEGER NO-UNDO.
DEFINE VARIABLE iSessionCount AS INTEGER NO-UNDO.

DEFINE VARIABLE oJMXQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE oJMXM     AS JsonArray  NO-UNDO.
DEFINE VARIABLE oJMXOut   AS JsonObject NO-UNDO.
DEFINE VARIABLE iCount    AS INTEGER    NO-UNDO.
    
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

// Build Query for agents
oJMXQuery = NEW JsonObject().
oJMXM = NEW JsonArray().
oJMXQuery:Add("O","PASOE:type=OEManager,name=SessionManager").
oJMXM:Add("resetMetrics").
oJMXM:Add(SESSION:PARAMETER).
oJMXQuery:Add("M",oJMXM).


// Run the query on the server
CREATE SERVER hSrv.
IF hSrv:CONNECT(OS-GETENV("APSVCONNECTSTRING"))
    THEN DO:
    RUN apsv/executejmx.p ON hSrv (INPUT oJMXQuery, OUTPUT oJMXOut).
END.
ELSE MESSAGE "FAILED TO CONNECT".
MESSAGE "Metrics reset for OE app:" SESSION:PARAMETER.

CATCH e AS Progress.Lang.Error :
    MESSAGE e:GetMessage(1).        
END CATCH.
FINALLY:
    DELETE OBJECT oJMXQuery NO-ERROR.
    DELETE OBJECT oJMXM     NO-ERROR.
    DELETE OBJECT oJMXOut   NO-ERROR.
    hSrv:DISCONNECT().
    QUIT.
END FINALLY.
