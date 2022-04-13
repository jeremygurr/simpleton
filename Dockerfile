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

WORKDIR $SIMPLETON_WORK
CMD /bin/bash $SIMPLETON_REPO/init

