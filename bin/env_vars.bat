:: Set the location where you've installed apsvbench
set APSVBENCH=C:\apps\apsvbench

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
set HIST_NUMBUCKETS=15

set HIST_BARSCALE=auto

:: Histogram range type:  
::    auto = even divisions from lowest time to highest time
::    fixed = even divisions starting at low range, by bucket size.
set HIST_RANGETYPE=auto
::set HIST_RANGETYPE=fixed
::set HIST_LOWRANGE=0.51
::set HIST_BUCKETSIZE=0.015