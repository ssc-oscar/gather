#!/bin/bash

# run2410.sh
# In the first stage bbRepos.py, glRepos.py, and ghUpdatedRepos.py populate mongodb, which is then used to
# get project list, while the rest populate project list into XXXX.$DT
# all XXXX.$DT need to be copied to da cluster
# 
# In the second stage the check for latest objects is produced vi ls-relote
# second stage typically requires a much larger disk to store *.heads
# all *.heads need to be copied to da cluster
# Last Modified By: Luis Gonzalez Villalobos
# Last Modified Date: 10/31/2024

# GLOBALS
DT=202410
DTdash=2024-10-31
PDT=202406
PDTdash=2024-06-01
PT=$(date -d"$PDTdash" +%s)
T=$(date -d"$DTdash" +%s)

# Dir path to dump all collected data
# Typically, all logs and head files would stay in the gather dir
# This path is configurable so that we can direct log and headsfile a partition with enough space
# MODIFY THIS - CURRENTLY TAILORED FOR EXOSPHERE MACHINE
# /home/exouser/24q3 is a link to shared drive /media/volume/WoC-Data/discovery/24q3
DATA_PATH="/home/exouser/24q3"

# Test Remotes
# done through ssh_config -> ~/.ssh/config
# requires adding keys to each remote
function test_remotes() {
  git ls-remote bb:swsc/lookup
  git ls-remote gh:fdac20/news
  git ls-remote gh:php/php-src
  git ls-remote gl:inkscape/inkscape
  git ls-remote gl_gnome:GNOME/gtk
  git ls-remote dr:project/drupal
  git ls-remote deb:dpkg-team/dpkg
}

function github_discovery() {
  # 1) Github scrape: Requires tokens

  # Following fragment was used previously for splitting whole time between scrapes
  # We now use one of the six available keys to do a whole day discovery
  # Fragment can be used to split for daily scrape further
  # The objective is to have one day split in hours intervals for a daily GH scrape

  # OLD FRAGMENT TO SPLIT TOKENS:
  # ntok=$(cat tokens|wc -l)
  # inc=$(( ($T-$PT)/$ntok ))
  # for i in $(eval "echo {1..$ntok}")
  # do ptt=$(date -d"@"$(($PT+($i-1)*$inc)) +"%Y-%m-%d")
  #    tt=$(date -d"@"$(($PT+($i)*$inc)) +"%Y-%m-%d")
  #    echo $(head -$i tokens|tail -1) $ptt $tt 
  # done > tokens_date

  # Ran: token_date_01, 02, 03, 04, 05, 06, 07, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26
  # Final: done!
  for i in {1..6}; do (r=$(head -$i token_date_26|tail -1); echo $r | python3 ghUpdatedReposWithCount.py gh$DT repos  &> $DATA_PATH/ghReposList$(echo $r | cut -d ' ' -f2).updt) & done
}

function bitbucket_discovery() {
  # 2) BitBucket scrape
  # BB: need to extract all, no way to check for updated ones
  # All these were last obtained on 24Q2 (during run2406.sh)
  #python3 bbRepos.py 1980-01-01 bitbucket$DT 2013-00-01 &> $DATA_PATH/bbRepos${DT}1.out &
  #python3 bbRepos.py 2013-01-01 bitbucket$DT 2014-05-03 &> $DATA_PATH/bbRepos${DT}2.out &
  #python3 bbRepos.py 2014-05-03 bitbucket$DT 2015-05-03 &> $DATA_PATH/bbRepos${DT}3.out &
  #python3 bbRepos.py 2015-05-03 bitbucket$DT 2016-05-03 &> $DATA_PATH/bbRepos${DT}4.out &
  #python3 bbRepos.py 2016-05-03 bitbucket$DT 2017-05-03 &> $DATA_PATH/bbRepos${DT}5.out &
  #python3 bbRepos.py 2017-05-03 bitbucket$DT 2018-05-03 &> $DATA_PATH/bbRepos${DT}6.out &
  #python3 bbRepos.py 2018-05-03 bitbucket$DT 2019-05-03 &> $DATA_PATH/bbRepos${DT}7.out &
  #python3 bbRepos.py 2019-05-03 bitbucket$DT 2020-05-01 &> $DATA_PATH/bbRepos${DT}8.out &
  #python3 bbRepos.py 2020-05-03 bitbucket$DT 2021-05-01 &> $DATA_PATH/bbRepos${DT}9.out &
  #python3 bbRepos.py 2021-05-01 bitbucket$DT 2022-05-03 &> $DATA_PATH/bbRepos${DT}10.out &
  #python3 bbRepos.py 2022-05-03 bitbucket$DT 2023-05-03 &> $DATA_PATH/bbRepos${DT}11.out &
  #python3 bbRepos.py 2023-05-03 bitbucket$DT 2024-05-03 &> $DATA_PATH/bbRepos${DT}12.out &

  # Get only new, use heads for existing repos
  python3 bbRepos.py 2024-05-03 bitbucket$DT 2025-05-03 &> $DATA_PATH/bbRepos${DT}0.out &
}

function sf_discovery() {
  # 3) SF scrape
  python3 sfRepos.py sf$DT repos &> $DATA_PATH/sfRepos$DT.out
  python3 listU.py sf$DT repos '{}' url | sed "s|b'https://sourceforge.net/projects/||;s|'$||;" | sort -u > $DATA_PATH/sf$DT.prj
}

function gitlab_discovery() {
  # 4) Gitlab scrape
  python3 glRepos.py 1 gl$DT repos &> $DATA_PATH/gl$DT.out &
}

function other_forges() {
  # Do other forges git.bioconductor.org, 
  wget http://git.bioconductor.org -O $DATA_PATH/bio.html
  cat $DATA_PATH/bio.html | awk '{print $2}' | grep / | grep -v '\*' | awk '{ print "https://git.bioconductor.org/"$1}' > $DATA_PATH/bioconductor.org.$DT 
  cat $DATA_PATH/bioconductor.org.$DT | \
  while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
  done | gzip > $DATA_PATH/bioconductor.org.$DT.heads &

  wget "blitiri.com.ar/git/" -O $DATA_PATH/blitiri.com.ar.html
  # wget "blitiri.com.ar/git/" --no-check-certificate -O blitiri.com.ar.html
  grep '<td class="name"><a href="' $DATA_PATH/blitiri.com.ar.html|sed 's|^\s*<td class="name"><a href="||;s|".*||' | sort -u | awk '{print "https://blitiri.com.ar/git/"$1}' > $DATA_PATH/blitiri.com.ar.$DT

  # fedorapeople.org
  u=fedorapeople.org
  wget "https://$u" -O $DATA_PATH/$u.html
  # wget "https://$u" --no-check-certificate -O $u.html
  grep 'Git repositories' $DATA_PATH/$u.html|sed 's|<a href="||;s|".*||;s|^\s*||' | sort -u > $DATA_PATH/$u.$DT

  u=code.qt.io
  wget "https://$u/cgit/" -O  $DATA_PATH/$u.html
  grep 'toplevel-repo' $DATA_PATH/$u.html| sed "s|.*href='/cgit/|/cgit/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $DATA_PATH/$u.$DT

  u=git.alpinelinux.org
  wget "https://$u" -O $DATA_PATH/$u.html
  # wget "https://$u" --no-check-certificate -O $u.html
  grep 'toplevel-repo' $DATA_PATH/$u.html | sed "s|.*href='/|/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $DATA_PATH/$u.$DT

  u=git.openembedded.org 
  wget "https://$u" -O $DATA_PATH/$u.html
  # wget "https://$u" --no-check-certificate -O $u.html
  grep 'toplevel-repo' $DATA_PATH/$u.html | sed "s|.*' href='/|/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $DATA_PATH/$u.$DT

  for u in git.torproject.org git.xfce.org git.yoctoproject.org
  do wget "https://$u" -O $DATA_PATH/$u.html
  #do wget "https://$u" --no-check-certificate -O $u.html
  grep -E '(sublevel|toplevel)-repo' $DATA_PATH/$u.html | sed "s|.*' href='/|/|;s|'.*||"|sort -u | awk '{print "https://'$u'"$1}' > $DATA_PATH/$u.$DT
  done

  wget "https://repo.or.cz/?a=project_list" -O $DATA_PATH/cz.html
  # wget "https://repo.or.cz/?a=project_list" --no-check-certificate -O cz.html
  grep '\.git' $DATA_PATH/cz.html  | sed 's|.*"/\([^/"]*\.git\).*|\1|' | uniq | sort -u | awk '{print "https://repo.or.cz/"$1}'> $DATA_PATH/repo.or.cz.$DT
  cat $DATA_PATH/repo.or.cz.$DT | \
  while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
  done | gzip > $DATA_PATH/repo.or.cz.$DT.heads &

  wget "https://gitbox.apache.org/repos/asf" -O $DATA_PATH/gitbox.apache.org.html
  grep '<td><a href="/repos/asf/[^\?]' $DATA_PATH/gitbox.apache.org.html|sed 's|.*<td><a href="/||;s|".*||' | sort -u | awk '{print "https://gitbox.apache.org/"$1}' > $DATA_PATH/gitbox.apache.org.$DT

  echo https://gcc.gnu.org/git/gcc.git > $DATA_PATH/gcc.git.$DT

  for i in {1..50}
  do wget "https://pagure.io/?page=$i&sorting=None" -O $DATA_PATH/pagure.io.html
  # do wget "https://pagure.io/?page=$i&sorting=None" --no-check-certificate -O pagure.io.html
    grep '^\s*<a href="/' $DATA_PATH/pagure.io.html |sed 's|^\s*<a href="||;s|".*||'|grep -Ev '^/(about|ssh_info)$' 
  done | uniq | sort -u | awk '{print "https://pagure.io"$1}' > $DATA_PATH/pagure.io.$DT 

  u=notabug.org	 
  for i in {1..50}
  do wget "https://$u/explore/repos?page=$i&q=" -O $DATA_PATH/$u.html
  # do wget "https://$u/explore/repos?page=$i&q=" --no-check-certificate -O $u.html
    grep '<a class="name" href="/' $DATA_PATH/$u.html |sed 's|<a class="name" href="/|/|;s|".*||'
  done |sort -u | awk '{print "https://'$u'"$1}' >  $DATA_PATH/$u.$DT

  for u in framagit.org gitlab.adullact.net code.ill.fr forgemia.inra.fr git.unicaen.fr git.unistra.fr git.pleroma.social gitlab.fing.edu.uy gitlab.huma-num.fr  gitlab.irstea.fr gitlab.cerema.fr gite.lirmm.fr gitlab.common-lisp.net 
  do for i in {1..50}
  do sleep 2; wget "https://$u/explore/projects?non_archived=true&page=$i&sort=name_asc" -O $DATA_PATH/$u.html
  # do sleep 2; wget "https://$u/explore/projects?non_archived=true&page=$i&sort=name_asc" --no-check-certificate -O $u.html
    grep '<a class="project" href="' $DATA_PATH/$u.html | sed 's|<a class="project" href="||;s|".*||' 
  done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $DATA_PATH/$u.$DT  
  done

  for u in gitlab.freedesktop.org gitlab.inria.fr gitlab.ow2.org 0xacab.org invent.kde.org 
  do for i in {1..50}
    do for o in latest_activity_desc name_asc name_desc created_desc created_asc 
      do sleep 2; wget "https://$u/explore/projects?non_archived=true&page=$i&sort=$o" -O $DATA_PATH/$u.html
#       do sleep 2; wget "https://$u/explore/projects?non_archived=true&page=$i&sort=$o" --no-check-certificate -O $u.html
        grep '<a class="project" href="' $DATA_PATH/$u.html | sed 's|<a class="project" href="||;s|".*||' 
      done
    done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $DATA_PATH/$u.a.$DT  
    for i in {1..50}
    do for o in latest_activity_desc name_asc name_desc created_desc created_asc
      do sleep 2; wget "https://$u/explore/projects/starred?non_archived=true&page=$i&sort=$o" -O $DATA_PATH/$u.html
#      do sleep 2; wget "https://$u/explore/projects/starred?non_archived=true&page=$i&sort=$o" --no-check-certificate -O $u.html
      grep '<a class="project" href="' $DATA_PATH/$u.html | sed 's|<a class="project" href="||;s|".*||'
      done
    done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $DATA_PATH/$u.s.$DT  
    for i in {1..50}
    do for o in latest_activity_desc name_asc name_desc created_desc created_asc
      do sleep 2; wget "https://$u/explore/projects/trending?non_archived=true&page=$i&sort=$o" -O $DATA_PATH/$u.html
#       do sleep 2; wget "https://$u/explore/projects/trending?non_archived=true&page=$i&sort=$o" --no-check-certificate -O $u.html
        grep '<a class="project" href="' $DATA_PATH/$u.html | sed 's|<a class="project" href="||;s|".*||' 
      done
    done | uniq | sort -u | awk '{print "https://'$u'"$1}' >  $DATA_PATH/$u.t.$DT  

    cat $DATA_PATH/$u.?.$DT | sort -u > $DATA_PATH/$u.$DT 
  done

  # TODO: Figured it out but we get some invalid references; See Gather_Notes
  #       The invalid refs are around 50, so no need to worry

  cat $DATA_PATH/invent.kde.org.$DT | \
  while read r; do r="$r.git";a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a | sed 's/ //g'; 
  done | gzip > $DATA_PATH/invent.kde.org.$DT.heads &

  # Capturing the following:
  # * repo.or.cz.$DT 
  # * gitlab.gnome.org.$DT 
  # * android.googlesource.com.$DT 
  # * git.zx2c4.com.$DT 
  # * git.eclipse.org.$DT 
  # * git.kernel.org.$DT 
  # * git.savannah.gnu.org.$DT 
  # * git.savannah.nongnu.org.$DT

  # fedorapeople.org.$DT list peoples git websites: need to append /public_git/ to get their projects
  cat $DATA_PATH/fedorapeople.org.$DT|sed 's|^\s*||'|while read r; do wget "$r/public_git" -O -; done >  $DATA_PATH/fedorapeople.org.fix.$DT.html
  # cat fedorapeople.org.$DT|sed 's|^\s*||'|while read r; do wget "$r/public_git" --no-check-certificate -O -; done >  fedorapeople.org.fix.$DT.html
  grep /public_git/  $DATA_PATH/fedorapeople.org.fix.$DT.html|  sed "s|.* href='/cgit/||;s|'.*||;s|/tree/$||;s|^|https://fedorapeople.org/cgit/|" | sort -u > $DATA_PATH/fedorapeople.org.fix.$DT

  #git.pleroma.social.$DT - seems not to allow listing
  echo https://git.pleroma.social/pleroma/pleroma > $DATA_PATH/git.pleroma.social.$DT

  for i in $DATA_PATH/fedorapeople.org.fix.$DT $DATA_PATH/pagure.io.$DT $DATA_PATH/blitiri.com.ar.$DT $DATA_PATH/code.qt.io.$DT $DATA_PATH/gitlab.common-lisp.net.$DT $DATA_PATH/code.ill.fr.$DT $DATA_PATH/forgemia.inra.fr.$DT $DATA_PATH/git.unicaen.fr.$DT $DATA_PATH/notabug.org.$DT $DATA_PATH/git.unistra.fr.$DT $DATA_PATH/gcc.git.$DT $DATA_PATH/gitlab.fing.edu.uy.$DT $DATA_PATH/gitlab.huma-num.fr.$DT $DATA_PATH/gitlab.adullact.net.$DT $DATA_PATH/gitlab.irstea.fr.$DT $DATA_PATH/git.alpinelinux.org.$DT $DATA_PATH/gitlab.cerema.fr.$DT $DATA_PATH/git.openembedded.org.$DT $DATA_PATH/gite.lirmm.fr.$DT $DATA_PATH/git.torproject.org.$DT $DATA_PATH/git.xfce.org.$DT $DATA_PATH/git.yoctoproject.org.$DT $DATA_PATH/framagit.org.$DT $DATA_PATH/gitlab.freedesktop.org.$DT  $DATA_PATH/gitlab.ow2.org.$DT $DATA_PATH/gitbox.apache.org.$DT $DATA_PATH/gitlab.inria.fr.$DT
  do (sed 's|/\.git/$||;s|^\s*||;s|//|//a:a@|;s|/tree/$||;s|/$||;s|blitiri.com.ar/git/r/|blitiri.com.ar/repos/|;' $i | while read r; do a=$(git ls-remote "$r" 2> $i.err| awk '{print ";"$1}'); echo "$r$a"|sed 's/ //g'; done| gzip > $DATA_PATH/$i.heads; sleep 2) &
  done

  # pages 1-300
  # https://gitlab.gnome.org/explore/projects?page=300&sort=latest_activity_desc
  # insert username/password to prevend password requests
  # UPDATE: Max number of pages is 50 (3/15/23)
  for p in {1..50}
  do sleep 2; wget "https://gitlab.gnome.org/explore/projects?page=$p" -O - 2> /dev/null | perl -ane 'chop();if (m|^<a class="project" href="|){s|<a class="project" href="||;s|".*||;s|^/||;print "https://a:a\@gitlab.gnome.org/$_\n"}'
  # do sleep 2; wget "https://gitlab.gnome.org/explore/projects?page=$p" --no-check-certificate -O - 2> /dev/null | perl -ane 'chop();if (m|^<a class="project" href="|){s|<a class="project" href="||;s|".*||;s|^/||;print "https://a:a\@gitlab.gnome.org/$_\n"}'
  done | sort -u > $DATA_PATH/gitlab.gnome.org.$DT

  for p in {1..50}
  do sleep 2;wget "https://gitlab.gnome.org/explore/projects?page=$p&sort=latest_activity_desc" -O - 2> /dev/null | perl -ane 'chop();if (m|^<a class="project" href="|){s|<a class="project" href="||;s|".*||;s|^/||;print "https://a:a\@gitlab.gnome.org/$_\n"}'
  # do sleep 2;wget "https://gitlab.gnome.org/explore/projects?page=$p&sort=latest_activity_desc" --no-check-certificate -O - 2> /dev/null | perl -ane 'chop();if (m|^<a class="project" href="|){s|<a class="project" href="||;s|".*||;s|^/||;print "https://a:a\@gitlab.gnome.org/$_\n"}'
  done | sort -u > $DATA_PATH/gitlab.gnome.org_latest.$DT

  cat $DATA_PATH/gitlab.gnome.org.$DT $DATA_PATH/gitlab.gnome.org_latest.$DT | sort -u | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > $DATA_PATH/gitlab.gnome.org.$DT.heads &

  # pages 1-1530 
  # UPDATE: Again max 50 pages, it recommends on using the API
  # git.debian.org -> https://salsa.debian.org/explore/projects?page=1540&sort=latest_activity_desc
  for of in {0..9}; do 
  for p in $(eval "echo {$((1+$of*20))..$((20+$of*20))}")
  do wget "https://salsa.debian.org/explore/projects?page=$p&sort=latest_activity_desc"  -O - 2> /dev/null | perl -ane 'chop(); while (m|<a class="project" href="([^"]*)"|g){print "https://a:a\@salsa.debian.org$1.git\n"}'
    done > $DATA_PATH/git.debian.org.$DT.$of 
  done &
  wait
  for of in {0..9}; do
    cat $DATA_PATH/git.debian.org.$DT.$of | while read r; do a=$(git ls-remote $r 2> err | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; sleep 20; done | gzip > $DATA_PATH/git.debian.org.$DT.$of.heads 
  done

  # sort=name_desc
  # Add following forges as well
  # android.git.kernel.org ??

  # there are totally 2398 pages in https://git.drupalcode.org/explore/projects
  # Again, max 50. Need to use API
  thost="https://git.drupalcode.org/explore/projects?page="
  i=0
  rm drupal.org
  for i in {1..50}
  do 
    rhost="$thost$i".'&sort=latest_activity_desc';
    curl -o $DATA_PATH/drupal0.html  $rhost;
    rhost="$thost$i".'&sort=latest_activity_asc';
    curl -o $DATA_PATH/drupal1.html  $rhost;
    rhost="$thost$i".'&sort=created_desc';
    curl -o $DATA_PATH/drupal2.html  $rhost;
    rhost="$thost$i".'&sort=created_asc';
    curl -o $DATA_PATH/drupal3.html  $rhost;
    rhost="$thost$i".'&sort=name_asc';
    curl -o $DATA_PATH/drupal4.html  $rhost;
    rhost="$thost$i".'&sort=name_desc';
    curl -o $DATA_PATH/drupal5.html  $rhost;
    rhost="$thost$i".'&sort=stars_desc';
    curl -o $DATA_PATH/drupal6.html  $rhost;
    rhost="$thost$i".'&sort=stars_asc';
    curl -o $DATA_PATH/drupal7.html  $rhost;

    #if j==-1,this is invalid page,we have gotten all pages successfully. 
    for t in {0..7}
    do j=$(perl -e '$e=0;while(<STDIN>){if(m|<h5>This user doesn|){$e=-1;last;};}; print "$e\n"' < $DATA_PATH/drupal$t.html);
      if [ "$j" -eq "-1" ]; then break; fi;
      #all urls will be stored in ./drupal.com
      perl -ane 'while(m|<span class="project-name">([^<]*)</span>|g){print "https://git.drupalcode.org/project/$1\n"}' < $DATA_PATH/drupal$t.html >> $DATA_PATH/drupal.com.$DT;
      if [ `expr $i % 10` -eq 0 ]; then  sleep 2; fi;
    done
  done &

  sort -u  $DATA_PATH/drupal.com.$DT > $DATA_PATH/drupal.com.$DT.u
  mv $DATA_PATH/drupal.com.$DT.u $DATA_PATH/drupal.com.$DT
  cat $DATA_PATH/drupal.com.$DT| sed  's|.*/project/|dr:project/|'  | \
  while read r; do git ls-remote $r | grep -E 'refs/heads|HEAD' | sed 's|\s*refs/heads/|;|;s|\s*HEAD|;HEAD|;s|^|'$r';|';
  done | gzip > $DATA_PATH/drupal.com.$DT.heads &

  wget https://android.googlesource.com/ -O $DATA_PATH/android.googlesource.com.html
  perl -ane 'while(m|class="RepoList-itemName">([^<]*)</|g){print "https://android.googlesource.com/$1\n";}' < $DATA_PATH/android.googlesource.com.html > $DATA_PATH/android.googlesource.com.$DT
  cat $DATA_PATH/android.googlesource.com.$DT | \
  while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g';
  done | gzip > $DATA_PATH/android.googlesource.com.$DT.heads &

  wget https://git.zx2c4.com -O $DATA_PATH/git.zx2c4.com.html
  # wget https://git.zx2c4.com --no-check-certificate -O git.zx2c4.com.html
  perl -ane "while (m|<td class='toplevel-repo'><a title='([^']*)'|g){print \"https://git.zx2c4.com/\$1\n\";}" < $DATA_PATH/git.zx2c4.com.html > $DATA_PATH/git.zx2c4.com.$DT
  cat $DATA_PATH/git.zx2c4.com.$DT | \
  while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g';
  done | gzip > $DATA_PATH/git.zx2c4.com.$DT.heads &

  wget http://git.eclipse.org/ -O $DATA_PATH/git.eclipse.org.html
  perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.eclipse.org\$1\n\";}" < $DATA_PATH/git.eclipse.org.html | sed 's|/c/|/r/|' > $DATA_PATH/git.eclipse.org.$DT
  cat $DATA_PATH/git.eclipse.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > $DATA_PATH/git.eclipse.org.$DT.heads &


  wget http://git.postgresql.org -O $DATA_PATH/git.postgresql.org.html
  perl -ane 'while(m|<a class="list" href="/gitweb/\?p=([^"]*);a=summary"|g){print "https://git.postgresql.org/git/$1\n"}' < $DATA_PATH/git.postgresql.org.html | sort -u > $DATA_PATH/git.postgresql.org.$DT
  cat $DATA_PATH/git.postgresql.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > $DATA_PATH/git.postgresql.org.$DT.heads &

  wget http://git.savannah.gnu.org/cgit --no-check-certificate -O $DATA_PATH/git.savannah.gnu.org.html
  # #perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.savannah.gnu.org\$1\n\";}" < git.savannah.gnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > git.savannah.gnu.org.$DT
  #perl -ane "while (m|<td class='toplevel-repo'><a title='([^']*)'|g){print \"https://git.savannah.gnu.org/git/\$1\n\";}" < git.savannah.gnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > git.savannah.gnu.org.$DT
  perl -ane "if (m|'/cgit/.*noalyss.git/([^\'/]*)/tree/|){print \"https://git.savannah.gnu.org/git/\$1\\n\";}
  " < $DATA_PATH/git.savannah.nongnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > $DATA_PATH/git.savannah.gnu.org.$DT; 
  cat $DATA_PATH/git.savannah.gnu.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > $DATA_PATH/git.savannah.gnu.org.$DT.heads &

  wget http://git.savannah.nongnu.org/cgit -O $DATA_PATH/git.savannah.nongnu.org.html
  # wget http://git.savannah.nongnu.org/cgit --no-check-certificate -O git.savannah.nongnu.org.html
  perl -ane 'if (m|.*noalyss.git/(.*)/tree|){print "https://git.savannah.nongnu.org/git/$1\n";}' < $DATA_PATH/git.savannah.nongnu.org.html | sed 's|/cgit/|/git/|' | sort -u  > $DATA_PATH/git.savannah.nongnu.org.$DT
  cat $DATA_PATH/git.savannah.nongnu.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > $DATA_PATH/git.savannah.nongnu.org.$DT.heads &

  wget http://git.kernel.org -O $DATA_PATH/git.kernel.org.html
  # wget http://git.kernel.org --no-check-certificate  -O git.kernel.org.html
  perl -ane "while (m|<td class='sublevel-repo'><a title='[^']*' href='([^']*)'|g){print \"https://git.kernel.org\$1\n\";}" < $DATA_PATH/git.kernel.org.html > $DATA_PATH/git.kernel.org.$DT
  cat $DATA_PATH/git.kernel.org.$DT | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; done | gzip > $DATA_PATH/git.kernel.org.$DT.heads &
}

function sf_heads() {
  # Split for parallel processing
  split -n l/10 -da1 $DATA_PATH/sf$DT.prj $DATA_PATH/sf$DT.prj.
  for i in {0..9}
  do cat $DATA_PATH/sf$DT.prj.$i | while read r; 
    do gg=$(git ls-remote "https://git.code.sf.net/p/$r/git" 2> /dev/null| awk '{print ";"$1}')
      cc=$(git ls-remote "https://git.code.sf.net/p/$r/code" 2> /dev/null| awk '{print ";"$1}');  
      [[ $gg == "" ]] || echo https://git.code.sf.net/p/$r/git$gg |sed 's/ ;/;/g'
      [[ $cc == "" ]] || echo https://git.code.sf.net/p/$r/code$cc|sed 's/ ;/;/g'; 
      done | gzip > $DATA_PATH/sf$DT.prj.$i.heads &
  done

  # Now, do for existing
  zcat $DATA_PATH/sf$PDT.prj.*.heads
}

function update_old_gh_repos() {
  # get old repos for gh, these may have changed again
  # Need to restore the previous db, use: mongorestore --host localhost:27017 --gzip -d gh$PDT <path_to_dump_files>/repos.bson.gz
  python3 listU.py gh$PDT repos '{}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > $DATA_PATH/gh$PDT.u
  split -n l/50 -da2 $DATA_PATH/gh$PDT.u $DATA_PATH/gh$PDT.u.
  for j in {00..49}
  do cat $DATA_PATH/gh$PDT.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
    done | gzip > $DATA_PATH/gh$PDT.u.$j.heads &
  done
}

function gl_heads() {
  # Get update repos for GL
  python3 listU.py gl$DT repos '{ "last_activity_at" : { "$gt" : "'"$PDTdash"'" }}' http_url_to_repo | sed "s|^b'||;s|'$||"|sort -u > $DATA_PATH/gl$DT.new 
  cat $DATA_PATH/gl$DT.new | sed 's|https://gitlab.com/|gl:|' | while read r; do a=$(git ls-remote $r | awk '{print ";"$1}'); echo $r$a|sed 's/ //g'; 
  done | gzip > $DATA_PATH/gl$DT.new.heads &
}

function gh_heads() {
  # Get updated, no-forks for GH
  #python3 listU.py gh$DT repos '{"isFork" : false}' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > gh$DT.u
  python3 listU.py gh$DT repos '{ "pushedAt" : { "$gt" : "'"$PDTdash"'"} }' nameWithOwner | sed "s|^b'||;s|'$||" | sort -u > $DATA_PATH/gh$DT.u
  # cat gh$PDT.u.*[0-9] | sort -t\; | join -t\; -v2 - gh$DT.u > gh$DT.new.u
  split -n l/50 -da2 $DATA_PATH/gh$DT.u $DATA_PATH/gh$DT.u.
  
  for j in {00..12}
  do cat $DATA_PATH/gh$DT.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
    done | gzip > $DATA_PATH/gh$DT.u.$j.heads &
  done
  for j in {13..26}
  do cat $DATA_PATH/gh$DT.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
    done | gzip > $DATA_PATH/gh$DT.u.$j.heads &
  done
  for j in {26..38}
  do cat $DATA_PATH/gh$DT.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
    done | gzip > $DATA_PATH/gh$DT.u.$j.heads &
  done
  for j in {39..49}
  do cat $DATA_PATH/gh$DT.u.$j | while read r; do
    a=$(git ls-remote gh:$r | awk '{print ";"$1}'); echo gh:$r$a | sed 's/ //g';
    done | gzip > $DATA_PATH/gh$DT.u.$j.heads &
  done
}

function bb_heads() {
  # Get updated bb (do heads on all 2M?)
  python3 listU.py bitbucket$DT repos '{ "updated_on" : { "$gt" : "'"$PDTdash"'" } }' full_name | \
     sed "s|^b'||;s|'$||" | sort -u > $DATA_PATH/bitbucket$DT.new
  split -n l/10 -da1 $DATA_PATH/bitbucket$DT.new $DATA_PATH/bitbucket$DT.new.
  for j in {0..9}
  do cat $DATA_PATH/bitbucket$DT.new.$j | while read r; do
    a=$(git ls-remote bb:$r | awk '{print ";"$1}'); echo bb:$r$a | sed 's/ //g';
    done | gzip > $DATA_PATH/bitbucket$DT.new.$j.heads &
  done
}

function dump_mongo() { 
  # dump all DBs and collections to data path
  for i in sf bitbucket gl gh
    do mongodump -d "$i$DT" --out=$DATA_PATH/dump --gzip
  done
}

# Driver
# test_remotes
# github_discovery
# bitbucket_discovery
# sf_discovery
# gitlab_discovery # needs revisit but we captured some
# other_forges
# sf_heads
# update_old_gh_repos
# wait
# gl_heads
# wait
# gh_heads
# wait
# bb_heads
# wait
dump_mongo
exit 1

