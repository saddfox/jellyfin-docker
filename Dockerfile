# By default build for unstable, 10.8.0-beta2 doesn't work on ubuntu 22.04
# supports amd vaapi, opencl only for legacy/orca
# for intel/nvidia use official jellyfin/jellyfin image
ARG TARGET_RELEASE=unstable

FROM jellyfin/jellyfin-server:${TARGET_RELEASE}-amd64 as server
FROM jellyfin/jellyfin-web:${TARGET_RELEASE} as web
FROM ubuntu:jammy

# Default environment variables for the Jellyfin invocation
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    JELLYFIN_DATA_DIR="/config" \
    JELLYFIN_CACHE_DIR="/cache" \
    JELLYFIN_CONFIG_DIR="/config/config" \
    JELLYFIN_LOG_DIR="/config/log" \
    JELLYFIN_WEB_DIR="/jellyfin/jellyfin-web" \
    JELLYFIN_FFMPEG="/usr/lib/jellyfin-ffmpeg/ffmpeg"
    
COPY install-opencl-amd.sh amd-opencl/

# Install dependencies:
# mesa-va-drivers: needed for AMD VAAPI. Mesa >= 20.1 is required for HEVC transcoding.
RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y apt-transport-https binutils ca-certificates curl gnupg wget xz-utils \
 && curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/debian-jellyfin.gpg \
 && echo "deb [arch=amd64] https://repo.jellyfin.org/ubuntu jammy main" | tee /etc/apt/sources.list.d/jellyfin.list \
 && apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y mesa-va-drivers jellyfin-ffmpeg5 openssl locales libfontconfig1 libfreetype6 \
# AMD OpenCL Tone mapping dependencies:
 && cd amd-opencl \
 && chmod +x install-opencl-amd.sh \
 && ./install-opencl-amd.sh \
 && cd .. \
 && rm -rf amd-opencl \
# Cleanup
 && apt-get remove apt-transport-https binutils curl gnupg wget xz-utils -y \
 && apt-get clean autoclean -y \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR} \
 && chmod 777 ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR} \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

COPY --from=server /jellyfin /jellyfin
COPY --from=web /jellyfin-web /jellyfin/jellyfin-web

EXPOSE 8096
VOLUME ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR}
ENTRYPOINT [ "/jellyfin/jellyfin" ]
