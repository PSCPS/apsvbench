#!/bin/bash
echo "Starting sar for server stats"
rm -f ${CATALINA_BASE}/temp/serverstats.sar
nohup sar -urS -o ${CATALINA_BASE}/temp/serverstats.sar 1 7200 > /dev/null 2>${CATALINA_BASE}/temp/serverstats.err &
echo "Sar started"
