cat git.debian.org | sed 's|https://salsa.debian.org/||;s|^|deb:|;s|\.git$||' | \
while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
