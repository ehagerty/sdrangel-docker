FROM ubuntu:20.04 AS base
ARG uid

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get -y install sudo git curl npm
RUN npm install npm -g \
    && npm cache clean -f \
    && npm install -g n \
    && n stable
RUN npm install -g @angular/cli \
    && npm install -g http-server

# Create node user with sudo rights and default to it
RUN useradd -m node -u ${uid} && echo "node:node" | chpasswd \
    && adduser node sudo \
    && sudo usermod --shell /bin/bash node
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER node

RUN sudo mkdir /opt/build \
    && sudo chown node:node /opt/build
WORKDIR /opt/build

# Clone sdrangelcli and build final image
FROM base as sdrangelcli
ARG repository
ARG branch
ARG repo_hash
ARG clone_tag
RUN git clone https://github.com/f4exb/sdrangelcli.git -b ${branch} sdrangelcli \
    && echo "${repo_hash}" > /dev/null \
    && echo "${clone_tag}" > /dev/null
WORKDIR /opt/build/sdrangelcli
RUN npm install \
    && ng build --prod \
    && mv dist /opt/build \
    && rm -rf *

WORKDIR /opt/build/dist/sdrangelcli
ENTRYPOINT [ "http-server" ]