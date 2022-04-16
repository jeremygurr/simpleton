ARG ALPINE_IMAGE=alpine:latest

FROM $ALPINE_IMAGE

USER root

ARG NO_PROXY=""
ARG HTTPS_PROXY=""
ARG HTTP_PROXY=""
ARG ALPINE_REPO=https://dl-cdn.alpinelinux.org/alpine/

RUN sed -i "s@https://dl-cdn.alpinelinux.org/alpine/@$ALPINE_REPO@g" /etc/apk/repositories 
RUN apk update 

RUN apk add \
  bash \
  bash-completion \
  bash-completion-doc \
  bash-doc \
  bind-tools \
  curl \
  curl-doc \
  coreutils \
  coreutils-doc \ 
  dnsmasq \
  dnsmasq-doc \
  file \
  findutils \
  findutils-doc \
  $nothing

RUN apk add \
  git \
  git-doc \
  grep \
  jq \
  jq-doc \
  less \
  less-doc \
  man-pages \
  mandoc \
  net-tools \
  net-tools-doc \
  openssh \
  openssh-doc \
  openssl \
  procps \
  procps-doc \
  source-highlight \
  source-highlight-doc \
  strace \
  strace-doc \
  $nothing

RUN apk add \
  sudo \
  sudo-doc \
  tar \
  util-linux \
  util-linux-doc \
  vim \
  yq \
  yq-doc \
  $nothing

RUN apk add \
  ifupdown-ng \
  openrc \
  alpine-conf \
  openrc-bash-completion \
  utmps-openrc \
  mandoc-doc \
  utmps-doc \
  busybox-doc \
  fstrm-doc \
  apk-tools-doc \
  $nothing

RUN apk add \
  ca-certificates-doc \
  pkgconf-doc \
  openrc-doc \
  libxml2-doc \
  ifupdown-ng-doc \
  libretls-doc \
  skalibs-doc \
  zlib-doc \
  readline-doc \
  json-c-doc \
  file-doc \
  $nothing

RUN apk add \
  texinfo \
  texinfo-doc \
  $nothing

RUN apk add \
  expat-doc \
  pcre2-doc \
  pcre-doc \
  grep-doc \
  libedit-doc \
  tar-doc \
  perl \
  perl-doc \
  perl-error \
  perl-error-doc \
  perl-git \
  git-perl \
  libeconf-doc \
  linux-pam-doc \
  util-linux-openrc \
  libcap-ng-doc \
  vim-doc \
  $nothing

RUN apk add \
  docs \
  $nothing

ENV HOME /home
ENV PAGER less
ENV SIMPLETON_REPO /simpleton
ENV SIMPLETON_WORK /work
ENV REPO_CACHE /home/.m2/repository

RUN adduser -h /home -s /bin/bash -D autouser -u 99999
RUN chmod a+rwx /etc
COPY ./ $SIMPLETON_REPO/
RUN ln -sf $SIMPLETON_REPO/shell-start.sh /etc/profile.d/
RUN ln -sf $SIMPLETON_REPO/inputrc /etc/
COPY sudoers /etc/
RUN chown root /etc/sudoers
RUN mkdir -p $REPO_CACHE

ARG TIME_ZONE=UTC
RUN setup-timezone -z $TIME_ZONE

WORKDIR $SIMPLETON_WORK
CMD /bin/bash $SIMPLETON_REPO/init

