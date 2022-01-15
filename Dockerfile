# syntax=docker/dockerfile:1

################################################################################

FROM ubuntu:20.04 AS builder

# Install Homebrew
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
  && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache
RUN \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git
RUN update-ca-certificates
RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

# Install build dependencies
RUN \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get install -y --no-install-recommends build-essential

# Install runtime dependencies
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
ENV HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
ENV HOMEBREW_NO_INSTALL_CLEANUP=1
ENV HOMEBREW_NO_INSTALL_UPGRADE=1
RUN \
  --mount=type=cache,target=/root/.cache \
  brew install curl git

RUN mv /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps /Taps

################################################################################

FROM scratch AS linuxbrew

LABEL maintainer=kou64yama@gmail.com

COPY --from=builder /home/linuxbrew/.linuxbrew /

################################################################################

FROM scratch AS taps

LABEL maintainer=kou64yama@gmail.com

COPY --from=builder /Taps /

################################################################################

FROM ubuntu:20.04 AS runtime

LABEL maintainer=kou64yama@gmail.com

RUN apt-get update \
  && apt-get install -y --no-install-recommends sudo build-essential \
  && apt-get upgrade -y --no-install-recommends \
  && apt-get clean

################################################################################

FROM runtime AS slim

ARG USERNAME=linuxbrew
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd -g ${USER_GID} ${USERNAME} \
  && useradd -lm -s /bin/bash -g ${USER_GID} -u ${USER_UID} ${USERNAME} \
  && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" >>/etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
ENV HOMEBREW_FORCE_BREWED_CURL=1
ENV HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
ENV HOMEBREW_NO_INSTALL_CLEANUP=1
ENV HOMEBREW_NO_INSTALL_UPGRADE=1

COPY --from=linuxbrew --chown=${USERNAME}:${USERNAME} \
  / /home/linuxbrew/.linuxbrew

################################################################################

FROM slim

COPY --from=taps --chown=${USERNAME}:${USERNAME} \
  / /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps
