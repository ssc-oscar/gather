cat gl201903.new | sed 's|https://gitlab.com/||;s|^|gl:|;s|\.git$||' | \
while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
