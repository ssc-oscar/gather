#!/bin/bash


strt=0
for i in {0..5}
do fr=$(($i*20000000+$strt))
   to=$(($fr+20000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201812 $fr $to &> ghReposList201812.$fr-$to &
done
wait
strt=120000000
for i in {0..4}
do fr=$(($i*20000000+$strt))
   to=$(($fr+20000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201812 $fr $to &> ghReposList201812.$fr-$to &
done
python3 bbRepos.py 1980-01-01 bitbucket201812 &> bbRepos201812.out
wait

#${un[$i]} ${ps[$i]} 
