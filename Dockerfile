# The image Beton's Linux CI jobs run in: Ubuntu 24.04 with the packages the jobs used to install with apt at the start
# of every run, the Khronos validation layer, and the .NET SDK. A job checks /etc/beton-ci-image against the version it
# expects, and installs them itself when the image is older, so a stale image is slower, never wrong.
FROM ubuntu:24.04

ARG IMAGE_VERSION
ARG DOTNET_SDK_VERSION
ARG VULKAN_SDK_VERSION
ARG VULKAN_SDK_SHA256

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    PATH=/usr/share/dotnet:$PATH

# Git and Git LFS for the checkout, what the .NET SDK needs, Python for a protocol client test, Mesa's software Vulkan
# driver lavapipe for the GPU tests, and xz to unpack the Vulkan SDK.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends ca-certificates curl git git-lfs libicu74 tzdata python3 xz-utils \
      libvulkan1 mesa-vulkan-drivers \
 && rm -rf /var/lib/apt/lists/*

# The Khronos validation layer from LunarG's Vulkan SDK, pinned to the SDK matching the Vulkan headers BRUTAL is
# generated from. Ubuntu 24.04's vulkan-validationlayers is 1.3.275, which doesn't know Vulkan 1.4. Only the layer and
# vulkaninfo are kept; the manifest points at the library's absolute path.
RUN curl -fsSL "https://sdk.lunarg.com/sdk/download/$VULKAN_SDK_VERSION/linux/vulkansdk-linux-x86_64-$VULKAN_SDK_VERSION.tar.xz" \
      -o /tmp/vulkansdk.tar.xz \
 && echo "$VULKAN_SDK_SHA256  /tmp/vulkansdk.tar.xz" | sha256sum --check \
 && tar -xJf /tmp/vulkansdk.tar.xz -C /tmp \
      "$VULKAN_SDK_VERSION/x86_64/lib/libVkLayer_khronos_validation.so" \
      "$VULKAN_SDK_VERSION/x86_64/share/vulkan/explicit_layer.d/VkLayer_khronos_validation.json" \
      "$VULKAN_SDK_VERSION/x86_64/bin/vulkaninfo" \
 && install -m 755 "/tmp/$VULKAN_SDK_VERSION/x86_64/lib/libVkLayer_khronos_validation.so" /usr/local/lib/ \
 && install -m 755 "/tmp/$VULKAN_SDK_VERSION/x86_64/bin/vulkaninfo" /usr/local/bin/ \
 && mkdir -p /usr/local/share/vulkan/explicit_layer.d \
 && sed 's#"library_path": *"[^"]*"#"library_path": "/usr/local/lib/libVkLayer_khronos_validation.so"#' \
      "/tmp/$VULKAN_SDK_VERSION/x86_64/share/vulkan/explicit_layer.d/VkLayer_khronos_validation.json" \
      > /usr/local/share/vulkan/explicit_layer.d/VkLayer_khronos_validation.json \
 && rm -rf /tmp/vulkansdk.tar.xz "/tmp/$VULKAN_SDK_VERSION"

# Fail the build unless the layer loads at the pinned version and lavapipe reports Vulkan 1.4. Naming the layer in
# VK_INSTANCE_LAYERS makes vulkaninfo fail when the loader can't load it.
RUN export VK_DRIVER_FILES="$(find /usr/share/vulkan/icd.d -name 'lvp_icd*.json' | paste -sd ':' -)" \
 && VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation vulkaninfo --summary > /tmp/vulkaninfo.txt \
 && cat /tmp/vulkaninfo.txt \
 && grep -E "VK_LAYER_KHRONOS_validation" /tmp/vulkaninfo.txt | grep -qF "$(echo "$VULKAN_SDK_VERSION" | cut -d. -f1-3)" \
 && grep -Eq "apiVersion += 1\.4\." /tmp/vulkaninfo.txt \
 && rm /tmp/vulkaninfo.txt

# The SDK where actions/setup-dotnet looks first, so a job asking for this version downloads nothing.
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
 && bash /tmp/dotnet-install.sh --version "$DOTNET_SDK_VERSION" --install-dir /usr/share/dotnet \
 && rm /tmp/dotnet-install.sh \
 && dotnet --list-sdks

RUN echo "$IMAGE_VERSION" > /etc/beton-ci-image
