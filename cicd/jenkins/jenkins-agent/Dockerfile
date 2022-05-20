FROM jenkins/inbound-agent:4.13-2-jdk11

ARG JENKINSUID=1000
ARG JENKINSGID=1000
ARG DOCKERGID=999
ARG SUDOGID=27

USER root

# Note: removed libreadline-gplv2-dev and python-pip
RUN echo "deb http://ftp.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list && \
  apt-get update -qq && \
  apt-get install -qqy curl libssl1.1 acl apt-transport-https build-essential ca-certificates gettext-base \
    gnupg gnupg2 less libc6-dev libffi-dev libgdm-dev libncursesw5-dev libsqlite3-dev \
    libbz2-dev lsb-release make npm python-apt-common python3 python3-venv python3-dbus python3-gi \
    python python3-software-properties python3-wheel python3-setuptools ruby ruby-bundler \
    software-properties-common sudo tk-dev vim-tiny zlib1g-dev libssl-dev

RUN apt-get install -qqy fonts-liberation libasound2 libatk1.0-0 libc6 libcairo2 \
    libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm-dev libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 \
    libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
    libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 \
    libxrender1 libxss1 libxtst6 wget xdg-utils && \
  curl -L http://ftp.us.debian.org/debian/pool/main/libi/libindicator/libindicator7_0.5.0-4_amd64.deb \
     -o libindicator7_0.5.0-4_amd64.deb && \
  apt-get -y install ./libindicator7_0.5.0-4_amd64.deb && \
  curl -L http://ftp.us.debian.org/debian/pool/main/liba/libappindicator/libappindicator1_0.4.92-7_amd64.deb \
     -o ./libappindicator1_0.4.92-7_amd64.deb && \
  apt-get -y install ./libappindicator1_0.4.92-7_amd64.deb

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | \
  apt-key add - && \
  apt-key fingerprint 0EBFCD88

RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
  apt-get update && \
  apt-get install -qqy docker-ce docker-ce-cli && \
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64" \
     -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose && \
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  curl -L https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64 \
     -o /usr/local/bin/clair-scanner && \
  chmod +x /usr/local/bin/clair-scanner && \
  ln -s /usr/local/bin/clair-scanner /usr/bin/clair-scanner

RUN apt-get install python3.9

# INSTALL NODE.JS:
RUN npm cache clean --force && \
  npm install npm -g && \
  npm install n -g && \
  n lts

ENV USER jenkins
ENV UID 1000

# Setup users and groups
RUN groupmod -g ${JENKINSGID} jenkins && \
  groupmod -g ${DOCKERGID} docker && \
  usermod -g ${JENKINSGID} -G ${DOCKERGID},${SUDOGID} -u ${JENKINSUID} jenkins && \
  usermod -p '$6$zltyyttlas$DwfqAq2l5HlUE2WnEUhFtAi1Je3YE2uH50fdyyUmUjoXzmzZGm3ch4eaT/N6O62JgSKdhy0tslF/f8dNdXZQt/' jenkins && \
  touch /var/run/docker.sock && \
  chown root:docker /var/run/docker.sock && \
  chmod 660 /var/run/docker.sock && \
  ls -l /var/run/docker.sock && \
  setfacl -m user:$USER:rw /var/run/docker.sock && \
  getfacl /var/run/docker.sock

USER jenkins

# Create empty whitelist so command can be set up once for all time
RUN pwd && \
  ls -l && \
  mkdir /home/jenkins/clair && \
  mkdir /home/jenkins/clair/whitelists && \
  touch /home/jenkins/clair/whitelists/common-whitelist.yaml
