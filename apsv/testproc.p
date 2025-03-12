
/*------------------------------------------------------------------------
    File        : testproc.p
    Purpose     : Test procedure EXAMPLE for load-testing APSV calls

    Syntax      : THIS PROCEDURE REQUIRES SPORTS2020 DATABASE

    Description :     

    Author(s)   : S.E. Southwell
    Created     : Wed Mar 05 15:20:09 CST 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE TEMP-TABLE tt-customer NO-UNDO LIKE Customer.
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
DEFINE INPUT PARAMETER cInput AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR tt-customer.
MESSAGE "Running testproc".
FOR EACH Customer WHERE Customer.Name MATCHES cInput NO-LOCK:
    CREATE tt-customer.
    BUFFER-COPY Customer TO tt-customer.
END.

