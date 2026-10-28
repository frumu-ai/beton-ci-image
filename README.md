# beton-ci-image

The container image Beton's Linux CI jobs run in: Ubuntu 24.04 with Git, Git LFS, Python, Mesa's lavapipe software Vulkan driver, the Khronos Vulkan validation layer and the .NET SDK. It saves every CI job the minutes it took to install them.

```
ghcr.io/frumu-ai/beton-ci-image:<version>
```

## Changing it

1. Edit the `Dockerfile`, or `DOTNET_SDK_VERSION` to match the engine's `global.json`.
2. Increase `VERSION` by one.
3. Push to `main`: the Publish workflow builds the image and pushes it tagged with that version and `latest`.
4. In the engine's `.github/workflows/ci.yml`, change the image tag and the expected version to the new one.

CI pins a version, so publishing changes nothing until CI asks for it. A job running in an image older than it expects installs the packages itself, so it's slower but still right.

The image contains only public packages and holds no credentials. It's public so that self-hosted runners can pull it without any.
