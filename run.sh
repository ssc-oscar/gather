#!/bin/bash

DT=201903
#get updated repos only
#python3 ghUpdatedRepos.py 2018-12-01 gh201813 repos  &> ghReposList201813.updt &
python3 ghUpdatedRepos.py 2019-02-01 gh$DT repos  &> ghReposList$DT.updt &

#needs to be chaged to 201001
python3 bbRepos.py 1980-01-01 bitbucket$DT 2012-01-01 &> bbRepos${DT}0.out &
python3 bbRepos.py 2012-01-01 bitbucket$DT 2014-01-01 &> bbRepos${DT}1.out &
python3 bbRepos.py 2014-01-01 bitbucket$DT 2015-01-01 &> bbRepos${DT}2.out &
python3 bbRepos.py 2015-01-01 bitbucket$DT 2016-01-01 &> bbRepos${DT}3.out &
python3 bbRepos.py 2016-01-01 bitbucket$DT 2017-01-01 &> bbRepos${DT}4.out &
python3 bbRepos.py 2017-01-01 bitbucket$DT  &> bbRepos${DT}5.out &


python3 sfRepos.py sf$DT repos &> sf$DT.out &
#python3 extractSfGit.py sf201813 repos &>> sf201813.out

python3 	glRepos.py 1 gl$DT repos &> gl$DT.out &

wait


#where did sf201813.prj.$i came from?
python3 listU.py sf201813 repos url | sed "s|b`https://sourceforge.net/projects//p/||;s|'$||;" > sf201813.prj 
split -n l/30 -da2 sf201813.prj sf201813.prj.
for i in {00..29}
do cat sf201813.prj.$i | while read r; 
  do gg=$(git ls-remote "https://git.code.sf.net/p/$r/git" 2> /dev/null| awk '{print ";"$1}')
  cc=$(git ls-remote "https://git.code.sf.net/p/$r/code" 2> /dev/null| awk '{print ";"$1}');  
  [[ $gg == "" ]] || echo https://git.code.sf.net/p/$r/git$gg |sed 's/ ;/;/g'
  [[ $cc == "" ]] || echo https://git.code.sf.net/p/$r/code$cc|sed 's/ ;/;/g'; 
  done | gzip > sf201813.prj.$i.heads & 
done

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
#Why again?
python3 listU.py gh201813 reposu '{"isFork" : false}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > gh201813.u
split -n l/30 -da2 gh201813.u gh201813.u.
for j in {00..29}
do cat gh201813.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
  done | gzip > gh201813.u.$j.heads &
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
