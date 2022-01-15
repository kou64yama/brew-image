# ghcr.io/kou64yama/brew

[![build](https://github.com/kou64yama/brew-image/actions/workflows/docker.yml/badge.svg?event=push)](https://github.com/kou64yama/brew-image/actions/workflows/docker.yml)

## Usage

Pull image from the command line:

```bash
docker pull ghcr.io/kou64yama/brew:latest
```

Use as base image in Dockerfile:

```dockerfile
FROM ghcr.io/kou64yama/brew:runtime AS builder

COPY --from=ghcr.io/kou64yama/brew:linuxbrew / /home/linuxbrew/.linuxbrew
COPY --from=ghcr.io/kou64yama/brew:taps / /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
ENV HOMEBREW_FORCE_BREWED_CURL=1
ENV HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
ENV HOMEBREW_NO_INSTALL_CLEANUP=1
ENV HOMEBREW_NO_INSTALL_UPGRADE=1

RUN brew install zsh
RUN rm -rf /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/*

FROM ghcr.io/kou64yama/brew:runtime

COPY --from=builder /home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH

CMD [ "/home/linuxbrew/.linuxbrew/bin/zsh", "-l" ]
```
