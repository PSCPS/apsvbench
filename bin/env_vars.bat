:: Set the location where you've installed apsvbench
set APSVBENCH=C:\apps\apsvbench

:: Discarding results
set DISCARDOUTLIERS=TRUE
::set DISCARDTYPE=FIXED:2
::set DISCARDTYPE=PERCENT:5
set DISCARDTYPE=IQR:1.5
:: DISCARDTYPE: FIXED=Set number of records from either end to remove.  IQR: Remove numbers below Q1 - x*IQR or above Q3 + x*IQR
set WARMUPRUNS=1

:: Set your APSV connection string.
:: example:
set APSVCONNECTSTRING=-URL https://myserver.com/myapp/apsv -sessionModel Session-free
 
:: Number of seconds of server-side stats to grab at the end of the test
set SERVERSTATSSECONDS=30

:: ABL AppName
set ABLAPPNAME=myapp

:: Histogram control
set HIST_SHOWHISTOGRAM=TRUE
::    Number includes out-of-range buckets where value is below lowrange or above high range
set HIST_NUMBUCKETS=10
::    How to scale the size of each histogram bar.  Only option right now is "auto".
set HIST_BARSCALE=auto

:: Histogram range type:  
::    auto = even divisions from lowest time to highest time
::    fixed = even divisions starting at low range, by bucket size.
set HIST_RANGETYPE=auto
::set HIST_RANGETYPE=fixed
::set HIST_LOWRANGE=0.53
::set HIST_BUCKETSIZE=0.0025