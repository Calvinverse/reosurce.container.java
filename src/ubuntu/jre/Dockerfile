FROM 192.168.6.76:5000/calvinverse/resource.consul.ubuntu:0.1.0
LABEL maintainer "Petrik van der Velde (@petrikvdvelde)"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

#
# INSTALL JAVA
#

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

ENV JAVA_VERSION 9~b114
ENV JAVA_UBUNTU_VERSION 9~b114-0ubuntu1

# Install java and the required fonts
# Because apparently we might need these fonts because we are running in headless mode
# see: https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+got+java.awt.headless+problem
RUN apt-get update && \
    apt-get --assume-yes install openjdk-9-jre-headless="$JAVA_UBUNTU_VERSION" && \
    apt-get --assume-yes install libfontconfig1 && \
    apt-get --assume-yes install fonts-dejavu && \
    apt-get --assume-yes install fonts-dejavu-core && \
    apt-get --assume-yes install fonts-dejavu-extra && \
    apt-get --assume-yes install xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set JAVA_HOME
# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
ENV JAVA_HOME /usr/lib/jvm/java-9-openjdk-amd64/bin/java
