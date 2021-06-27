# This script is based on the one at https://github.com/uphold/docker-litecoin-core/blob/master/0.18/Dockerfile
# The Debian image used in the script has known vulnerabilities as listed here - https://snyk.io/test/docker/debian%3A10-slim
# Built litecoin on alpine as this image has no known vulnerabilities


FROM alpine:latest

# Adding the litecoin user
# Installing curl and GPG
##### Downloading GPG keys from 

RUN adduser -D litecoin \
  && apk update \
  && apk add --no-cache curl gnupg \
  && for key in \
    B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    FE3348877809386C \
  ; do \
    gpg --no-tty --keyserver pgp.mit.edu --recv-keys $key || \
    gpg --no-tty --keyserver keyserver.pgp.com --recv-keys $key || \
    gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys $key || \
    gpg --no-tty --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys $key ; \
  done

# GOSU installation on Alpine taken from - https://github.com/tianon/gosu/blob/master/INSTALL.md
# Setting up GOSU so that we can run the application as the litecoin user

ENV GOSU_VERSION 1.13
RUN set -eux; \
	apk add --no-cache --virtual .gosu-deps ca-certificates dpkg; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true


# Alpine comes with a lightweight musl-libc library. The litecoin package requires glibc installed to run. 
# TODO: Identify a base image with no vulnerabilites that already has glibc installed, OR build/package litecoin especially for Alpine.
# The glibc setup snippet was taken from here - https://gist.github.com/larzza/0f070a1b61c1d6a699653c9a792294be

ENV GLIBC_VERSION=2.26-r0
RUN  wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/sgerrand.rsa.pub \
     && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
     && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
     && apk --no-cache add glibc-${GLIBC_VERSION}.apk \
     && apk --no-cache add glibc-bin-${GLIBC_VERSION}.apk \
     && rm -rf /glibc-*.apk

# Setup litecoin

ENV LITECOIN_VERSION=0.18.1
ENV LITECOIN_DATA=/home/litecoin/.litecoin

RUN curl -SLO https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz \
  && curl -SLO https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-linux-signatures.asc \
  && gpg --verify litecoin-${LITECOIN_VERSION}-linux-signatures.asc \
  && grep $(sha256sum litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz | awk '{ print $1 }') litecoin-${LITECOIN_VERSION}-linux-signatures.asc \
  && tar --strip=2 -xzf *.tar.gz -C /usr/local/bin \
  && rm *.tar.gz

COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/litecoin/.litecoin"]

EXPOSE 9332 9333 19332 19333 19444

ENTRYPOINT ["/entrypoint.sh"]