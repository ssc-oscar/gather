i=$1
cat ghRepos.$i | sed 's|^|gh:|;s|_|/|' | \
while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
