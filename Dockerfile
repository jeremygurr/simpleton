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

RUN /bin/echo 1

RUN apk --allow-untrusted add \
  util-linux \
  pciutils 

RUN /bin/echo 1.25

RUN apk --allow-untrusted add \
  usbutils 

RUN /bin/echo 1.3

