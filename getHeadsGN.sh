cat gitlab.gnome.org | sed 's|https://gitlab.gnome.org/||;s|^|gl_gnome:|;s|\.git$||' | \
while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
