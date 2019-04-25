sort -u drupal.com | sed 's|https://git.drupalcode.org/||;s|^|dr:|;s|\.git$||' | \
while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
