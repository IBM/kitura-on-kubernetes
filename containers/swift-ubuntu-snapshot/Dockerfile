##
# Copyright IBM Corporation 2016,2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

# Dockerfile to build a Docker image with the Swift tools and binaries and
# its dependencies.

FROM ibmcom/ubuntu:14.04
MAINTAINER IBM Swift Engineering at IBM Cloud
LABEL Description="Linux Ubuntu 14.04 image with the Swift binaries and tools."

USER root

# Set environment variables for image
ENV SWIFT_LINK https://swift.org/builds/swift-4.2-branch/ubuntu1404/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-05-22-a/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-05-22-a-ubuntu14.04.tar.gz
ENV WORK_DIR /

# Set WORKDIR
WORKDIR ${WORK_DIR}

# Linux OS utils and libraries and set clang 3.8 as default
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
  build-essential \
  clang-3.8 \
  git \
  libpython2.7 \
  libicu-dev \
  wget \
  libcurl4-openssl-dev \
  vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100 \
  && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.8 100 \
  && echo "set -o vi" >> /root/.bashrc

# Install Swift compiler
RUN wget $SWIFT_LINK -O swift-4.2.tar.gz \
  && tar xzvf swift-4.2.tar.gz --strip-components=1 \
  && rm swift-4.2.tar.gz \
  && chmod -R go+r /usr/lib/swift \
  && swift --version

CMD /bin/bash
