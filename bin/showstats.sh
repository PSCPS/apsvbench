#!/bin/bash
INFILE="${CATALINA_BASE}/temp/serverstats.sar"
sar -$1 -f $INFILE -e $(date -d '1 seconds ago' +'%H:%M:%S') -s $(date -d "$2 seconds ago" +'%H:%M:%S') |
awk 'NR==3 {first=$0} {last=$0} END {print first; print last}'
