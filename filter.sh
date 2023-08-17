cat todo | while read f
do zcat $f 
done | perl -e 'while(<STDIN>){chop(); ($u, @h) = split (/\;/, $_, -1); $u=$uo if $u eq "";$uo=$u;for $h0 (@h){print "$h0;$#h;$u\n" if $h0=~m|^[0-f]{40}$|}}' | \
     uniq | perl /home/audris/bin/hasObj1.perl commit | cut -d\; -f3 | uniq 
#done | perl -e 'while(<STDIN>){chop(); ($u, @h) = split (/\;/, $_, -1); $u=$uo if $u eq "";$uo=$u;for $h0 (@h){print "$h0;$#h;$u\n" if $h0=~m|^[0-f]{40}$|}}' | \
#     uniq | perl /home/lgonzal6/bin/hasObj1.perl commit | cut -d\; -f3 | uniq 