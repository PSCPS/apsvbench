# Apsvbench
Purpose: Benchmarking tool for PASOE  
Author: S.E. Southwell - Progress  
Disclaimer: THIS CODE IS PROVIDED FREE AS-IS, WITHOUT ANY WARRANTY OR SUPPORT FROM THE AUTHOR OR PROGRESS SOFTWARE CORPORATION.  USE AT YOUR OWN RISK

This tool allows an OpenEdge developer to put an artificial load on a PASOE OpenEdge app running on APSV protocol.  You can specify multiple simultaneous threads of testers, which will repeatedly connect to and make requests on the appserver.

## Requirements
You must have OpenEdge 12.x or better installed on a Windows machine to test from.
You must have access to a PASOE instance running an APSV application
You must have an appserver procedure that can be called without causing damage to your data, and that can be called simultaneously.

## Quick Instructions
1. Extract this project to disk somewhere on your Windows machine.
2. Locate bin/env_vars.bat and edit the file so that APSVBENCH is set to your installation location, and APSVCONNECTSTRING is a valid OpenEdge appserver connection string.
3. Edit bench/stressapsv.p so that the RUN statement calls the correct .p on your appserver with the right path and parameters.
3. Open up a proenv window and navigate to this project.
4. Run this command to test a single thread, one repetition:
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
5. Run the run_tests.bat command below to have 10 threads each run 50 repetitions
   ```
   run_tests run_stresstestapsv.bat 10 50
   ```
   Check for a response like this:
   ```
   proenv>run_tests run_stresstestapsv.bat 10 50
   Starting concurrent execution...
   Awaiting completion...
   Summarizing results...
   
      Total Runtime: 292.11
       Thread Count: 10
            Samples: 500
     Avg Call (sec): 0.58
     Min Call (sec): 0.53
     Max Call (sec): 0.73
          Std. Dev.: 0.02
   Throughput / sec: 17.12
   Timing histogram:
    0.528 <= x <  0.549:    25 ****
    0.549 <= x <  0.569:    82 *************
    0.569 <= x <  0.590:   198 ********************************
    0.590 <= x <  0.610:   157 *************************
    0.610 <= x <  0.631:    26 ****
    0.631 <= x <  0.652:     5 *
    0.652 <= x <  0.672:     3 .
    0.672 <= x <  0.693:     2 .
    0.693 <= x <  0.713:     0
    0.713 <= x <  0.734:     2 .
   ```

## Files
   apsv/* - Examples of programs you could place within your appserver's propath in order to load test.  (But feel free to use your own)  
   bench/*.p - ABL procedures to test the appserver and tabulate results  
   bin/*.bat - Windows .bat files to start up the multi-threaded testing as well as process the output.  
   results/*.txt - Data files from each thread of your tests.  If this folder doesn't exist when you first start Apsvbench, then it will be created automatically.
