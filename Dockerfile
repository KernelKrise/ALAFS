# ---------------------- ARGS ---------------------- #
ARG USERNAME=user
ARG APPDIR=/app
ARG GO_VERSION=1.26.1
ARG JADX_VERSION=1.5.5
ARG NDK_VERSION=r29
ARG AFLXX_VERSION=4.40c
ARG AFLXX_MIN_API=29
ARG AFLXX_FRIDA_VERSION=17.9.1


# ---------------------- BASE IMAGE ---------------------- #
FROM debian:trixie-slim AS base

# Args
ARG USERNAME

# Create unprivilleged user
RUN groupadd "${USERNAME}" && \
    useradd -g "${USERNAME}" -s /bin/bash -m "${USERNAME}"

# Install apt dependencies
RUN DEBIAN_FRONTEND=noninteractive apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    ca-certificates \
    git \
    build-essential \
    binutils \
    binutils-arm-linux-gnueabi \
    binutils-arm-linux-gnueabihf \
    binutils-aarch64-linux-gnu \
    file \
    cmake \
    gcc \
    g++ \
    clang \
    xxd \
    zip \
    unzip \
    openjdk-21-jdk \
    apktool \
    aapt \
    adb \
    python3 \
    python3-pip \
    zlib1g-dev \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*


# ---------------------- BUILDER IMAGE ---------------------- #
FROM base AS builder

# Args
ARG GO_VERSION
ARG JADX_VERSION
ARG NDK_VERSION
ARG AFLXX_VERSION
ARG AFLXX_MIN_API
ARG AFLXX_FRIDA_VERSION

# Install Go
RUN curl -fsSL -o go.tar.gz "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /opt -xzf go.tar.gz && \
    rm -f go.tar.gz && \
    ln -s /opt/go/bin/go /usr/bin/go

# Install mcp-shell
RUN cd /opt && \
    git clone https://github.com/sonirico/mcp-shell && \
    cd mcp-shell && \
    make build

# Install JADX
RUN curl -fsSL -o jadx.zip "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" && \
    unzip jadx.zip -d /opt/jadx && \
    rm -f jadx.zip

# Install NDK
RUN curl -fsSL -o ndk.zip "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip" && \
    unzip ndk.zip -d /opt && \
    rm ndk.zip && \
    mv "/opt/android-ndk-${NDK_VERSION}" /opt/ndk

# Download AFL++
RUN curl -fsSL -o afl.zip "https://github.com/AFLplusplus/AFLplusplus/archive/refs/tags/v${AFLXX_VERSION}.zip" && \
    unzip afl.zip -d /opt && \
    rm afl.zip

# Copy CMakeLists.txt
COPY CMakeLists.txt "/opt/AFLplusplus-${AFLXX_VERSION}/"

# Build AFL++ binary (arm64-v8a)
RUN mkdir -p /opt/afl/arm64-v8a && \
    cd "/opt/AFLplusplus-${AFLXX_VERSION}" && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake \
    -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
    -DANDROID_PLATFORM="${AFLXX_MIN_API}" \
    -DANDROID_ABI=arm64-v8a \
    -DFRIDA_VERSION="${AFLXX_FRIDA_VERSION}" \
    .. && \
    make && \
    mv afl-fuzz afl-frida-trace.so /opt/afl/arm64-v8a/

# Build AFL++ binary (armeabi-v7a)
RUN mkdir -p /opt/afl/armeabi-v7a && \
    cd "/opt/AFLplusplus-${AFLXX_VERSION}" && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake \
    -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
    -DANDROID_PLATFORM="${AFLXX_MIN_API}" \
    -DANDROID_ABI=armeabi-v7a \
    -DFRIDA_VERSION="${AFLXX_FRIDA_VERSION}" \
    .. && \
    make && \
    mv afl-fuzz afl-frida-trace.so /opt/afl/armeabi-v7a/

# Build AFL++ binary (x86_64)
RUN mkdir -p /opt/afl/x86_64 && \
    cd "/opt/AFLplusplus-${AFLXX_VERSION}" && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake \
    -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
    -DANDROID_PLATFORM="${AFLXX_MIN_API}" \
    -DANDROID_ABI=x86_64 \
    -DFRIDA_VERSION="${AFLXX_FRIDA_VERSION}" \
    .. && \
    make && \
    mv afl-fuzz afl-frida-trace.so /opt/afl/x86_64/

# Build AFL++ binary (x86)
RUN mkdir -p /opt/afl/x86 && \
    cd "/opt/AFLplusplus-${AFLXX_VERSION}" && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake \
    -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
    -DANDROID_PLATFORM="${AFLXX_MIN_API}" \
    -DANDROID_ABI=x86 \
    -DFRIDA_VERSION="${AFLXX_FRIDA_VERSION}" \
    .. && \
    make && \
    mv afl-fuzz afl-frida-trace.so /opt/afl/x86/


# ---------------------- RELEASE IMAGE ---------------------- #
FROM base AS release

# Args
ARG APPDIR
ARG USERNAME

# Environment
ENV MCP_SHELL_SEC_CONFIG_FILE="${APPDIR}/security.yaml"

# Install tools from builder
COPY --from=builder --chmod=755 /opt/mcp-shell/bin/mcp-shell /usr/bin/mcp-shell
COPY --from=builder --chmod=755 /opt/jadx /opt/jadx
RUN ln -s /opt/jadx/bin/jadx /usr/bin/jadx
COPY --from=builder --chmod=755 /opt/ndk /opt/ndk
COPY --from=builder --chmod=755 /opt/afl /opt/afl

# Set workdir
WORKDIR "${APPDIR}"

# Copy sources
COPY ./src/ .

# Change ownership
RUN chown -R "${USERNAME}":"${USERNAME}" "${APPDIR}"

# Set unprivilleged user
USER "${USERNAME}"

# Entrypoint
ENTRYPOINT ["bash"]

# Cmd
CMD ["entrypoint.sh"]
