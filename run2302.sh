#!/bin/bash   

# In the first stage bbRepos.py, glRepos.py, and ghUpdatedRepos.py populate mongodb, which is then used to
# get project list, while the rest populate project list into XXXX.$DT
# all XXXX.$DT need to be copied to da cluster

# in the second stage the check for latest objects is produced vi ls-relote
# second stage typically requires a much larger disk to store *.heads
# all *.heads need to be copied to da cluster

git ls-remote bb:swsc/lookup
git ls-remote gh:fdac20/news
git ls-remote gh:php/php-src
git ls-remote gl:inkscape/inkscape
git ls-remote gl_gnome:GNOME/gtk
git ls-remote dr:project/drupal
git ls-remote deb:

DT=202302
DTdash=2023-02-12
PDT=202109
PDTdash=2021-09-10

PT=$(date -d"$PDTdash" +%s)
T=$(date -d"$DTdash" +%s)

# Get updated repos only: updated since last gathering
ntok=$(cat tokens|wc -l)
inc=$(( ($T-$PT)/$ntok ))
for i in $(eval "echo {1..$ntok}")
do ptt=$(date -d"@"$(($PT+($i-1)*$inc)) +"%Y-%m-%d")
   tt=$(date -d"@"$(($PT+($i)*$inc)) +"%Y-%m-%d")
   echo $(head -$i tokens|tail -1) $ptt $tt 
done > tokens_date

for i in {1..9}; do (r=$(head -$i tokens_date|tail -1); echo $r | python3 ghUpdatedRepos.py gh$DT repos  &> ghReposList$(echo $r | cut -d ' ' -f2).updt) & done

# BB: need to extract all, no way to check for updated ones
python3 bbRepos.py 1980-01-01 bitbucket$DT 2013-00-01 &> bbRepos${DT}1.out &
python3 bbRepos.py 2013-01-01 bitbucket$DT 2014-05-03 &> bbRepos${DT}2.out &
python3 bbRepos.py 2014-05-03 bitbucket$DT 2015-05-03 &> bbRepos${DT}3.out &
python3 bbRepos.py 2015-05-03 bitbucket$DT 2016-05-03 &> bbRepos${DT}4.out &
python3 bbRepos.py 2016-05-03 bitbucket$DT 2017-05-03 &> bbRepos${DT}5.out &
python3 bbRepos.py 2017-05-03 bitbucket$DT 2018-05-03 &> bbRepos${DT}6.out &
python3 bbRepos.py 2018-05-03 bitbucket$DT 2019-05-03 &> bbRepos${DT}7.out &
python3 bbRepos.py 2019-05-03 bitbucket$DT 2020-05-01 &> bbRepos${DT}8.out &
python3 bbRepos.py 2020-05-03 bitbucket$DT 2021-05-01 &> bbRepos${DT}9.out &
python3 bbRepos.py 2021-05-01 bitbucket$DT 2022-05-03 &> bbRepos${DT}10.out &
#get only new, use heads for existing repos
python3 bbRepos.py 2022-05-03 bitbucket$DT 2023-05-03 &> bbRepos${DT}0.out &

#UNCHECK FROM HERE
# # SF 
# python3 sfRepos.py sf$DT repos 
# python3 listU.py sf$DT repos '{}' url | sed "s|b'https://sourceforge.net/projects/||;s|'$||;" | sort -u > sf$DT.prj
# #join -v1 sf$DT.prj sf$PDT.prj > sf$DT.prj.new

# #python3 extractSfGit.py sf201813 repos &>> sf201813.out

# # Gitlab
# python3 glRepos.py 1 gl$DT repos &> gl$DT.out &

# wait

# # Split for parallel processing
# split -n l/10 -da1 sf$DT.prj sf$DT.prj.
# for i in {0..9}
# do cat sf$DT.prj.$i | while read r; 
#  do gg=$(git ls-remote "https://git.code.sf.net/p/$r/git" 2> /dev/null| awk '{print ";"$1}')
#    cc=$(git ls-remote "https://git.code.sf.net/p/$r/code" 2> /dev/null| awk '{print ";"$1}');  
#    [[ $gg == "" ]] || echo https://git.code.sf.net/p/$r/git$gg |sed 's/ ;/;/g'
#    [[ $cc == "" ]] || echo https://git.code.sf.net/p/$r/code$cc|sed 's/ ;/;/g'; 
#     done | gzip > sf$DT.prj.$i.heads &
# done

# #now do for existing
# zcat sf$PDT.prj.*.heads

# # Do other forges git.bioconductor.org, 
# wget http://git.bioconductor.org -O bio.html
# cat bio.html | awk '{print $2}' | grep / | grep -v '\*' | awk '{ print "https://git.bioconductor.org/"$1}' > bioconductor.org.$DT 
# cat bioconductor.org.$DT | \
# while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
# done | gzip > bioconductor.org.$DT.heads &


# wget "https://blitiri.com.ar/git/"  -O blitiri.com.ar.html
# grep '<td class="name"><a href="' blitiri.com.ar.html|sed 's|^\s*<td class="name"><a href="||;s|".*||' | sort -u | awk '{print "https://blitiri.com.ar/git/"$1}' > blitiri.com.ar.$DT

# u=fedorapeople.org
# wget "https://$u"  -O  $u.html
# grep 'Git repositories' $u.html|sed 's|<a href="||;s|".*||' | sort -u > $u.$DT

# u=code.qt.io
# wget "https://$u/cgit/"  -O  $u.html
# grep 'toplevel-repo' $u.html| sed "s|.*href='/cgit/|/cgit/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $u.$DT

# u=git.alpinelinux.org
# wget "https://$u" -O $u.html
# grep 'toplevel-repo' $u.html | sed "s|.*href='/|/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $u.$DT

# u=git.openembedded.org 
# wget "https://$u" -O $u.html
# grep 'toplevel-repo' $u.html | sed "s|.*' href='/|/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $u.$DT

# for u in git.torproject.org git.xfce.org git.yoctoproject.org
# do wget "https://$u" -O $u.html
# grep -E '(sublevel|toplevel)-repo' $u.html | sed "s|.*' href='/|/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $u.$DT
# done

# wget "https://repo.or.cz/?a=project_list" -O cz.html
# grep '\.git' cz.html  | sed 's|.*"/\([^/"]*\.git\).*|\1|' | uniq | sort -u | awk '{print "https://repo.or.cz/"$1}'> repo.or.cz.$DT
# cat repo.or.cz.$DT | \
# while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
# done | gzip > repo.or.cz.$DT.heads &


# wget "https://gitbox.apache.org/repos/asf" -O gitbox.apache.org.html
# grep '<td><a href="/repos/asf/[^\?]' gitbox.apache.org.html|sed 's|.*<td><a href="/||;s|".*||' | sort -u | awk '{print "https://gitbox.apache.org/"$1}' > gitbox.apache.org.$DT

# echo https://gcc.gnu.org/git/gcc.git > gcc.git.$DT

# for i in {1..50}
# do wget "https://pagure.io/?page=$i&sorting=None" -O pagure.io.html
#    grep '^\s*<a href="/' pagure.io.html |sed 's|^\s*<a href="||;s|".*||'|grep -Ev '^/(about|ssh_info)$' 
# done | uniq | sort -u | awk '{print "https://pagure.io"$1}' > pagure.io.$DT 

# u=notabug.org	 
# for i in {1..50}
# do wget "https://$u/explore/repos?page=$i&q=" -O $u.html
#    grep '<a class="name" href="/' $u.html |sed 's|<a class="name" href="/|/|;s|".*||'
# done |sort -u | awk '{print "https://'$u'"$1}' >  $u.$DT
   
# for u in framagit.org gitlab.adullact.net code.ill.fr forgemia.inra.fr git.unicaen.fr git.unistra.fr git.pleroma.social gitlab.fing.edu.uy gitlab.huma-num.fr  gitlab.irstea.fr gitlab.cerema.fr gite.lirmm.fr gitlab.common-lisp.net 
# do for i in {1..50}
# do sleep 2; wget "https://$u/explore/projects?non_archived=true&page=$i&sort=name_asc" -O $u.html
#    grep '<a class="project" href="' $u.html | sed 's|<a class="project" href="||;s|".*||' 
# done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $u.$DT  
# done

# for u in gitlab.freedesktop.org gitlab.inria.fr gitlab.ow2.org 0xacab.org invent.kde.org 
# do for i in {1..50}
#    do for o in latest_activity_desc name_asc name_desc created_desc created_asc 
#       do sleep 2; wget "https://$u/explore/projects?non_archived=true&page=$i&sort=$o" -O $u.html
#        grep '<a class="project" href="' $u.html | sed 's|<a class="project" href="||;s|".*||' 
#       done
#    done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $u.a.$DT  
#    for i in {1..50}
#    do for o in latest_activity_desc name_asc name_desc created_desc created_asc
#      do sleep 2; wget "https://$u/explore/projects/starred?non_archived=true&page=$i&sort=$o" -O $u.html
#       grep '<a class="project" href="' $u.html | sed 's|<a class="project" href="||;s|".*||'
#      done
#    done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $u.s.$DT  
#    for i in {1..50}
#    do for o in latest_activity_desc name_asc name_desc created_desc created_asc
#      do sleep 2; wget "https://$u/explore/projects/trending?non_archived=true&page=$i&sort=$o" -O $u.html
#         grep '<a class="project" href="' $u.html | sed 's|<a class="project" href="||;s|".*||' 
#       done
#    done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $u.t.$DT  

#    cat $u.?.$DT | sort -u > $u.$DT 
# done

# cat invent.kde.org.$DT | \
# while read r; do r="$r.git";a=$(git ls-remote $r.git | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
# done | gzip > invent.kde.org.$DT.heads &


# #repo.or.cz.$DT gitlab.gnome.org.$DT android.googlesource.com.$DT git.zx2c4.com.$DT git.eclipse.org.$DT git.kernel.org.$DT git.savannah.gnu.org.$DT git.savannah.nongnu.org.$DT
# #fedorapeople.org.$DT list peoples git websites: need to append /public_git/ to get their projects
# cat fedorapeople.org.$DT|sed 's|^\s*||'|while read r; do wget "$r/public_git" -O -; done >  fedorapeople.org.fix.$DT.html
# grep /public_git/  fedorapeople.org.fix.$DT.html|  sed "s|.* href='/cgit/||;s|'.*||;s|/tree/$||;s|^|https://fedorapeople.org/cgit/" | sort -u > fedorapeople.org.fix.$DT


# #git.pleroma.social.$DT - seems not to allow listing
# echo https://git.pleroma.social/pleroma/pleroma > git.pleroma.social.$DT

# for i in fedorapeople.org.fix.$DT pagure.io.$DT blitiri.com.ar.$DT code.qt.io.$DT gitlab.common-lisp.net.$DT code.ill.fr.$DT forgemia.inra.fr.$DT git.unicaen.fr.$DT notabug.org.$DT git.unistra.fr.$DT gcc.git.$DT gitlab.fing.edu.uy.$DT gitlab.huma-num.fr.$DT gitlab.adullact.net.$DT gitlab.irstea.fr.$DT git.alpinelinux.org.$DT gitlab.cerema.fr.$DT git.openembedded.org.$DT gite.lirmm.fr.$DT git.torproject.org.$DT git.xfce.org.$DT git.yoctoproject.org.$DT framagit.org.$DT gitlab.freedesktop.org.$DT  gitlab.ow2.org.$DT gitbox.apache.org.$DT gitlab.inria.fr.$DT
# do (sed 's|/\.git/$||;s|^\s*||;s|//|//a:a@|;s|/tree/$||;s|/$||;s|blitiri.com.ar/git/r/|blitiri.com.ar/repos/|;' $i | while read r; do a=$(git ls-remote "$r" 2> $i.err| awk '{print ";"$1}'); echo "$r$a"|sed 's/ //g'; done| gzip > $i.heads; sleep 2) &
# done 


# # pages 1-300
# # https://gitlab.gnome.org/explore/projects?page=300&sort=latest_activity_desc
# # insert username/password to prevend password requests
# for p in {1..300}
# do wget "https://gitlab.gnome.org/explore/projects?page=$p" -O - 2> /dev/null | perl -ane 'chop();if (m|^<a class="text-plain" href="|){s|<a class="text-plain" href="||;s|".*||;s|^/||;print "https://a:a\@gitlab.gnome.org/$_\n"}'
# done | sort -u > gitlab.gnome.org.$DT
# cat gitlab.gnome.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > gitlab.gnome.org.$DT.heads &


# # pages 1-1530 
# # git.debian.org -> https://salsa.debian.org/explore/projects?page=1540&sort=latest_activity_desc
# for of in {0..9}; do 
# for p in $(eval "echo {$((1+$of*20))..$((20+$of*20))}")
# do wget "https://salsa.debian.org/explore/projects?page=$p"  -O - 2> /dev/null | perl -ane 'chop(); while (m|<a class="project" href="([^"]*)"|g){print "https://a:a\@salsa.debian.org$1.git\n"}'
# done > git.debian.org.$DT.$of &
# done
# wait
# for of in {0..9}; do
# cat git.debian.org.$DT.$of | while read r; do a=$(git ls-remote $r 2> err | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; sleep 20; done | gzip > git.debian.org.$DT.$of.heads 
# done

# sort=name_desc
# # Add following forges as well
# # android.git.kernel.org ??

# #there are totally 2398 pages in https://git.drupalcode.org/explore/projects
# thost="https://git.drupalcode.org/explore/projects?page="
# i=0
# rm drupal.org
# for i in {1..50}
# do 
#  rhost="$thost$i".'&sort=latest_activity_desc';
#  curl -o drupal0.html  $rhost;
#  rhost="$thost$i".'&sort=latest_activity_asc';
#  curl -o drupal1.html  $rhost;
#  rhost="$thost$i".'&sort=created_desc';
#  curl -o drupal2.html  $rhost;
#  rhost="$thost$i".'&sort=created_asc';
#  curl -o drupal3.html  $rhost;
#  rhost="$thost$i".'&sort=name_asc';
#  curl -o drupal4.html  $rhost;
#  rhost="$thost$i".'&sort=name_desc';
#  curl -o drupal5.html  $rhost;
#  rhost="$thost$i".'&sort=stars_desc';
#  curl -o drupal6.html  $rhost;
#  rhost="$thost$i".'&sort=stars_asc';
#  curl -o drupal7.html  $rhost;

#  #if j==-1,this is invalid page,we have gotten all pages successfully. 
#  for t in {0..7}
#  do j=$(perl -e '$e=0;while(<STDIN>){if(m|<h5>This user doesn|){$e=-1;last;};}; print "$e\n"' < drupal$t.html);
#   if [ "$j" -eq "-1" ]; then break; fi;
#   #all urls will be stored in ./drupal.com
#   perl -ane 'while(m|<span class="project-name">([^<]*)</span>|g){print "https://git.drupalcode.org/project/$1\n"}' < drupal$t.html >> drupal.com.$DT;
#   if [ `expr $i % 10` -eq 0 ]; then  sleep 2; fi;
#  done
# done

# sort -u  drupal.com.$DT > drupal.com.$DT.u
# mv drupal.com.$DT.u drupal.com.$DT
# cat drupal.com.$DT| sed  's|.*/project/|dr:project/|'  | \
# while read r; do git ls-remote $r | grep -E 'refs/heads|HEAD' | sed 's|\s*refs/heads/|;|;s|\s*HEAD|;HEAD|;s|^|'$r';|';
# done | gzip > drupal.com.$DT.heads &


# wget https://android.googlesource.com/ -O android.googlesource.com.html
# perl -ane 'while(m|class="RepoList-itemName">([^<]*)</|g){print "https://android.googlesource.com/$1\n";}' < android.googlesource.com.html > android.googlesource.com.$DT
# cat android.googlesource.com.$DT | \
# while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g';
# done | gzip > android.googlesource.com.$DT.heads &

# ###

# wget https://git.zx2c4.com -O git.zx2c4.com.html
# perl -ane "while (m|<td class='toplevel-repo'><a title='([^']*)'|g){print \"https://git.zx2c4.com/\$1\n\";}" < git.zx2c4.com.html > git.zx2c4.com.$DT
# cat git.zx2c4.com.$DT | \
# while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g';
# done | gzip > git.zx2c4.com.$DT.heads &

# wget http://git.eclipse.org/ -O git.eclipse.org.html
# perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.eclipse.org\$1\n\";}" < git.eclipse.org.html | sed 's|/c/|/r/|' > git.eclipse.org.$DT
# cat git.eclipse.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.eclipse.org.$DT.heads &


# wget http://git.postgresql.org -O git.postgresql.org.html
# perl -ane 'while(m|<a class="list" href="/gitweb/\?p=([^"]*);a=summary"|g){print "https://git.postgresql.org/git/$1\n"}' < git.postgresql.org.html | sort -u > git.postgresql.org.$DT
# cat git.postgresql.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.postgresql.org.$DT.heads &

# wget http://git.kernel.org  -O git.kernel.org.html
# perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.kernel.org\$1\n\";}" < git.kernel.org.html > git.kernel.org.$DT
# cat git.kernel.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.kernel.org.$DT.heads &


# wget http://git.savannah.gnu.org/cgit -O git.savannah.gnu.org.html
# #perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.savannah.gnu.org\$1\n\";}" < git.savannah.gnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > git.savannah.gnu.org.$DT
# perl -ane "while (m|<td class='toplevel-repo'><a title='([^']*)'|g){print \"https://git.savannah.gnu.org/git/\$1\n\";}" < git.savannah.gnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > git.savannah.gnu.org.$DT
# cat git.savannah.gnu.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.savannah.gnu.org.$DT.heads &

# wget http://git.savannah.nongnu.org/cgit -O git.savannah.nongnu.org.html
# perl -ane "while (m|<td class='toplevel-repo'><a title='([^']*)'|g){print \"https://git.savannah.nongnu.org/git/\$1\n\";}" < git.savannah.nongnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > git.savannah.nongnu.org.$DT
# cat git.savannah.nongnu.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > git.savannah.nongnu.org.$DT.heads &


# #get old repos for gh, these may have changed again
# python3 listU.py gh$PDT repos '{}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > gh$PDT.u
# split -n l/50 -da2 gh$PDT.u gh$PDT.u.
# for j in {00..49}
# do cat gh$PDT.u.$j | while read r; do
#   a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
#   done | gzip > gh$PDT.u.$j.heads &
# done


# wait



# # Get update repos for GL
# python3 listU.py gl$DT repos '{ "last_activity_at" : { "$gt" : "'"$PDTdash"'" }}' http_url_to_repo | sed "s|^b'||;s|'$||"|sort -u > gl$DT.new 
# cat  gl$DT.new | sed 's|https://gitlab.com/|gl:|' | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
# done | gzip > gl$DT.new.heads &

# # Get updated, no-forks for GH
# #python3 listU.py gh$DT repos '{"isFork" : false}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > gh$DT.u
# python3 listU.py gh$DT repos '{ "pushed_at" : { "$gt" : "'"$PDTdash"'"}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > gh$DT.u
# cat gh$PDT.u.*[0-9] | sort -t\; | join -t\; -v2 - gh$DT.u > gh$DT.new.u
# split -n l/50 -da2 gh$DT.new.u gh$DT.u.
# for j in {00..49}
# do cat gh$DT.u.$j | while read r; do
#     a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
#   done | gzip > gh$DT.u.$j.heads &
# done



# # Get updated bb (do heads on all 2M?)
# python3 listU.py bitbucket$DT repos '{ "updated_on" : { "$gt" : "'"$PDTdash"'" } }' full_name | \
#   sed "s|^b'||;s|'$||" | sort -u > bitbucket$DT.new
# split -n l/10 -da1 bitbucket$DT.new bitbucket$DT.new.
# for j in {0..9}
# do cat bitbucket$DT.new.$j | while read r; do
#     a=$(git ls-remote bb:$r | awk '{print ";"$1}'); echo bb:$r$a | sed 's/ //g';
#   done | gzip > bitbucket$DT.new.$j.heads &
# done

# wait

# #dump all the collected mongo data
# #mongodump 
# #${un[$i]} ${ps[$i]} 
