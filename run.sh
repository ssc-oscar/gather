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

(python3 sfRepos.py sf201813 repos &> sf201813.out; python3 extractSfGit.py sf201813 repos &>> sf201813.out) &

python3 	glRepos.py 1 gl201813 repos &> gl201813.out &

#other forges git.bioconductor.org, 
wget http://git.bioconductor.org -O bio.html
cat bio.html | awk '{print $2}' | grep / | grep -v '\*' | awk '{ print "https://git.bioconductor.org/"$1}'> fatal: repository 'https://git.code.sf.net/p/perlcaster/git/' not found
cat bioconductor.org | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > bioconductor.org.heads &

wget "https://repo.or.cz/?a=project_list" -O cz.html
grep '\.git' cz.html  | sed 's|.*"/\([^/"]*\.git\).*|\1|' | uniq | sort -u | awk '{print "https://repo.or.cz/"$1}'> repo.or.cz
cat repo.or.cz | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > repo.or.cz.heads &

wget https://cgit.kde.org/ -O kde.html
grep '\.git' kde.html  |  sed "s|.*href='/\([^']*\.git\).*|\1|" | \
   uniq | sort -u | awk '{print "https://anongit.kde.org/"$1}'> cgit.kde.org
cat cgit.kde.org | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > cgit.kde.org.heads &

# https://gitlab.gnome.org/explore 
# https://android.googlesource.com/
# https://cgit.drupalcode.org/
# https://git.zx2c4.com/cgit
# android.git.kernel.org
# http://git.eclipse.org/
# git.postgresql.org
# git.kernel.org
#  git.savannah.gnu git.debian.org
wait
python3 listU.py gl201813 repos '{ "last_activity_at" : { "$gt" : "2018-11-01" }}' http_url_to_repo | sed "s|^b'||;s|'$||" > gl201813.new)&

cat  gl201813.new | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > gl201813.new.heads &

python3 listU.py ghReposList201813 repos '{ "fork" : false }' html_url | sed "s|^b'||;s|'$||" > ghReposList201813.nofork
split -n l/30 -da2 ghReposList201813.nofork ghReposList201813.nofork.
for j in {00..29}
do sed 's|https://github.com/|gh:|' ghReposList201813.nofork.$j | while read r; do
    a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a | sed 's/ //g';
  done | gzip > ghReposList201813.nofork.$j.heads &
done

python3 listU.py bitbucket201813 repos '{ "updated_on" : { "$gt" : "2018-11-01" } }' full_name | \
  sed "s|^b'||;s|'$||" | sort -u > bitbucket201813.new
split -n l/10 -da1 bitbucket201813.new bitbucket201813.new.
for j in {0..8}
do cat bitbucket201813.new.$j | while read r; do
    a=$(git ls-remote bb:$r | awk '{print ";"$1}'); echo bb:$r$a | sed 's/ //g';
  done | gzip > bitbucket201813.new.$j.heads &
done

wait



#${un[$i]} ${ps[$i]} 
