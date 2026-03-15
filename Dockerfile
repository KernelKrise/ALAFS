FROM debian:trixie-slim AS base

# Environment
ENV USERNAME="user" \
    UID="1000" \
    APPDIR="/app"

# Create unprivilleged user
RUN groupadd -g "${UID}" "${USERNAME}" && \
    useradd -u "${UID}" -g "${USERNAME}" -s /bin/bash -m "${USERNAME}"

# Install tools
RUN DEBIAN_FRONTEND=noninteractive apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    apktool \
    file \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Set workdir
WORKDIR "${APPDIR}"

# Copy sources
COPY ./src/ ./

# Change ownership
RUN chown -R "${UID}":"${UID}" "${APPDIR}"

# Set unprivilleged user
USER "${USERNAME}"

# Entrypoint
ENTRYPOINT [ "bash" ]

# Command
CMD [ "entrypoint.sh" ]
