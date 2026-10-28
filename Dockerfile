# The image Beton's Linux CI jobs run in: Ubuntu 24.04 with the packages the jobs used to install with apt at the start
# of every run, and the .NET SDK. A job checks /etc/beton-ci-image against the version it expects, and installs the
# packages itself when the image is older, so a stale image is slower, never wrong.
FROM ubuntu:24.04

ARG IMAGE_VERSION
ARG DOTNET_SDK_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    PATH=/usr/share/dotnet:$PATH

# Git and Git LFS for the checkout, what the .NET SDK needs, Python for a protocol client test, and Mesa's software
# Vulkan driver lavapipe with the Khronos validation layer for the GPU tests.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends ca-certificates curl git git-lfs libicu74 tzdata python3 \
      libvulkan1 mesa-vulkan-drivers vulkan-validationlayers \
 && rm -rf /var/lib/apt/lists/*

# The SDK where actions/setup-dotnet looks first, so a job asking for this version downloads nothing.
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
 && bash /tmp/dotnet-install.sh --version "$DOTNET_SDK_VERSION" --install-dir /usr/share/dotnet \
 && rm /tmp/dotnet-install.sh \
 && dotnet --list-sdks

RUN echo "$IMAGE_VERSION" > /etc/beton-ci-image
