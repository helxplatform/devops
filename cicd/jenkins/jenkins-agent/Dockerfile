FROM node:latest AS node_base
FROM jenkins/inbound-agent:4.13-2-jdk11
COPY --from=node_base /opt /opt
COPY --from=node_base /usr/local /usr/local

ARG JENKINSUID=1000
ARG JENKINSGID=1000
ARG DOCKERGID=999
ARG SUDOGID=27

USER root

# Remove old docker
RUN dpkg --remove docker docker-engine docker.io containerd runc

RUN apt-get update && \
    apt-get -y install ca-certificates curl gnupg lsb-release

# Add new docker source
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && \
    apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
    apt-get -y install acl && \
    apt-get -y install python3.9 python3-pip && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 && \
    pip install --upgrade pip && \
    pip install pytest~=7.1 docker~=5.0 pyyaml~=6.0  jinja2~=3.1

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
    #groupmod -g 990 999
    #chmod 666 /var/run/docker.sock

USER jenkins
