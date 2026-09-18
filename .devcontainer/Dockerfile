FROM ubuntu@sha256:224a1869083a311ef3f13648a154ba79832fbef6364d31493642ca03082da254

LABEL org.opencontainers.image.source="https://github.com/ShuranXu/embeddedville-soc-course-3-lab" \
      org.opencontainers.image.description="Pinned EmbeddedVille SoC Course 3 Verilator workspace" \
      org.opencontainers.image.licenses="LicenseRef-Course-Use"

ARG DEBIAN_FRONTEND=noninteractive
ARG VERILATOR_VERSION=5.050
ARG VERILATOR_SHA256=ec6723f30c1798b1fbbbed97364f09c431fb4875577c314f37240e99b60a4a04
ARG PYTHON_SERIES=3.12

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf bison build-essential ca-certificates cmake curl flex gcc-arm-none-eabi git help2man \
    libfl2 libfl-dev libgoogle-perftools-dev ninja-build perl python3 unzip zip zlib1g-dev && \
    test "$(python3 -c 'import sys; print(str(sys.version_info.major) + "." + str(sys.version_info.minor))')" = "${PYTHON_SERIES}" && \
    useradd -m -s /bin/bash vscode && rm -rf /var/lib/apt/lists/*

RUN curl -fL "https://github.com/verilator/verilator/archive/refs/tags/v${VERILATOR_VERSION}.tar.gz" -o /tmp/verilator.tar.gz && \
    echo "${VERILATOR_SHA256}  /tmp/verilator.tar.gz" | sha256sum -c - && \
    mkdir -p /tmp/verilator && tar -xzf /tmp/verilator.tar.gz -C /tmp/verilator --strip-components=1 && \
    cd /tmp/verilator && autoconf && ./configure --prefix=/opt/verilator && make -j2 && make install && \
    rm -rf /tmp/verilator /tmp/verilator.tar.gz

ENV PATH="/opt/verilator/bin:${PATH}" \
    EMBEDDEDVILLE_STARTER_VERSION="course-3-v2.0.0"
WORKDIR /workspaces/embeddedville-soc-course-3-lab
