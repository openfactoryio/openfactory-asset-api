# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/python:3.13-bookworm

USER root

# Install telnet
RUN apt-get update && apt-get install -y telnet && \
    rm -rf /var/lib/apt/lists/*

USER vscode
