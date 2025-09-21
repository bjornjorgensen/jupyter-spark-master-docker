FROM bjornjorgensen/dep-builder

ARG openjdk_version="25"

USER root

# Combine all package installations in single layer for efficiency
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk-headless" \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java \
    git wget python3 curl && \
    # Install uv in same layer to reduce image size
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    # Clean up in same layer
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH="/root/.local/bin:$PATH"

WORKDIR /tmp/

RUN git clone https://github.com/apache/spark.git

WORKDIR /tmp/spark 

# Set Maven optimization options for faster builds
ENV MAVEN_OPTS="-Xss128m -Xmx6g -XX:ReservedCodeCacheSize=1g -XX:+UseG1GC"

# Use parallel builds and skip unnecessary components for faster compilation
RUN ./dev/make-distribution.sh --name custom-spark --pip --tgz -Pkubernetes \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
    -Dmaven.scaladoc.skip=true \
    -Dmaven.source.skip=true \
    -Dcyclonedx.skip=true \
    -T 1C
