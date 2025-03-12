# Apsvbench
Purpose: Benchmarking tool for PASOE
Author: S.E. Southwell - Progress

## Instructions
1. Extract this project to disk somewhere on your Windows machine.
2. Locate bin/env_vars.bat and edit the file so that APSVBENCH is set to your installation location, and APSVCONNECTSTRING is a valid OpenEdge appserver connection string.
3. Edit bench/stressapsv.p so that the RUN statement calls the correct .p on your appserver with the right path and parameters.
3. Open up a proenv window and navigate to this project.
4. Run this command:
   ```
   bin/run_stresstestapsv.bat 1:1
   ```
   Check for a response like this:
     ```
     proenv>run_stresstestapsv.bat 1 1
     OBSV:.655
     Thread#:1
     Calls:1
     ELAPSED:.655
     AVG: .66
     MIN: .655
     MAX: .655
     done
     ```
