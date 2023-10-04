ARG ALPINE_IMAGE=alpine:v3.18

FROM $ALPINE_IMAGE

USER root

ARG NO_PROXY=""
ARG HTTPS_PROXY=""
ARG HTTP_PROXY=""
ARG ALPINE_REPO=https://dl-cdn.alpinelinux.org/alpine/

COPY repositories /etc/apk/
RUN sed -i "s@https://dl-cdn.alpinelinux.org/alpine/@$ALPINE_REPO@g" /etc/apk/repositories 
RUN apk --allow-untrusted update 

RUN apk --allow-untrusted add \
  busybox

RUN apk --allow-untrusted add \
  util-linux \
  pciutils 

RUN apk --allow-untrusted add \
  usbutils 

RUN apk --allow-untrusted add \
  coreutils 

RUN apk --allow-untrusted add \
  binutils \
  findutils \
  grep \
  iproute2

RUN apk --allow-untrusted add \
  alpine-conf \
  apk-tools-doc \
  bash \
  bash-completion \
  bash-completion-doc \
  bash-doc \
  bind-tools \
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
  file-doc 

RUN apk --allow-untrusted add \
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
  jq \
  jq-doc \
  json-c-doc \
  less \
  less-doc \
  libcap-ng-doc \
  libedit-doc \
  libretls-doc \
  libxml2-doc \
  linux-pam-doc 

RUN apk --allow-untrusted add \
  man-pages \
  mandoc \
  mandoc-doc \
  net-tools \
  net-tools-doc \
  openrc \
  openrc-bash-completion \
  openrc-doc \
  openssh \
  openssh-doc \
  openssl \
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
  skalibs-doc 

RUN apk --allow-untrusted add \
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
#  tshark \
  tzdata 

RUN apk --allow-untrusted add \
  util-linux \
  util-linux-doc \
  utmps-doc \
  utmps-openrc \
  vim \
  vim-doc \
  yq \
  zlib-doc 

RUN apk --allow-untrusted add \
  bc \
  bc-doc

# RUN apk --allow-untrustedadd \
#   openssl3-doc \
#   $nothing

ENV HOME /home
ENV PAGER less
ENV SIMPLETON_BASE /repo
ENV SIMPLETON_REPO /repo/simpleton
ENV REPO_CACHE /home/.m2/repository

RUN adduser -h /home -s /bin/bash -D autouser -u 99999
RUN chmod a+rwx /etc
RUN ln -sf $SIMPLETON_REPO/target/shell-start.sh /etc/profile.d/
RUN ln -sf $SIMPLETON_REPO/inputrc /etc/
COPY sudoers /etc/
RUN chown root /etc/sudoers
RUN mkdir -p $REPO_CACHE

ARG TIME_ZONE=UTC
RUN setup-timezone -z $TIME_ZONE
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa

WORKDIR /work
CMD /bin/bash $SIMPLETON_REPO/init

