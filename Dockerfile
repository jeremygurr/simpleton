ARG ALPINE_IMAGE=alpine:latest

FROM $ALPINE_IMAGE

USER root

ARG NO_PROXY=""
ARG HTTPS_PROXY=""
ARG HTTP_PROXY=""
ARG ALPINE_REPO=https://dl-cdn.alpinelinux.org/alpine/

COPY repositories /etc/apk/
RUN sed -i "s@https://dl-cdn.alpinelinux.org/alpine/@$ALPINE_REPO@g" /etc/apk/repositories 
RUN apk update 

RUN apk add \
  alpine-conf \
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
  jq \
  jq-doc \
  json-c-doc \
  less \
  less-doc \
  libcap-ng-doc \
  libeconf-doc \
  libedit-doc \
  libretls-doc \
  libxml2-doc \
  linux-pam-doc \
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
#  procps-doc \
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
  tshark \
  tzdata \
  util-linux \
  util-linux-doc \
  util-linux-openrc \
  utmps-doc \
  utmps-openrc \
  vim \
  vim-doc \
  yq \
#  yq-doc \
  zlib-doc \
  $nothing

# RUN apk add \
#   openssl3-doc \
#   $nothing

RUN apk add \
  helix \
  $nothing

ENV HOME /home
ENV PAGER less
ENV SIMPLETON_BASE /repo
ENV SIMPLETON_REPO /repo/simpleton
ENV REPO_CACHE /home/.m2/repository

RUN adduser -h /home -s /bin/bash -D autouser -u 99999
RUN chmod a+rwx /etc
#COPY ./ $SIMPLETON_REPO/
RUN ln -sf $SIMPLETON_REPO/shell-start.sh /etc/profile.d/
RUN ln -sf $SIMPLETON_REPO/inputrc /etc/
COPY sudoers /etc/
RUN chown root /etc/sudoers
RUN mkdir -p $REPO_CACHE

ARG TIME_ZONE=UTC
RUN setup-timezone -z $TIME_ZONE

WORKDIR /work
CMD /bin/bash $SIMPLETON_REPO/init

