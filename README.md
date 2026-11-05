# beton-ci-image

The container image Beton's Linux CI jobs run in: Ubuntu 24.04 with Git, Git LFS, Python, Mesa's lavapipe software Vulkan driver, the Khronos Vulkan validation layer and the .NET SDK. It saves every CI job the minutes it took to install them.

The validation layer comes from LunarG's Vulkan SDK, not Ubuntu: Ubuntu 24.04's package is 1.3.275, which doesn't know Vulkan 1.4. `VULKAN_SDK_VERSION` pins the SDK to the one matching the Vulkan headers BRUTAL is generated from, and `VULKAN_SDK_SHA256` is its checksum from LunarG (`https://vulkan.lunarg.com/sdk/sha/<version>/linux/vulkansdk-linux-x86_64-<version>.tar.xz.json`). Only the layer and `vulkaninfo` are kept. The build fails unless the layer loads at that version and lavapipe reports Vulkan 1.4.

```
ghcr.io/frumu-ai/beton-ci-image:<version>
```

## Changing it

1. Edit the `Dockerfile`, `DOTNET_SDK_VERSION` to match the engine's `global.json`, or `VULKAN_SDK_VERSION` and `VULKAN_SDK_SHA256` together. A new Vulkan SDK version also changes the pin in the engine's `ci.yml`, which a job in an older image installs.
2. Increase `VERSION` by one.
3. Push to `main`: the Publish workflow builds the image and pushes it tagged with that version and `latest`.
4. In the engine's `.github/workflows/ci.yml`, change the image tag and the expected version to the new one.

CI pins a version, so publishing changes nothing until CI asks for it. A job running in an image older than it expects installs the packages itself, so it's slower but still right.

The image contains only public packages and holds no credentials. It's public so that self-hosted runners can pull it without any.
