#!/bin/bash

if [[ 'a' == 'b' ]];
then
strt=0
for i in {0..5}
do fr=$(($i*20000000+$strt))
   to=$(($fr+20000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201813 $fr $to &> ghReposList201812.$fr-$to &
done
wait
fi 

strt=120000000
for i in {0..4}
do fr=$(($i*20000000+$strt))
   to=$(($fr+20000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201813 $fr $to &> ghReposList201812.$fr-$to &
done
if [[ 'a' == 'b' ]];
then
strt=0
for i in {0..5}
do fr=$(($i*20000000+$strt))
   to=$(($fr+20000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201813 $fr $to &> ghReposList201812.$fr-$to &
done
wait

strt=120000000
for i in {0..4}
do fr=$(($i*20000000+$strt))
   to=$(($fr+20000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201813 $fr $to &> ghReposList201812.$fr-$to &
done
wait

fi

strt=150000000
for i in {0..5}
do fr=$(($i*5000000+$strt))
   to=$(($fr+5000000))
   python3 ghReposList.py ${un[$i]} ${ps[$i]} ghReposList201813 $fr $to &> ghReposList201813.$fr-$to &
done   

python3 bbRepos.py 1980-01-01 bitbucket201813 &> bbRepos201813.out &

(python3 sfRepos.py sf201813 repos; python3 extractSfGit.py sf201813 repos) &

python3 	glRepos.py 1 gl201813 repos &

#other forges git.bioconductor.org, 
wget http://git.bioconductor.org -O bio.html
cat bio.html | awk '{print $2}' | grep / | grep -v '\*' | awk '{ print "https://git.bioconductor.org/"$1}'> fatal: repository 'https://git.code.sf.net/p/perlcaster/git/' not found

# https://gitlab.gnome.org/explore 
# https://android.googlesource.com/
# https://cgit.drupalcode.org/
# https://cgit.kde.org/
# https://git.zx2c4.com/cgit
# android.git.kernel.org
# http://git.eclipse.org/
# git.postgresql.org
# repo.or.cz
# git.kernel.org
#  git.savannah.gnu git.debian.org
wait

#${un[$i]} ${ps[$i]} 
