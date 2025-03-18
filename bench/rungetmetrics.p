
/*------------------------------------------------------------------------
    File        : rungetmetrics.p
    Purpose     : Call the appserver to get the metrics

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
DEFINE VARIABLE oMetrics  AS JsonObject NO-UNDO.    
DEFINE VARIABLE cNames    AS CHARACTER  EXTENT NO-UNDO.
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

// Build Query for agents
oJMXQuery = NEW JsonObject().
oJMXM = NEW JsonArray().
oJMXQuery:Add("O","PASOE:type=OEManager,name=SessionManager").
oJMXM:Add("getMetrics").
oJMXM:Add(OS-GETENV("ABLAPPNAME")).
oJMXQuery:Add("M",oJMXM).


// Run the query on the server
CREATE SERVER hSrv.
IF hSrv:CONNECT(OS-GETENV("APSVCONNECTSTRING"))
    THEN DO:
    RUN apsv/executejmx.p ON hSrv (INPUT oJMXQuery, OUTPUT oJMXOut).
END.
ELSE MESSAGE "FAILED TO CONNECT".
oMetrics = oJMXOut:GetJsonObject("getMetrics").
/*cNames = oMetrics:GetNames().                                         */
/*DO iCount = 1 TO EXTENT (cNames):                                     */
/*    MESSAGE cNames[iCount] ": " oMetrics:GetCharacter(cNames[iCount]).*/
/*END.                                                                  */

MESSAGE 
    "         Metrics for OE app: " OS-GETENV("ABLAPPNAME") SKIP
    "                   Requests: " oMetrics:GetCharacter("requests") SKIP
    "             Max Concurrent: " oMetrics:GetCharacter("maxConcurrentClients") SKIP
    "   Reserve ABLSession Waits: " oMetrics:GetCharacter("numReserveABLSessionWaits") SKIP
    "Reserve ABLSession Timeouts: " oMetrics:GetCharacter("numReserveABLSessionTimeouts") SKIP.
    

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
