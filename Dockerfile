FROM debian:trixie-slim AS base

# Environment
ENV USERNAME=user \
    UID=1000 \
    APPDIR=/app \
    GO_VERSION=1.26.1

# Create unprivilleged user
RUN groupadd -g "${UID}" "${USERNAME}" && \
    useradd -u "${UID}" -g "${USERNAME}" -s /bin/bash -m "${USERNAME}"

# Install apt dependencies
RUN DEBIAN_FRONTEND=noninteractive apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    ca-certificates \
    git \
    build-essential \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN curl -fsSL -o go.tar.gz "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm -f go.tar.gz && \
    ln -s /usr/local/go/bin/go /usr/bin/go

# Install mcp-shell
RUN git clone https://github.com/sonirico/mcp-shell && \
    cd mcp-shell && \
    make install

# Set workdir
WORKDIR "${APPDIR}"

# Copy sources
COPY ./src/ .

# Change ownership
RUN chown -R "${UID}":"${UID}" "${APPDIR}"

# Set unprivilleged user
USER "${USERNAME}"

# Entrypoint
ENTRYPOINT [ "bash" ]

# Cmd
CMD [ "entrypoint.sh" ]
