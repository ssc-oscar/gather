#!/usr/bin/bash

# For now:

DT=202309

for i in {1..6}; do (r=$(head -$i tokens|tail -1); echo $r | python3 ghUpdatedRepos_Daily.py test$DT repos  &> ghReposList$(echo $r | cut -d ' ' -f1).updt) & done

exit 0
