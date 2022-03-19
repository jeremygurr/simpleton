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

COPY ./ /repo/simpleton/

RUN ln -sf /repo/simpleton/sudoers /etc/

CMD /bin/bash /repo/simpleton/init
