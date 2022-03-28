FROM alpine:latest 

USER root

# RUN sed -i "s@https://dl-cdn.alpinelinux.org/alpine/@https://ci-repo.aexp.com/repository/alpine-raw/@g" /etc/apk/repositories 
RUN apk update 
RUN apk add \
  bash \
  bash-completion \
  bash-completion-doc \
  bash-doc \
  bind-tools \
  curl \
  curl-doc \
  findutils \
  findutils-doc \
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
  sudo \
  sudo-doc \
  vim \
  yq \
  yq-doc 

ENV HOME /home
ENV PAGER less
ENV SIMPLETON_REPO /simpleton
ENV SIMPLETON_WORK /work
ENV REPO_CACHE /home/.m2/repository

RUN adduser -h /home -s /bin/bash -D autouser -u 99999
RUN chmod a+rwx /etc
COPY sudoers /etc/
COPY shell-start.sh /etc/profile.d/
COPY inputrc /etc/
RUN chown root /etc/sudoers
RUN mkdir -p $REPO_CACHE

WORKDIR $SIMPLETON_WORK
CMD /bin/bash $SIMPLETON_REPO/init

