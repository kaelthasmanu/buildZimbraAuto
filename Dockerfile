# Uncomment the distro that you wish to build for
#ARG RELEASE=almalinux:8.10
#ARG RELEASE=oraclelinux:8.10
#ARG RELEASE=rockylinux/rockylinux:8.10
#ARG RELEASE=rockylinux/rockylinux:9.4
ARG RELEASE=ubuntu:22.04

# DO NOT EDIT BELOW THIS LINE

# Let's build for the version set above
FROM $RELEASE

# Install some necessary dependencies
RUN if [ -f "/usr/bin/apt-get" ]; then apt-get update && apt-get -y install git lsb-release; fi
RUN if [ -f "/usr/bin/dnf" ]; then dnf -y install dnf-plugins-core git redhat-lsb-core; fi

# Clone Zimbra Build Scripts
RUN git clone https://github.com/ianw1974/zimbra-build-scripts /home/git/zimbra-build-scripts
WORKDIR /home/git/zimbra-build-scripts

# Remove sudo from build script
RUN sed -i 's/sudo\ //g' ./zimbra-build-helper.sh

# Install and pre-configure timezone (needed on Ubuntu 20.04)
RUN if [ -f "/usr/bin/apt-get" ]; then DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata ; fi

# Install dependencies
RUN ./zimbra-build-helper.sh --install-deps

# Volume to retrieve builds
VOLUME /home/git/zimbra/BUILDS/

# Entrypoint wrapper: applies env vars to config.build before building
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
