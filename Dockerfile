ARG BASE=ubuntu
ARG BASE_TAG=22.04
ARG PYTHON_VERSION=3.10

FROM ${BASE}:${BASE_TAG} as develop-deps

ARG PYTHON_VERSION
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # standard build tools
        build-essential \
        libffi-dev \
        # python tools
        "python${PYTHON_VERSION}-dev" \
        python3-pip \
        python3-setuptools \
        python3-tk \
        # other tools
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s "$(which python${PYTHON_VERSION})" /usr/local/bin/python \
    && python -m pip install --no-cache-dir --upgrade pip setuptools

WORKDIR /
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --upgrade pip && python -m pip install --no-cache-dir \
        -r requirements.txt

#########################################################################################
# the base for development
#########################################################################################
FROM develop-deps as develop

# install extra convenience tools for development 
# not required for building, testing, linting, formatting etc.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # other tools
        ssh-client \
        nano \
        # fixuid deps
        golang \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# download and compile fixuid
ARG FIXUID_VERSION="0.5.1"
WORKDIR /usr/local/src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -SsL "https://github.com/boxboat/fixuid/archive/refs/tags/v${FIXUID_VERSION}.tar.gz" | tar -C . -xzf - \
    && "./fixuid-${FIXUID_VERSION}/build.sh" \
    && cp "fixuid-${FIXUID_VERSION}/fixuid" /usr/local/bin/fixuid

# add non-root user
ARG USERNAME="dockeruser"
ARG GROUPNAME="dockergroup"
WORKDIR /
RUN addgroup --gid 1000 "${GROUPNAME}" \
    && adduser --uid 1000 --ingroup "${GROUPNAME}" --home "/home/${USERNAME}" --shell /bin/bash --disabled-password --gecos "" "${USERNAME}" \
    && chown root:root /usr/local/bin/fixuid \
    && chmod u+s /usr/local/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: %s\ngroup: %s\n" "${USERNAME}" "${GROUPNAME}" > /etc/fixuid/config.yml
ENTRYPOINT ["fixuid"]
