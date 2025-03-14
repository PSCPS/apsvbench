# Apsvbench
Purpose: Benchmarking tool for PASOE  
Author: S.E. Southwell - Progress  
Disclaimer: THIS CODE IS PROVIDED FREE AS-IS, WITHOUT ANY WARRANTY OR SUPPORT FROM THE AUTHOR OR PROGRESS SOFTWARE CORPORATION.  USE AT YOUR OWN RISK

## Description
This tool allows an OpenEdge developer to put an artificial load on a PASOE OpenEdge app running on APSV protocol.  You can specify multiple simultaneous threads of testers, which will repeatedly connect to and make requests on the appserver.

## Requirements
You must have OpenEdge 12.x or better installed on a Windows machine to test from.  
You must have access to a PASOE instance running an APSV application.  
You must have an appserver procedure that can be called without causing damage to your data, and that can be called simultaneously.  
The app you are testing must be enabled for APSV transport.  
The client machine you are testing from should have sufficient CPU and RAM to be able to start as many OpenEdge AVM sessions
as you will need to test with.

## How it works
Once you configure this tool, you can use it to run simultaneous OpenEdge client threads, which will continually run
test the appserver in a tight loop by making a connection, running a procedure, then disconnecting.  

Each of the client processes will dump a log file in the results folder after it completes its run.  This file contains the 
timing of each request.  Once each client has completed its runs, a procedure will be run to summarize the statistics
with average, min, max, standard deviation, and a histogram of the timing distributions.  

If you install the optional shell scripts in your instance, the instance will startup and use the 
sar command in the background to track CPU, Memory and Swap usage, which the tool can then retrieve 
during a run.  It will then retrieve these after the tests are complete, and give you the average CPU/Mem/Swap
usage during the 30 seconds prior to the end of the test.  Note that server-side stats use up a fair amount of disk
space, so by default the sar_startup.sh script sets a time limit of 2 hours (7200 seconds) to gather stats.  You can
adjust this if you need more time, or you can start this script again from the commandline as the PASOE user.

## Quick Instructions
1. Extract this project to disk somewhere on your Windows machine.
2. Locate bin/env_vars.bat and edit the file so that APSVBENCH is set to your installation location, and APSVCONNECTSTRING is a valid OpenEdge appserver connection string.
3. Edit bench/stressapsv.p so that the RUN statement calls the correct .p on your appserver with the right path and parameters.
4. Optionally: Place the bin/*.sh files in the {CATALINA_BASE}/bin folder of the instance you want to test.  Ensure they are executable by the user account that PASOE runs under.
5. Open up a proenv window and navigate to this project.
6. Run this command to test a single thread, one repetition:
   ```
   bin/run_stresstestapsv.bat 1:1
   ```
   Check for a response like this:
     ```
     proenv>run_stresstestapsv.bat 1:1
     OBSV:.655
     Thread#:1
     Calls:1
     ELAPSED:.655
     AVG: .66
     MIN: .655
     MAX: .655
     done
     ```
   If your env_vars.bat is not setup correctly, you may have an error display.  Otherwise, you are ready to try multiple threads.
7. Run the run_tests.bat command below to have 10 threads each run 50 repetitions
   ```
   run_tests run_stresstestapsv.bat 40 100
   ```
   Check for a response like this:
   ```
    proenv>run_tests.bat run_stresstestapsv.bat 40 100
    Starting concurrent execution...
    Awaiting completion...
    Summarizing results...
    
       Total Runtime: 2,904.12
        Thread Count: 40
             Samples: 4,000
      Avg Call (sec): 0.73
      Min Call (sec): 0.55
      Max Call (sec): 2.64
           Std. Dev.: 0.19
    Throughput / sec: 55.09
    Timing histogram:
     0.546 <= x <   0.755: 3,248 *****************************************************************
     0.755 <= x <   0.964:   588 ************
     0.964 <= x <   1.173:   114 **
     1.173 <= x <   1.382:    10 .
     1.382 <= x <   1.592:     0
     1.592 <= x <   1.801:     0
     1.801 <= x <   2.010:     0
     2.010 <= x <   2.219:     6 .
     2.219 <= x <   2.428:    21 .
     2.428 <= x <=  2.637:    13 .
    Getting server-side statistics...
     CPU Usage:  53.82%
     MEM Usage:  86.40%
    Swap Usage:  56.00%
   ```
   Note that if you installed the bin/*.sh files on the server, you'll get the CPU/Mem/Swap statistics as well.

8. On the server, you can monitor for CPU and memory usage at the commandline using the sar command:
      ```
        [ec2-user@rita ~]$ sar -urS 1 20 | tail -n 8
        Average:        CPU     %user     %nice   %system   %iowait    %steal     %idle
        Average:        all      0.88      0.00      0.62      0.10      0.57     97.84
        
        Average:    kbmemfree   kbavail kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
        Average:        78784    169576   1619421     80.85        24    221644   5679229     93.12    372082   1398296       377
        
        Average:    kbswpfree kbswpused  %swpused  kbswpcad   %swpcad
        Average:      1609468   2486528     60.71    152832      6.15
      
      ``` 

## Files
   apsv/* - Examples of programs you could place within your appserver's propath in order to load test.  (But feel free to use your own)  
   bench/*.p - ABL procedures to test the appserver and tabulate results  
   bin/*.bat - Windows .bat files to start up the multi-threaded testing as well as process the output.  
   bin/*.sh - Linux shell scripts to place in the {CATALINA_BASE}/bin directory of the instance you want to test. (Optional to gather server-side stats)
   results/*.txt - Data files from each thread of your tests.  If this folder doesn't exist when you first start Apsvbench, then it will be created automatically.
