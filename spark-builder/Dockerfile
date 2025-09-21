# Multi-stage build: dependencies → build → runtime
FROM debian:testing AS spark-builder

ARG openjdk_version="25"

USER root

# Install build dependencies in a single layer for optimal caching
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk" \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java \
    git \
    wget \
    python3 \
    curl \
    build-essential \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH="/root/.local/bin:$PATH"

# Create virtual environment using uv (for consistency with your original approach)
RUN uv venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN uv pip install --upgrade pip setuptools

# Clone Spark repository (separate layer for better caching)
WORKDIR /tmp/
RUN git clone https://github.com/apache/spark.git

# Build Spark with optimizations
WORKDIR /tmp/spark 
ENV MAVEN_OPTS="-Xss128m -Xmx6g -XX:ReservedCodeCacheSize=1g -XX:+UseG1GC"

RUN ./dev/make-distribution.sh --name custom-spark --pip --tgz -Pkubernetes \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
    -Dmaven.scaladoc.skip=true \
    -Dmaven.source.skip=true \
    -Dcyclonedx.skip=true \
    -T 1C
