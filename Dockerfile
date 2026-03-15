FROM debian:trixie-slim AS base

# Environment
ENV USERNAME="user" \
    UID="1000" \
    APPDIR="/app" \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_HOME=/opt/poetry

# Create unprivilleged user
RUN groupadd -g "${UID}" "${USERNAME}" && \
    useradd -u "${UID}" -g "${USERNAME}" -s /bin/bash -m "${USERNAME}"

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    curl \
    apktool \
    file \
    python3 \
    python3-pip \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Set workdir
WORKDIR "${APPDIR}"

# Copy poetry files
COPY pyproject.toml poetry.lock ./

# Install python dependencies
RUN ${POETRY_HOME}/bin/poetry install --no-root --only main

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
