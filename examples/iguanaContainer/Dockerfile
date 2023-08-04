FROM opensuse/leap
COPY . /iguana/examples/partitioning/
RUN zypper install -y python3
RUN zypper install -y libstorage-ng-python3
ENTRYPOINT /usr/bin/bash /iguana/examples/partitioning/inputScript.bash
WORKDIR /iguana/examples/partitioning/
# CMD ["nginx", "-g", "daemon off;"]
