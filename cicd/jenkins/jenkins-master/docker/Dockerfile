FROM jenkins/jenkins:2.277.1-lts

USER root

# We have to downgrade libssl to u4 from u5 due to libssl-dev depending on u5
# Will want to track this and remove in the future.
RUN echo "deb http://ftp.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -qqy --allow-downgrades --reinstall libssl1.1=1.1.1d-0+deb10u4 && \
    apt-get install -qqy apt-transport-https ca-certificates curl gcc gnupg2 \
    gir1.2-glib-2.0 gir1.2-packagekitglib-1.0 gettext-base	jq less make\
    netbase python-apt-common ruby ruby-bundler software-properties-common sudo \
    tzdata vim-tiny wget

# Setup python stdlib dependencies
RUN set -ex \
    && apt-get update && apt-get install -y --no-install-recommends \
        dpkg-dev \
        libbluetooth-dev \
        libbz2-dev \
        libc6-dev \
        libexpat1-dev \
        libffi-dev \
        libgdbm-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        tk-dev \
        uuid-dev \
        xz-utils \
        zlib1g-dev;

# Install python3.x
ENV PYTHON_INSTALL_VERSION 3.9.2
RUN wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_INSTALL_VERSION%%[a-z]*}/Python-$PYTHON_INSTALL_VERSION.tar.xz" \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    && cd /usr/src/python \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-optimizations \
        --enable-option-checking=fatal \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
    && make -j "$(nproc)" \
        LDFLAGS="-Wl,--strip-all" \
    && make install \
    && rm -rf /usr/src/python \
    && find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
            -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \
        \) -exec rm -rf '{}' + \
    && ldconfig \
    && python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
    && ln -s idle3 idle \
    && ln -s pydoc3 pydoc \
    && ln -s python3 python \
    && ln -s python3-config python-config

# Install pip
RUN set -ex; \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py; \
    python3 get-pip.py --no-cache-dir ; \
    pip --version; \
    find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +; \
    rm -f get-pip.py;

RUN python -m pip install -U pip; \
    pip install setuptools wheel;

RUN set -ex; \
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
    echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
    apt-get update -qq && \
    apt-get install docker-ce=5:19.03.12~3-0~debian-buster docker-ce-cli=5:19.03.12~3-0~debian-buster containerd.io -y;

RUN set -ex; \
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose;

RUN set -ex; \
    curl -L https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64 -o /usr/local/bin/clair-scanner && \
    chmod +x /usr/local/bin/clair-scanner  && \
    ln -s /usr/local/bin/clair-scanner /usr/bin/clair-scanner && \
    curl -L https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

RUN mkdir ruby && \
    cd ruby && \
    curl https://rubygems.org/rubygems/rubygems-3.1.4.tgz -o rubygems-3.1.4.tgz && \
    tar -xzvf rubygems-3.1.4.tgz && \
    cd rubygems-3.1.4 && \
    ruby setup.rb && \
    gem install json2table

# Cleanup and remove some data we don't need anymore.
RUN set -ex; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*;

ENV USER jenkins
ENV UID 1000
RUN usermod -p '$6$zltyyttlas$DwfqAq2l5HlUE2WnEUhFtAi1Je3YE2uH50fdyyUmUjoXzmzZGm3ch4eaT/N6O62JgSKdhy0tslF/f8dNdXZQt/' jenkins && \
    usermod -aG sudo jenkins

## For Blackbalsam build:
ENV USER2 jovyan
ENV UID2 1003
ENV HOME2 /home/$USER2
RUN useradd -b /home -d $HOME2 -m  --shell /bin/bash --uid $UID2 -U -G jenkins $USER2 && \
    chown -R $UID2:$UID $HOME2 && \
    chmod -R 775 $HOME2

USER jenkins

# Create empty whitelist so command can be set up once for all time
RUN mkdir /var/jenkins_home/clair && \
    mkdir /var/jenkins_home/clair/whitelists && \
    touch /var/jenkins_home/clair/whitelists/common-whitelist.yaml
