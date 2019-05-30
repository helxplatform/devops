### Dockerfile for rocker/tidyverse with trial base-layer security improvements, based on Rstudio tidyverse image with additional upgrades ###
FROM rocker/rstudio:3.5.3
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  auditd \
  nano \
  whois \
  curl \
  cron \
  rsyslog \
  libxml2-dev \
  libcairo2-dev \
  libsqlite3-dev \
  libmariadbd-dev \
  libmariadb-client-lgpl-dev \
  unixodbc-dev \
  libssl-dev \
  libssh2-1-dev \
  libpq-dev \
  && install2.r --error \
    --deps TRUE \
    tidyverse \
    dplyr \
    devtools \
    formatR \
    remotes \
    selectr \
    caTools \
    BiocManager
RUN wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz && \
    tar -zxf openssl-1.1.1a.tar.gz && cd openssl-1.1.1a && \
    ./config && \
    apt install make gcc && \
    make && \
    make test && \
    mv /usr/bin/openssl ~/tmp && \
    make install && \
    ln -s /usr/local/bin/openssl /usr/bin/openssl && \
    sudo ldconfig
RUN echo "-a exit,always -F arch=b64 -F euid=0 -S execve -k root" >> /etc/audit/rules.d/audit.rules
RUN echo "-a exit,always -F arch=b32 -F euid=0 -S execve -k root" >> /etc/audit/rules.d/audit.rules
RUN echo "-a exit,always -F arch=b64 -F euid>=1000 -S execve -k useract" >> /etc/audit/rules.d/audit.rules
RUN echo "-a exit,always -F arch=b32 -F euid>=1000 -S execve -k useract" >> /etc/audit/rules.d/audit.rules
RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.0.1-amd64.deb
RUN dpkg -i filebeat-7.0.1-amd64.deb
RUN groupadd rstudio_whitelist -g 1004
RUN echo -n "rstudio ALL=(ALL) ALL" >> /etc/sudoers 
COPY ./user_mgmt.py .
COPY ./filebeat.yml .
RUN cp filebeat.yml /etc/filebeat/filebeat.yml
WORKDIR /home/rstudio
EXPOSE 8787
