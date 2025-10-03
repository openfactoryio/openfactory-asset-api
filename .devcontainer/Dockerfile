# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/python:2.0.2-3.13-bullseye

USER root

# Install telnet
RUN apt-get update && apt-get install -y telnet && \
    rm -rf /var/lib/apt/lists/*

USER vscode
