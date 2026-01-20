FROM alpine:3.23 AS builder

ARG TARGETARCH
ARG GCLOUD_VERSION=458.0.0

WORKDIR /tmp

RUN apk add --no-cache curl wget unzip python3

# Download terraform and cloudflared in a single layer
RUN curl -sLo terraform.zip "https://releases.hashicorp.com/terraform/1.10.1/terraform_1.10.1_linux_${TARGETARCH}.zip" && \
    unzip terraform.zip && \
    chmod +x terraform && \
    wget -q "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${TARGETARCH}" && \
    chmod +x "cloudflared-linux-${TARGETARCH}"

# Download Docker CLI
ARG DOCKER_VERSION=27.2.0
RUN if [ "${TARGETARCH}" = "amd64" ]; then DOCKER_ARCH="x86_64"; else DOCKER_ARCH="aarch64"; fi && \
    curl -sLo docker.tgz "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" && \
    tar -xzf docker.tgz && \
    chmod +x docker/docker

RUN if [ `uname -m` = 'x86_64' ]; then echo -n "x86_64" > /tmp/arch; else echo -n "arm" > /tmp/arch; fi;

# Install Google Cloud SDK in the builder stage
RUN ARCH=`cat /tmp/arch` && wget -q "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${ARCH}.tar.gz" && \
    tar -xf "google-cloud-cli-${GCLOUD_VERSION}-linux-${ARCH}.tar.gz" && \
    ./google-cloud-sdk/install.sh --quiet --additional-components kubectl gke-gcloud-auth-plugin

FROM alpine:3.23

ARG TARGETARCH

# Create a non-root user
RUN addgroup -S noroot && adduser -S noroot -G noroot

# Install required packages in a single layer
RUN apk add --no-cache \
    curl \
    gcompat \
    git \
    idn2-utils \
    jq \
    openssh \
    tar \
    unzip \
    make \
    binutils \
    aws-cli \
    bind-tools \
    ansible \
    python3 && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Copy binaries from builder stage
COPY --from=builder /tmp/terraform /usr/local/bin/
COPY --from=builder /tmp/cloudflared-linux-${TARGETARCH} /usr/local/bin/cloudflared
COPY --from=builder /tmp/docker/docker /usr/local/bin/docker
COPY --from=builder /tmp/google-cloud-sdk /google-cloud-sdk

# Set proper permissions
RUN chmod 755 /usr/local/bin/terraform /usr/local/bin/cloudflared /usr/local/bin/docker

ENV PATH=$PATH:/google-cloud-sdk/bin

# To avoid running as root
# USER noroot
# WORKDIR /home/noroot

# Default command
CMD ["/bin/sh"]

# Build command sample
# docker buildx build --platform linux/amd64,linux/arm64 -t kwop/tools:0.7 --push ./