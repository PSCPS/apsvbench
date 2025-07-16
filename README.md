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
You must be able to put some files into your appserver's propath
The app you are testing must be enabled for APSV transport.  
The client machine you are testing from should have sufficient CPU and RAM to be able to start as many OpenEdge AVM sessions
as you will need to test with.


## How it works
Once you configure this tool, you can use it to run simultaneous OpenEdge client threads, which will continually run
test the appserver in a tight loop by making a connection, running a procedure, then disconnecting.  

Each of the client processes will dump a log file in the results folder after it completes its run.  This file contains the 
timing of each request.  Once each client has completed its runs, a procedure will be run to summarize the statistics
with average, min, max, standard deviation, and a histogram of the timing distributions.  It also writes a CSV file
with the results

If you install the optional shell scripts in your instance, the instance will startup and use the 
sar command in the background to track CPU, Memory and Swap usage, which the tool can then retrieve 
during a run.  It will then retrieve these after the tests are complete, and give you the average CPU/Mem/Swap
usage during the 30 seconds prior to the end of the test.  Note that server-side stats use up a fair amount of disk
space, so by default the sar_startup.sh script sets a time limit of 2 hours (7200 seconds) to gather stats.  You can
adjust this if you need more time, or you can start this script again from the commandline as the PASOE user.

## Quick Instructions
1. Extract this project to disk somewhere on your Windows machine.
2. Locate bin/env_vars.bat and edit the file so that APSVBENCH is set to your installation location, and APSVCONNECTSTRING is a valid OpenEdge appserver connection string.
Also make sure that you set ABLAPPNAME.
3. Edit bench/stressapsv.p so that the RUN statement calls the correct .p on your appserver with the right path and parameters.
4. Optionally: Place the bin/*.sh files in the {CATALINA_BASE}/bin folder of the instance you want to test.  Ensure they are executable by the user account that PASOE runs under.
5. Open up a proenv window and navigate to this project.
6. Run this command to test a single thread, one repetition:
   ```
   bin/run_stresstestapsv.bat 1:1:a
   ```
   Check for a response like this:
     ```
     proenv>run_stresstestapsv.bat 1:1:a
     pausing: 0
     TestId: a
     OBSV:.553
     Thread#:1
     Calls:1
     ELAPSED:.553
     AVG: .55
     MIN: .553
     MAX: .553
     done
     ```
   If your env_vars.bat is not setup correctly, you may have an error display.  Otherwise, you are ready to try multiple threads.
7. Run the run_tests.bat command below to have 4 threads each run 20 repetitions
   ```
   run_tests.bat a 4 20
   ```
   Check for a response like this:
   ```
    proenv>run_tests.bat a 40 100
    Checking server resources before run...
            APSV Agents Running:   4
          APSV Sessions Running:  40
    Metrics reset for OE app: magaliOE
    TestId: a
    Starting concurrent execution...
    Awaiting completion...
    .......................
    Summarizing Results
    
    Tot. Runtime: 931.90             Cli. Threads: 40                     Samples: 1,323
        Avg Call: 0.704                  Min Call: 0.539                 Max Call: 1.105
          Median: 0.671                   Std Dev: 0.093                 Skewness: 1.421
      Throughput: 56.79
    
    Timing histogram: (@=9, *=4.5, .>=1)
     0.539 -  0.577:    20 |@@.
     0.577 -  0.614:    99 |@@@@@@@@@@@
     0.614 -  0.652:   276 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*
     0.652 -  0.690:   383 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* (med=0.671)  (mode)
     0.690 -  0.728:   163 |@@@@@@@@@@@@@@@@@@. (avg=0.704)
     0.728 -  0.765:   147 |@@@@@@@@@@@@@@@@.
     0.765 -  0.803:    53 |@@@@@*
     0.803 -  0.841:    38 |@@@@.
     0.841 -  0.879:    44 |@@@@*
     0.879 -  0.916:    34 |@@@*
     0.916 -  0.954:    32 |@@@*
     0.954 -  0.992:    17 |@*
     0.992 -  1.030:    10 |@.
     1.030 -  1.067:     5 |*
     1.067 -  1.105:     2 |.
    
    Server-side statistics:
    
       CPU Usage: 49.42%                MEM Usage: 86.10%              Swap Usage: 55.40%
     APSV Agents: 4                   APSV Sessio: 40                  ABL Appnam: magaliOE
        Requests: 1,326               Max Concurr: 39                 Sess. Waits: 0
    Sess. Timeou: 0                        Errors: 2,677
   ```
   Note that if you installed the bin/*.sh files on the server, you'll get the CPU/Mem/Swap statistics as well.


## Files
   apsv/* - Examples of programs you could place within your appserver's propath in order to load test.  (But feel free to use your own)  
   bench/*.p - ABL procedures to test the appserver and tabulate results  
   bin/*.bat - Windows .bat files to start up the multi-threaded testing as well as process the output.  
   bin/*.sh - Linux shell scripts to place in the {CATALINA_BASE}/bin directory of the instance you want to test. (Optional to gather server-side stats)  
   results/*.txt - Data files from each thread of your tests.  If this folder doesn't exist when you first start Apsvbench, then it will be created automatically.  
   results/testlog.csv - Results are written here in csv format in addition to being shown on-screen.
   
## Testing Tips
You may hit local limits on your own machine before you are able to adequately stress out your server.
If you are doing concurrency over about 25 threads, then you'll have to probably reduce the number of repetitions in order
to prevent running out of local network resources.  You may also find that you can run out of local memory or CPU.  Definitely
watch your task manager's performance view until you can see where your local machine's limits are.  You also want to watch the "Errors" number
that Apsvbench reports in the output.  In the example above, you can see that the user asked for 40 sessions at 100 repetitions, but it only
managed to get 1,323 samples, and 2,677 errors. What may be happening is that the system is running out of network ports for requests.  If
you wait a minute, those ports free up and you can try again
