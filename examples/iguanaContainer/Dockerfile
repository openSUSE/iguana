# Specify the license of the container build description (see also the LICENSE file)
# SPDX-License-Identifier: GPL-2.0-only
# Define the names/tags of the container
#!BuildTag: partitioning_container:latest
FROM opensuse/tumbleweed
COPY . /partitioning/
RUN zypper install -y python3
RUN zypper install -y libstorage-ng-python3
ENTRYPOINT /usr/bin/bash /partitioning/inputScript.sh
WORKDIR /partitioning/
