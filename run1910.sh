#!/bin/bash
PDT=201905
PDTdash=2019-05-01
DT=201910
# Get updated repos only: updated since last gathering
#python3 ghUpdatedRepos.py 2018-12-01 gh201813 repos  &> ghReposList201813.updt &
cat tokens_date | while read r; do echo $r | python3 ghUpdatedRepos.new.py gh$DT repos  &> ghReposList$(echo $r | cut -d ' ' -f2).updt & done

# BB: need to extract all, no way to check for updated ones
#python3 bbRepos.py 1980-01-01 bitbucket$DT 2013-00-01 &> bbRepos${DT}0.out &
#python3 bbRepos.py 2013-01-01 bitbucket$DT 2014-05-03 &> bbRepos${DT}1.out &
#python3 bbRepos.py 2014-05-03 bitbucket$DT 2015-05-03 &> bbRepos${DT}2.out &
#python3 bbRepos.py 2015-05-03 bitbucket$DT 2016-05-03 &> bbRepos${DT}3.out &
#python3 bbRepos.py 2015-05-03 bitbucket$DT 2016-05-03 &> bbRepos${DT}4.out &
#python3 bbRepos.py 2016-05-03 bitbucket$DT 2017-05-03 &> bbRepos${DT}5.out &
#python3 bbRepos.py 2017-05-03 bitbucket$DT 2018-05-03 &> bbRepos${DT}6.out &
#python3 bbRepos.py 2018-05-03 bitbucket$DT 2022-05-03 &> bbRepos${DT}7.out &
#get only new, use heads for existing repos
python3 bbRepos.py $PDTdash bitbucket$DT 2022-05-03 &> bbRepos${DT}0.out &


# SF 
python3 sfRepos.py sf$DT repos 
python3 listU.py sf$DT repos '{}' url | sed "s|b'https://sourceforge.net/projects/||;s|'$||;" | sort -u > sf$DT.prj
join -v1 sf$DT.prj sf$PDT.prj > sf$DT.prj.new

#python3 extractSfGit.py sf201813 repos &>> sf201813.out

# Gitlab
python3 glRepos.py 1 gl$DT repos &> gl$DT.out &

wait

# Split for parallel processing
cat sf$DT.prj.new | while read r; 
do gg=$(git ls-remote "https://git.code.sf.net/p/$r/git" 2> /dev/null| awk '{print ";"$1}')
  cc=$(git ls-remote "https://git.code.sf.net/p/$r/code" 2> /dev/null| awk '{print ";"$1}');  
  [[ $gg == "" ]] || echo https://git.code.sf.net/p/$r/git$gg |sed 's/ ;/;/g'
  [[ $cc == "" ]] || echo https://git.code.sf.net/p/$r/code$cc|sed 's/ ;/;/g'; 
done | gzip > sf$DT.prj.new.heads & 
#now do for existing
zcat sf$PDT.prj.*.heads

# Do other forges git.bioconductor.org, 
wget http://git.bioconductor.org -O bio.html
cat bio.html | awk '{print $2}' | grep / | grep -v '\*' | awk '{ print "https://git.bioconductor.org/"$1}' > bioconductor.org.$DT 
cat bioconductor.org.$DT | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > bioconductor.org.$DT.heads &

wget "https://repo.or.cz/?a=project_list" -O cz.html
grep '\.git' cz.html  | sed 's|.*"/\([^/"]*\.git\).*|\1|' | uniq | sort -u | awk '{print "https://repo.or.cz/"$1}'> repo.or.cz.$DT
cat repo.or.cz.$DT | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > repo.or.cz.$DT.heads &

wget https://cgit.kde.org/ -O kde.html
grep '\.git' kde.html  |  sed "s|.*href='/\([^']*\.git\).*|\1|" | \
   uniq | sort -u | awk '{print "https://anongit.kde.org/"$1}'> cgit.kde.org.$DT
cat cgit.kde.org.$DT | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > cgit.kde.org.$DT.heads &

# pages 1-300
# https://gitlab.gnome.org/explore/projects?page=300&sort=latest_activity_desc
# insert username/password to prevend password requests
for p in {1..300}
do wget "https://gitlab.gnome.org/explore/projects?page=$p" -O - 2> /dev/null | perl -ane 'chop();if (m|^<a class="text-plain" href="|){s|<a class="text-plain" href="||;s|".*||;s|^/||;print "https://a:a\@gitlab.gnome.org/$_\n"}'
done | sort -u > gitlab.gnome.org.$DT
cat gitlab.gnome.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > gitlab.gnome.org.$DT.heads &


# pages 1-1530 
# git.debian.org -> https://salsa.debian.org/explore/projects?page=1540&sort=latest_activity_desc
for of in {0..9}; do 
for p in $(eval "echo {$((1+$of*163))..$((163+$of*163))}")
do wget "https://salsa.debian.org/explore/projects?page=$p"  -O - 2> /dev/null | perl -ane 'chop(); while (m|<a class="project" href="([^"]*)"|g){print "https://a:a\@salsa.debian.org$1\n"}'
done > git.debian.org.$DT.$of &
done
wait
for of in {0..9}; do
cat git.debian.org.$DT.$of | while read r; do a=$(git ls-remote $r 2> err | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; sleep 2; done | gzip > git.debian.org.$DT.$of.heads 
done


# Add following forges as well
# android.git.kernel.org ??

#there are totally 2398 pages in https://git.drupalcode.org/explore/projects
thost="https://git.drupalcode.org/explore/projects?page="
i=0
rm drupal.org
while :
do i=$(($i+1));
rhost="$thost$i";
curl -o drupal.html  $rhost;
#if j==-1,this is invalid page,we have gotten all pages successfully. 
j=$(perl -e '$e=0;while(<STDIN>){if(m|<h5>This user doesn|){$e=-1;last;};}; print "$e\n"' < drupal.html);
if [ "$j" -eq "-1" ]; then break; fi;
#all urls will be stored in ./drupal.com
perl -ane 'while(m|<span class="project-name">([^<]*)</span>|g){print "https://git.drupalcode.org/project/$1\n"}' < drupal.html>> drupal.com;
if [ `expr $i % 10` -eq 0 ]; then  sleep 2; fi;
done  
sed  's|.*/project/|dr:project/|' drupal.com | sort -u | \
while read r; do git ls-remote $r | grep -E 'refs/heads|HEAD' | sed 's|\s*refs/heads/|;|;s|\s*HEAD|;HEAD|;s|^|'$r';|';
done | gzip > drupal.com.heads &


wget https://android.googlesource.com/ -O android.googlesource.com.html
perl -ane 'while(m|class="RepoList-itemName">([^<]*)</|g){print "https://android.googlesource.com/$1\n";}' < android.googlesource.com.html > android.googlesource.com.$DT
cat android.googlesource.com.$DT | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g';
done | gzip > android.googlesource.com.$DT.heads &

wget https://git.zx2c4.com -O git.zx2c4.com.html
perl -ane "while (m|<td class='toplevel-repo'><a title='([^']*)'|g){print \"https://git.zx2c4.com/\$1\n\";}" < git.zx2c4.com.html > git.zx2c4.com.$DT
cat git.zx2c4.com.$DT | \
while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g';
done | gzip > git.zx2c4.com.$DT.heads &

wget http://git.eclipse.org/ -O git.eclipse.org.html
perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.eclipse.org\$1\n\";}" < git.eclipse.org.html | sed 's|/c/|/r/|' > git.eclipse.org.$DT
cat git.eclipse.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.eclipse.org.$DT.heads &


wget http://git.postgresql.org -O git.postgresql.org.html
perl -ane 'while(m|<a class="list" href="/gitweb/\?p=([^"]*);a=summary"|g){print "https://git.postgresql.org/git/$1\n"}' < git.postgresql.org.html | sort -u > git.postgresql.org.$DT
cat git.postgresql.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.postgresql.org.$DT.heads &

wget http://git.kernel.org  -O git.kernel.org.html
perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.kernel.org\$1\n\";}" < git.kernel.org.html > git.kernel.org.$DT
cat git.kernel.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.kernel.org.$DT.heads &


wget http://git.savannah.gnu.org/cgit -O git.savannah.gnu.org.html
perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.savannah.gnu.org\$1\n\";}" < git.savannah.gnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > git.savannah.gnu.org.$DT
cat git.savannah.gnu.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.savannah.gnu.org.$DT.heads &

wait

# Get update repos for GL
python3 listU.py gl$DT repos '{ "last_activity_at" : { "$gt" : "'"$PDTdash"'" }}' http_url_to_repo | sed "s|^b'||;s|'$||" > gl$DT.new 
cat  gl$DT.new | sed 's|https://gitlab.com/|gl:|' | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
done | gzip > gl$DT.new.heads &

# Get updated, no-forks for GH
python3 listU.py gh$DT repos '{"isFork" : false}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > gh$DT.u
split -n l/30 -da2 gh$DT.u gh$DT.u.
for j in {00..29}
do cat gh$DT.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
  done | gzip > gh$DT.u.$j.heads &
done

# Get updated bb (do heads on all 2M?)
python3 listU.py bitbucket$DT repos '{ "updated_on" : { "$gt" : "'"$PDTdash"'" } }' full_name | \
  sed "s|^b'||;s|'$||" | sort -u > bitbucket$DT.new
split -n l/10 -da1 bitbucket$DT.new bitbucket$DT.new.
for j in {0..8}
do cat bitbucket$DT.new.$j | while read r; do
    a=$(git ls-remote bb:$r | awk '{print ";"$1}'); echo bb:$r$a | sed 's/ //g';
  done | gzip > bitbucket$DT.new.$j.heads &
done

wait


#${un[$i]} ${ps[$i]} 
