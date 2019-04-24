cat bitbucket201903.$1 | sed 's|^|bb:|' | \
while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
