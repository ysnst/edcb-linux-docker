# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS builder

ARG EDCB_REPO=https://github.com/xtne6f/EDCB.git
ARG EDCB_BRANCH=work-plus-s
ARG BON_REPO=https://github.com/matching/BonDriver_LinuxMirakc.git
ARG MULTI2DEC_REPO=https://github.com/tsukumijima/Multi2Dec.git
ARG EMWUI_REPO=https://github.com/tsukumijima/EDCB_Material_WebUI.git
ARG MAKEFLAGS=-j4

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      g++ \
      gcc \
      git \
      libcurl4-openssl-dev \
      liblua5.2-dev \
      libpcsclite-dev \
      make \
      openssl \
      pkg-config \
      lua-zlib \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth 1 --branch "${EDCB_BRANCH}" "${EDCB_REPO}" EDCB

WORKDIR /opt/EDCB/Document/Unix
RUN make ${MAKEFLAGS} && make install_u

# 初回起動時に edcb-data へコピーする初期設定テンプレートをイメージ内に作成する
RUN mkdir -p /var/local/edcb /var/local/edcb.template \
 && make setup_ini \
 && cp -a /var/local/edcb/. /var/local/edcb.template/

WORKDIR /opt
RUN git clone --depth 1 "${EMWUI_REPO}" EDCB_Material_WebUI \
 && install -d /var/local/edcb.template/HttpPublic /var/local/edcb.template/Setting \
 && cp -a /opt/EDCB_Material_WebUI/HttpPublic/. /var/local/edcb.template/HttpPublic/ \
 && cp -a /opt/EDCB_Material_WebUI/Setting/. /var/local/edcb.template/Setting/

WORKDIR /opt
RUN git clone --depth 1 --recurse-submodules "${BON_REPO}" BonDriver_LinuxMirakc

WORKDIR /opt/BonDriver_LinuxMirakc
RUN make ${MAKEFLAGS} \
 && install -d /usr/local/lib/edcb \
 && install -m 0755 BonDriver_LinuxMirakc.so /usr/local/lib/edcb/

WORKDIR /opt
RUN git clone --depth 1 --recurse-submodules "${MULTI2DEC_REPO}" Multi2Dec

WORKDIR /opt/Multi2Dec/B25Decoder
RUN make ${MAKEFLAGS} USE_SIMD=y \
 && install -d /usr/local/lib/edcb \
 && install -m 0755 B25Decoder.so /usr/local/lib/edcb/

FROM debian:bookworm-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      libcurl4 \
      liblua5.2-0 \
      libpcsclite1 \
      lua-zlib \
      openssl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/ /usr/local/
COPY --from=builder /var/local/edcb.template/ /var/local/edcb.template/
COPY templates/ /var/local/edcb.template/

RUN mkdir -p /var/local/edcb
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5510
ENTRYPOINT ["/entrypoint.sh"]
