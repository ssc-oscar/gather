#!/bin/bash
i=$1
sed -i 's/^$/+ : '$i' : ALL/' /etc/security/access.conf
echo "$i ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$i
/usr/sbin/sssd -fd 2
sudo -H -u $i sh -c /bin/bash
