
/*------------------------------------------------------------------------
    File        : rungetagentsessions.p
    Purpose     : Call the appserver to get agents/sessions config

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
DEFINE VARIABLE cApsvConnectString AS CHARACTER NO-UNDO.
    
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

// Build Query for agents
oJMXQuery = NEW JsonObject().
oJMXM = NEW JsonArray().
oJMXQuery:Add("O","PASOE:type=OEManager,name=AgentManager").
oJMXM:Add("getAgentSessions").
oJMXM:Add(OS-GETENV("ABLAPPNAME")).
oJMXQuery:Add("M",oJMXM).

ASSIGN
    cApsvConnectString =  OS-GETENV("APSVCONNECTSTRING").

// Run the query on the server
CREATE SERVER hSrv.
IF hSrv:CONNECT(cApsvConnectString)
    THEN DO:
    RUN apsv/executejmx.p ON hSrv (INPUT oJMXQuery, OUTPUT oJMXOut).
END.
ELSE MESSAGE "FAILED TO CONNECT".

// Now parse the results
iAgentcount = oJMXOut:GetJsonObject("getAgentSessions"):GetJsonArray("agents"):Length.
IF iAgentCount > 0 THEN
DO iCount = 1 TO iAgentCount:
    iSessionCount = iSessionCount + oJMXOut:GetJsonObject("getAgentSessions"):GetJsonArray("agents"):GetJsonObject(iCount):GetJsonArray("sessions"):Length.
END.    

MESSAGE SUBSTITUTE("        APSV Agents Running: &1",STRING(iAgentCount,">>9")).
MESSAGE SUBSTITUTE("      APSV Sessions Running: &1",STRING(iSessionCount,">>9")).


CATCH e AS Progress.Lang.Error :
    MESSAGE e:GetMessage(1).        
END CATCH.
FINALLY:
    DELETE OBJECT oJMXQuery NO-ERROR.
    DELETE OBJECT oJMXM     NO-ERROR.
    DELETE OBJECT oJMXOut   NO-ERROR.
    hSrv:DISCONNECT().
END FINALLY.
