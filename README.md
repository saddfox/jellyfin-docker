# jellyfin-docker
docker image with HWA and tone-mapping for AMD

### Notes:
- Repackages official jellyfin docker builds on top of Ubuntu 22.04, chosen for its inclusion of Mesa 22 which fixes h264 encoding speed for Polaris.  
- Added support for tone-mapping via Orca OpenCL, which works **only** on *legacy* AMD GPUs. In theory GCN1 - GCN4, tested on Polaris (RX550).
- To reduce image size HWA on Intel/Nvidia is not supported, you should use the [official](https://hub.docker.com/r/jellyfin/jellyfin) image.
