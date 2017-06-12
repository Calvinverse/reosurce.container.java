FROM 192.168.100.2:5000/calvinverse/resource.consul.ubuntu:0.1.0
LABEL maintainer "Petrik van der Velde (@petrikvdvelde)"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Update apt-get so that we can get all the packages
RUN apt-get update


#
# INSTALL JAVA
#

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

ENV JAVA_VERSION 9~b114
ENV JAVA_UBUNTU_VERSION 9~b114-0ubuntu1
RUN apt-get --assume-yes install openjdk-9-jre-headless="$JAVA_UBUNTU_VERSION"

# Set JAVA_HOME
# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
ENV JAVA_HOME /usr/lib/jvm/java-9-openjdk-amd64/bin/java


#
# INSTALL FONTS
#
# Because apparently we might need these fonts because we are running in headless mode
# see: https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+got+java.awt.headless+problem
RUN apt-get --assume-yes install libfontconfig1
RUN apt-get --assume-yes install fonts-dejavu
RUN apt-get --assume-yes install fonts-dejavu-core
RUN apt-get --assume-yes install fonts-dejavu-extra
RUN apt-get --assume-yes install xvfb


# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
