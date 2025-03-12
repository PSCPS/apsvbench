
/*------------------------------------------------------------------------
    File        : ttObs.i
    Purpose     : Temp-table definitions for benchmarking stats

    Syntax      :

    Description : 

    Author(s)   : S.E. Southwell - Progress
    Created     : Wed Mar 12 08:42:02 CDT 2025
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE TEMP-TABLE ttObs NO-UNDO
    FIELD obsId   AS INTEGER
    FIELD runtime AS DECIMAL
    INDEX pkobsid IS PRIMARY UNIQUE obsid.

    
DEFINE TEMP-TABLE ttBucket NO-UNDO
    FIELD bucketID AS INTEGER
    FIELD lowValue AS DECIMAL FORMAT ">>>9.999"
    FIELD highValue AS DECIMAL FORMAT ">>>9.999"
    FIELD obscount AS INTEGER FORMAT ">>>,>>9"
    INDEX pkbucketId IS PRIMARY UNIQUE bucketid.