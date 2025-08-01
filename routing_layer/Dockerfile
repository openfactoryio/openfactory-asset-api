# ------------------------------------------------------------------------------
# 🐳 Dockerfile for OpenFactory Routing Layer API (FastAPI)
#
# This image is used in both development and production environments.
# It installs required system dependencies, sets up a non-root user,
# installs Python packages, and runs the FastAPI app using the built-in launcher.
#
# Key Features:
#   - Uses Python 3.12-slim base for small footprint
#   - Runs as a non-root user for better container security
#   - Compatible with both local and Swarm deployments
# ------------------------------------------------------------------------------

FROM python:3.12-slim

# Arguments for non-root user creation
ARG UNAME=routing_layer
ARG UID=1200
ARG GID=1200
# Arguments for version managment
ARG VERSION=dev
ARG APPLICATION_MANUFACTURER=OpenFactory-AssetAPI
ARG OPENFACTORY_VERSION=main

# Install git and create a non-root user and group
RUN apt-get update && apt-get install -y git \
    && groupadd --gid $GID $UNAME \
    && useradd --create-home --uid $UID --gid $GID $UNAME \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project (including pyproject.toml)
COPY pyproject.toml README.md /app/
COPY routing_layer /app/routing_layer

# Install the package using pyproject.toml
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir .

# Install OpenFactory
RUN pip uninstall -y openfactory && \
    pip install --no-cache-dir \
      "git+https://github.com/openfactoryio/openfactory-core.git@${OPENFACTORY_VERSION}"

# Change ownership to the non-root user
RUN chown -R $UNAME:$UNAME /app

# Set environment variable from build argument
ENV APPLICATION_VERSION=${VERSION}
ENV APPLICATION_MANUFACTURER=${APPLICATION_MANUFACTURER}
ENV OPENFACTORY_VERSION=${OPENFACTORY_VERSION}

# Switch to non-root user
USER $UNAME

# Expose port used by Uvicorn
EXPOSE 5555

# Command to run the FastAPI app
CMD ["python", "-m", "routing_layer.app.main"]

