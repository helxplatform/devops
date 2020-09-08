FROM jenkins/jenkins:lts
 
USER root

RUN echo "deb http://ftp.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy apt-transport-https ca-certificates curl gnupg2 software-properties-common gir1.2-glib-2.0 gir1.2-packagekitglib-1.0 python-apt-common python3 python3-venv python3-dbus python3-gi python python-pip python3-software-properties python3-pip python3-wheel python3-setuptools sudo less vim-tiny gettext-base

RUN pip  install --upgrade pip wheel setuptools && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update  -qq && \
    apt-cache madison docker-ce && \
    apt-get install docker-ce=5:19.03.12~3-0~debian-stretch docker-ce-cli=5:19.03.12~3-0~debian-stretch containerd.io -y && \
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose && \
    curl -L https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64 -o /usr/local/bin/clair-scanner && \
#    curl https://raw.githubusercontent.com/arminc/clair-scanner/releases/download/v12/clair-scanner_darwin_amd64 -o /usr/local/bin/clair-scanner && \
    chmod +x /usr/local/bin/clair-scanner  && \
    ln -s /usr/local/bin/clair-scanner /usr/bin/clair-scanner

ENV USER jenkins
ENV UID 1000
RUN usermod -aG sudo -p '$6$zltyyttlas$DwfqAq2l5HlUE2WnEUhFtAi1Je3YE2uH50fdyyUmUjoXzmzZGm3ch4eaT/N6O62JgSKdhy0tslF/f8dNdXZQt/' jenkins
# ENV HOME /home/$USER
# RUN useradd -m -b /home -d $HOME --shell /bin/bash --uid $UID -U -G jenkins $USER && \
# RUN groupadd docker

## For Blackbalsam build:
ENV USER2 jovyan
ENV UID2 1003
ENV HOME2 /home/$USER2
RUN useradd -b /home -d $HOME2 -m  --shell /bin/bash --uid $UID2 -U -G jenkins $USER2 && \
    chown -R $UID2:$UID $HOME2 && \
    chmod -R 775 $HOME2

USER jenkins

# Create empty whitelist so command can be set up once for (hopefully) all time
RUN mkdir /var/jenkins_home/clair && \
    mkdir /var/jenkins_home/clair/whitelists && \
    touch /var/jenkins_home/clair/whitelists/common-whitelist.yaml
