FROM opensuse/leap
# COPY ???/input.json .
COPY . /iguana/example/partitioning/
RUN zypper install -y python3
RUN zypper install -y libstorage-ng-python3
ENTRYPOINT /usr/bin/bash /iguana/example/partitioning/inputScript.bash
WORKDIR /iguana/example/partitioning/
# CMD ["nginx", "-g", "daemon off;"]
