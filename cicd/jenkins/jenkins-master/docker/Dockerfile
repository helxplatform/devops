FROM jenkins/jenkins:lts
 
USER root
RUN apt-get update -qq && \
    apt-get install -qqy apt-transport-https ca-certificates curl gnupg2 \
    software-properties-common gir1.2-glib-2.0 gir1.2-packagekitglib-1.0 \
    python-apt-common python3 python3-venv python3-dbus python3-gi \
    python3-software-properties less vim-tiny
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" && \
    apt-get update  -qq && \
    apt-cache madison docker-ce && \
    apt-get install docker-ce=5:19.03.12~3-0~debian-stretch \
        docker-ce-cli=5:19.03.12~3-0~debian-stretch containerd.io -y
#RUN groupadd docker && \
RUN  usermod -aG docker jenkins
USER jenkins
