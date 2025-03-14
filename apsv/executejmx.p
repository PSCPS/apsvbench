
/*------------------------------------------------------------------------
    File        : executejmx.p
    Purpose     : APSV call that executes an arbitrary JMX query

    Syntax      : Pass in a JMX Query JSON
                  Receive output in JSON format.
                  
                  Reference:
                  https://docs.progress.com/bundle/pas-for-openedge-reference/page/OEJMX-Query-Reference.html

    Description :     

    Author(s)   : S.E. Southwell
    Created     : 2025-03-13
    Notes       : THIS COULD BE POTENTIALLY DANGEROUS TO EXPOSE IF YOUR APPSERVER 
                  IS OPEN.  EITHER ENSURE THAT YOU HAVE AUTHENTICATION, OR THAT YOU 
                  ADD SOME AUTHENTICATION HERE, OR THAT YOU ARE USING THIS IN A DEVELOPMENT
                  ENVIRONMENT.
                  
                  USE AT YOUR OWN RISK, ONLY IF YOU UNDERSTAND THE ABOVE.
                  
                  To do: Add some error handling and validation if desired
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.
USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.ObjectModelParser FROM PROPATH.

DEFINE INPUT  PARAMETER oJMXQuery AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oJMXOut   AS JsonObject NO-UNDO.

DEFINE VARIABLE cJMXCommand AS CHARACTER NO-UNDO.
DEFINE VARIABLE resultJSON     AS LONGCHAR   NO-UNDO.
DEFINE VARIABLE oParser        AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE cFilename      AS CHARACTER NO-UNDO.

ASSIGN
    cJMXCommand = SUBSTITUTE("&1/bin/oejmx.sh -R -Q",OS-GETENV("CATALINA_BASE"))
    cFilename = SUBSTITUTE("&1remote_jmx_&2",SESSION:TEMP-DIRECTORY,STRING(RANDOM(1,1000),"9999")).

oJMXQuery:WriteFile(cFilename + ".qry").

// Do the query and get the results into a JSON
MESSAGE SUBSTITUTE("&1 &2 > &3",cJMXCommand,cFilename + ".qry", cFilename + ".out").
OS-COMMAND SILENT VALUE(SUBSTITUTE("&1 &2 -O &3",cJMXCommand,cFilename + ".qry",cFilename + ".out")).
COPY-LOB FROM FILE cFilename + ".out" TO resultJSON
    CONVERT TARGET CODEPAGE "UTF-8".
    
oParser = NEW ObjectModelParser().
oJMXOut = CAST(oParser:Parse(resultJSON),JsonObject).

FINALLY:
    //OS-DELETE VALUE (cFilename + ".qry").
    //OS-DELETE VALUE (cFilename + ".out").
    IF VALID-OBJECT (oParser) THEN DELETE OBJECT oParser.
END FINALLY.