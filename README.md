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
    proenv>run_tests.bat a 4 20
    Checking server resources before run...
            APSV Agents Running:   4
          APSV Sessions Running:   4
    Metrics reset for OE app: silviaOE
    TestId: a
    Starting concurrent execution...
    Awaiting completion...
    .............................................................
    
    Deleting outliers: IQR:1.5 Lower fence: 2.2985 Upper fence: 3.5025
    Deleting IQR outlier:  3.564
    Deleting IQR outlier:  3.516
    Deleting IQR outlier:  3.991
    Deleting IQR outlier:  4.21
    
    Summarizing Results
    
    Tot. Runtime: 207.73             Cli. Threads: 4                      Samples: 72
        Avg Call: 2.885                    95% CI: +/-0.050              Min Call: 2.365
             P90: 3.180                       P95: 3.456                 Max Call: 3.456
          Median: 2.833                   Std Dev: 0.217                 Skewness: -0.076
      Throughput: 1.39                   CoeffVar: 0.075                      IQR: 0.301
    Result Trust: Acceptable
    
    Timing histogram: (@=1, *=.5, .>=1)
     2.365 -  2.474:     3 |@@@
     2.474 -  2.583:     2 |@@
     2.583 -  2.692:     9 |@@@@@@@@@
     2.692 -  2.801:    10 |@@@@@@@@@@
     2.801 -  2.911:    13 |@@@@@@@@@@@@@ (med=2.833)  (avg=2.885)
     2.911 -  3.020:    16 |@@@@@@@@@@@@@@@@ (mode)
     3.020 -  3.129:    11 |@@@@@@@@@@@
     3.129 -  3.238:     5 |@@@@@
     3.238 -  3.347:     2 |@@
     3.347 -  3.456:     1 |@
    
    Server-side statistics:
    
       CPU Usage: 97.96%                MEM Usage: 48.00%              Swap Usage: 0.00%
     APSV Agents: 4                   APSV Sessio: 4                   ABL Appnam: silviaOE
        Requests: 2,111               Max Concurr: 3                  Sess. Waits: 0
    Sess. Timeou: 0                        Errors: 0
   ```
   Note that if you installed the bin/*.sh files on the server, you'll get the CPU/Mem/Swap statistics as well.


## Files
   apsv/* - Examples of programs you could place within your appserver's propath in order to load test.  (But feel free to use your own)  
   bench/*.p - ABL procedures to test the appserver and tabulate results  
   bin/*.bat - Windows .bat files to start up the multi-threaded testing as well as process the output.  
   bin/*.sh - Linux shell scripts to place in the {CATALINA_BASE}/bin directory of the instance you want to test. (Optional to gather server-side stats)  
   results/*.txt - Data files from each thread of your tests.  If this folder doesn't exist when you first start Apsvbench, then it will be created automatically.  
   results/testlog.csv - Results are written here in csv format in addition to being shown on-screen.

## Configuration
The bin/env_vars.bat file contains various configuration variables to drive the testing and display of results.

The following is an alphabetical listing of the environment variables and what they mean:

   **ABLAPPNAME** - Name of the ABL app that you are testing on your appserver.  Used when gathering PASOE data for test results.  

   **APSVBENCH** - The fully qualified path of the apsvbench directory  

   **APSVCONNECTSTRING** - The appserver connection string to use when making the connection.  Just like you would use in a connect statement.  

   **DISCARDOUTLIERS** - TRUE or FALSE - whether the results should discard outliers in accordance with DISCARDTYPE  

   **DISCARDTYPE** - How the program should discard outliers, if it does that.  
      Format:  
         TYPE:VALUE  
      Type Options:  
         FIXED - Set a number of records from both the high and low side to remove.  e.g. FIXED:2  
         IQR - Remove numbers based on Interquartile range: below Q1 - x*IQR or above Q3 + x*IQR.  The value to enter is x in this equation, and 1.5 is a good value to use.  

   **HIST_SHOWHISTOGRAM** - TRUE or FALSE - whether to show a histogram of the result timings.  Useful for determining visually how the results go.  

   **HIST_NUMBUCKETS** - Number of "buckets" to divide results into for the histogram.  The top and bottom buckets will contain any numbers that are out of range.  

   **HIST_RANGETYPE** - fixed or auto - Use auto to have the program calculate the appropriate range based on results.  Use fixed if you need to compare test results with a common histogram range.   

   **HIST_LOWRANGE** - Sets the low number when HIST_RANGETYPE is fixed.

   **HIST_BUCKETSIZE** - Sets the numeric range of each bucket when HIST_RANGETYPE is fixed.  

   **SERVERSTATSSECONDS** - The number of seconds worth of server-side stats to grab at the end of the test.  Try to set this such that it captures your tests during the most stressed portion. Defaults to 20.  

   **WARMUPRUNS** - The number of runs that each thread should use to "warm up" before counting the result.  This operations in addition to throwing out outliers.  

## Stopping a test
If you start a test and discover that it is going to take longer than you thought, you can stop the test by means of a test.stop file.  Simply
place a file named "test.stop" into the bin folder that you started your script from.  Be sure to give the threads enough time to come to a stop before deleting the file.  

You may use Ctrl-C within the run_stresstestapsv.bat program, which will stop the batch file, but NOT the associated testing threads.  That's why it's important to use the test.stop file.

## Interpreting results
The two things you'll probably be most interested in are **Avg Call** (Average time per call) and the histogram showing how the results are distributed.    

There are other fields you may have interest in:
- 95% CI: Provides a 95% confidence interval when added/subtracted from the average.
- CoeffVar:  Coefficient of Variance - Ratio of standard deviation to average.  Low numbers indicate tight results
- IQR: Interquartile Range - 75th percentile value minus 25th percentile value
- Min Call: Minimum amount of time (excluding outliers)
- Max Call: Maxiumum amount of time (excluding outliers)
- Median: The middle value of the set. (not the same as average)
- Mode: The most frequently occurring timing (applies to the bucket which contains the most samples)
- P90: 90% of calls take less than this amount of time  
- P95: 95% of calls take less than this amount of time
- Result Trust: Written interpreation of CoeffVar: Ultra Tight, Very Tight, Tight, Acceptable, Noisy, and Too Noisy.  You should be wary of trusting noisy results.
- Std. Dev: Standard deviation - normal statistical meaning
- Skewness: A measure of how skewed the histogram is from a "normal" distribution.
- Throughput: Ratio of tests to actual elapsed time.  (Tests completed per second)
- Tot. Runtime: Sum of each thread's total runtime.  Divide by # of threads to get actual test time

## Server-side statistics
The first row of the server-side statistics comes from output of the server's sar command, as collected over a period of time during
your test.  It shows average CPU usage, Memory usage, and swap usage during the test.  The higher these numbers are, the more variation you will likely have in
your test results as your server struggles to keep up.  If your goal is to benchmark code performance, try to do it with just one thread and many repetitions so that
you don't unnecessarily stress the server and show artificially bad results.  On the other hand, if your goal is to see how much concurrency the server
can handle, then gradually throw more threads at it until you see the numbers get worse.  Running many tests will help you understand how much
your server can handle at various levels.  

The remaining rows of the server-side statistics come from a JMX query that is basically the same as what you would see on the "Application Metrics" page of OpenEdge Management.   

## Testing Tips
You may hit local limits on your own machine before you are able to adequately stress out your server.
If you are doing concurrency over about 25 threads, then you'll have to probably reduce the number of repetitions in order
to prevent running out of local network resources.  You may also find that you can run out of local memory or CPU.  Definitely
watch your task manager's performance view until you can see where your local machine's limits are.  You also want to watch the "Errors" number
that Apsvbench reports in the output.  In the example above, you can see that the user asked for 40 sessions at 100 repetitions, but it only
managed to get 1,323 samples, and 2,677 errors. What may be happening is that the system is running out of network ports for requests.  If
you wait a minute, those ports free up and you can try again.  

You may decide that you want to run a "noop" (No operation) test that simply calls the appserver and runs a .p with no instructions
in it.  This would be a way to determine the average round-trip to the server, so that you could determine how much time the code is taking to run versus
the network latency.  None of the statistical output currently takes into account any noop time, so if you wanted stats based
on runtime alone, you would need to calculate that yourself.

