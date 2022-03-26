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

RUN adduser -h /home -s /bin/bash -D autouser -u 99999
RUN chmod a+rwx /etc
ENV HOME /home
ENV PAGER less

RUN ln -sf /work/simpleton/sudoers /etc/
RUN ln -sf /work/simpleton/shell-start.sh /etc/profile.d/
RUN ln -sf /work/simpleton/inputrc /etc/inputrc

CMD /bin/bash /work/simpleton/init

