FROM ubuntu:latest

MAINTAINER Audris Mockus <audris@mockus.org>

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && DEBIAN_FRONTEND='noninteractive' apt install -y  curl gnupg apt-transport-https

#mongodb
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
#RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN apt update && \
    apt install -y mongodb-org-shell  \
    mongodb-org-tools mongodb-org-mongos \
    libssl-dev \
    libcurl4-openssl-dev \
    openssh-server \
    lsof sudo \
    sssd \
    sssd-tools \
    vim \
    git \
    curl lsb-release \
    vim-runtime tmux zsh zip \
    python3-pymongo python3-requests \ 
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb \
	&& mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb


#install ldap authentication to use utk's ldap: would work only with proper port forwarding
COPY eecsCA_v3.crt /etc/ssl/ 
COPY sssd.conf /etc/sssd/ 
COPY common* /etc/pam.d/ 
RUN chmod 0600 /etc/sssd/sssd.conf /etc/pam.d/common* 
RUN if [ ! -d /var/run/sshd ]; then mkdir /var/run/sshd; chmod 0755 /var/run/sshd; fi

COPY init.sh startsvc.sh startshell.sh notebook.sh startDef.sh /bin/ 

ENV NB_USER audris
ENV NB_UID 22923 
ENV NB_GID 2343
ENV HOME /home/$NB_USER
RUN groupadd -g $NB_GID da
RUN useradd -m -s /bin/bash -N -u $NB_UID -g $NB_GID $NB_USER && mkdir $HOME/.ssh && chown -R $NB_USER:users $HOME 
COPY id_rsa_gcloud.pub $HOME/.ssh/authorized_keys
COPY config $HOME/.ssh/
COPY run*.sh *.py /home/$NB_USER/ 
RUN chown -R $NB_USER:users $HOME && chmod -R og-rwx $HOME/.ssh
