#!/bin/bash
sed -i 's/^$/+ : '$i' : ALL/' /etc/security/access.conf
/usr/sbin/sssd -fd 2
/usr/sbin/sshd -e
/bin/bash
