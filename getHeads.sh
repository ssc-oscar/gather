for i in git.savannah.gnu.org bioconductor.org.201903 android.googlesource.com git.kernel.org git.zx2c4.com cgit.kde.org git.eclipse.org git.debian.org repo.or.cz drupal.com sf201903.prj git.postgresql.org
do cat $i | while read r; do git ls-remote $r | grep -E 'HEAD|refs/heads' | perl -ane 's/\s+/;/;print "'$r';$_";'
done
done
