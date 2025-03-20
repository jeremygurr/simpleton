ARG ALPINE_IMAGE=alpine:v3.21.3

FROM $ALPINE_IMAGE

USER root

ARG NO_PROXY=""
ARG HTTPS_PROXY=""
ARG HTTP_PROXY=""
ARG ALPINE_REPO=https://dl-cdn.alpinelinux.org/alpine/

COPY target/repositories /etc/apk/
RUN sed -i "s@https://dl-cdn.alpinelinux.org/alpine/@$ALPINE_REPO@g" /etc/apk/repositories 

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.en
ENV LC_ALL=en_US.UTF-8

RUN ln -s /var/cache/apk /etc/apk/cache 

RUN --mount=type=cache,target=/var/cache/apk \
  apk --allow-untrusted add \
    alpine-conf \
    apk-tools-doc \
    bash \
    bash-completion \
    bash-completion-doc \
    bash-doc \
    bc \
    bc-doc \
    bind-tools \
    binutils \
    busybox \
    busybox-doc \
    ca-certificates-doc \
    coreutils \
    coreutils-doc \ 
    curl \
    curl-doc \
    dnsmasq \
    dnsmasq-doc \
    docs \
    expat-doc \
    file \
    file-doc \
    findutils \
    findutils-doc \
    fstrm-doc \
    git \
    git-doc \
    git-perl \
    grep \
    grep-doc \
    ifupdown-ng \
    ifupdown-ng-doc \
    iproute2 \
    jq \
    jq-doc \
    json-c-doc \
    less \
    less-doc \
    libcap-ng-doc \
    libedit-doc \
    libretls-doc \
    libxml2-doc \
    linux-pam-doc \
    man-pages \
    mandoc \
    mandoc-doc \
    musl-locales \
    net-tools \
    net-tools-doc \
    openjdk23 \
    openrc \
    openrc-bash-completion \
    openrc-doc \
    openssh \
    openssh-doc \
    openssl \
    pciutils \
    pcre-doc \
    pcre2-doc \
    perl \
    perl-doc \
    perl-error \
    perl-error-doc \
    perl-git \
    pkgconf-doc \
    procps \
    readline-doc \
    rsync \
    skalibs-doc \
    source-highlight \
    source-highlight-doc \
    strace \
    strace-doc \
    sudo \
    sudo-doc \
    tar \
    tar-doc \
    texinfo \
    texinfo-doc \
    tzdata \
    usbutils \
    util-linux \
    util-linux-doc \
    utmps-doc \
    utmps-openrc \
    vim \
    vim-doc \
    yq \
    zlib-doc \
    $end_of_packages

ENV HOME=/home
ENV PAGER=less
ENV SIMPLETON_BASE=/repo
ENV SIMPLETON_REPO=/repo/simpleton
ENV SIMPLETON_LIB=$SIMPLETON_REPO/lib
ENV REPO_CACHE=/home/.m2/repository

RUN adduser -h /home -s /bin/bash -D autouser -u 99999
RUN chmod a+rwx /etc/profile.d /usr/bin
RUN ln -sf /repo/simpleton/target/inputrc /etc/
COPY target/sudoers /etc/
RUN chown root /etc/sudoers
RUN mkdir -p $REPO_CACHE

ARG TIME_ZONE=UTC
RUN setup-timezone -z $TIME_ZONE

RUN mkdir -p $HOME/scripts
RUN mkdir -p $HOME/.ssh
RUN chmod 700 $HOME/.ssh
RUN chown -R autouser $HOME
RUN rm /etc/motd

WORKDIR /work
CMD [ "/bin/bash", "/repo/simpleton/target/init" ]

