ARG TARGET_RELEASE=10.8.13

FROM jellyfin/jellyfin-server:${TARGET_RELEASE}-amd64 as server
FROM jellyfin/jellyfin-web:${TARGET_RELEASE} as web
FROM ubuntu:mantic

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

# https://github.com/dlemstra/Magick.NET/issues/707#issuecomment-785351620
ENV MALLOC_TRIM_THRESHOLD_=131072

# Install dependencies:
RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y ca-certificates gnupg curl wget apt-transport-https \
 && curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/debian-jellyfin.gpg \
 && echo "deb [arch=amd64] https://repo.jellyfin.org/ubuntu mantic main" | tee /etc/apt/sources.list.d/jellyfin.list \
 && apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y jellyfin-ffmpeg6 openssl locales libfontconfig1 libfreetype6 \
# ROCm OpenCL runtime
 && mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg \
 && cat <<EOF | tee /etc/apt/sources.list.d/rocm.sources
Types: deb
URIs: https://repo.radeon.com/rocm/apt/latest
Suites: ubuntu
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/rocm.gpg
EOF
RUN apt-get update && apt-get install -y rocm-opencl-runtime \
 && apt-get remove gnupg wget apt-transport-https -y \
 && apt-get clean autoclean -y \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR} \
 && chmod 777 ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR} \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

COPY --from=server --chown=1000:1000 /jellyfin /jellyfin
COPY --from=web --chown=1000:1000 /jellyfin-web /jellyfin/jellyfin-web

EXPOSE 8096
VOLUME ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR}
ENTRYPOINT [ "/jellyfin/jellyfin" ]
