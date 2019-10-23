#!/bin/bash

for f in drupal.com.$DT.heads sf$DT.prj.new.heads repo.or.cz.$DT.heads gl$DT.new.heads gitlab.gnome.org.$DT.heads git.zx2c4.com.$DT.heads git.savannah.gnu.org.$DT.heads git.postgresql.org.$DT.heads git.kernel.org.$DT.heads git.eclipse.org.$DT.heads cgit.kde.org.$DT.heads bioconductor.org.$DT.heads android.googlesource.com.$DT.heads git.postgresql.org.$DT.heads;
do zcat $f | grep -v 'could not connect' | \
	 perl -ane 'chop(); ($u, @h) = split (/\;/, $_, -1); for $h0 (@h){print "$h0;$#h;$u\n" if $h0=~m|^[0-f]{40}$|}' | \
	 ssh da4 ~/bin/hasObj1.perl commit | cut -d\; -f3 | uniq > $f.get 
done

for i in {00..29}
do f=gh$DT.u.$i.heads
	zcat $f | grep -v 'could not connect' | \
	perl -ane 'chop(); ($u, @h) = split (/\;/, $_, -1); for $h0 (@h){print "$h0;$#h;$u\n" if $h0=~m|^[0-f]{40}$|}' | \
	ssh da4 ~/bin/hasObj1.perl commit | cut -d\; -f3 | uniq 
done > gh$DT.u.heads.get

for i in {0..9} 
do f=bitbucket$DT.new.$i.heads
	zcat $f | grep -v 'could not connect' | \
	perl -ane 'chop(); ($u, @h) = split (/\;/, $_, -1); for $h0 (@h){print "$h0;$#h;$u\n" if $h0=~m|^[0-f]{40}$|}' | \
	ssh da4 ~/bin/hasObj1.perl commit | cut -d\; -f3 | uniq 
done > bitbucket$DT.new.heads.get

				
for i in {0..9}
do f=git.debian.org.$DT.$i.heads
	zcat $f | grep -v 'could not connect' | \
	perl -ane 'chop(); ($u, @h) = split (/\;/, $_, -1); for $h0 (@h){print "$h0;$#h;$u\n" if $h0=~m|^[0-f]{40}$|}' | \
	ssh da4 ~/bin/hasObj1.perl commit | cut -d\; -f3 | uniq
done > git.debian.org.$DT.heads.get
