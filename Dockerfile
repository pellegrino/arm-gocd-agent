# Copyright 2017 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM hypriot/rpi-alpine
MAINTAINER Vitor Pellegrino <vitorp@gmail.com>

LABEL gocd.version="17.02" \
  description="ARM GoCD agent based on alpine version 3.5" \
  maintainer="Vitor Pellegrino <vitorp@gmail.com>" \
  gocd.full.version="17.12.0-5626" \
  gocd.git.sha="cb7df2ffe421e43f2a682a7a323cb3a3e30734cc"

ADD https://github.com/krallin/tini/releases/download/v0.16.1/tini-static-armhf /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.10/gosu-armhf /usr/local/sbin/gosu

# force encoding
ENV LANG=en_US.utf8

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  addgroup -g ${GID} go && \
  adduser -D -u ${UID} -s /bin/bash -G go go && \
  apk --no-cache upgrade && \
  apk add --no-cache openjdk8-jre-base git mercurial subversion openssh-client bash curl tini && \
# download the zip file
  curl --fail --location --silent --show-error "https://download.gocd.io/binaries/17.12.0-5626/generic/go-agent-17.12.0-5626.zip" > /tmp/go-agent.zip && \
# unzip the zip file into /go-agent, after stripping the first path prefix
  unzip /tmp/go-agent.zip -d / && \
  mv go-agent-17.12.0 /go-agent && \
  rm /tmp/go-agent.zip && \
  mkdir -p /docker-entrypoint.d

# ensure that logs are printed to console output
COPY agent-bootstrapper-logback-include.xml /go-agent/config/agent-bootstrapper-logback-include.xml
COPY agent-launcher-logback-include.xml /go-agent/config/agent-launcher-logback-include.xml
COPY agent-logback-include.xml /go-agent/config/agent-logback-include.xml

ADD docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
