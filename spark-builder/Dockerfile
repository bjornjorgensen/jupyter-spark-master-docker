FROM bjornjorgensen/dep-builder

ARG openjdk_version="25"

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk-headless" \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java \
    git wget python3 curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /tmp/

RUN git clone https://github.com/apache/spark.git

WORKDIR /tmp/spark 

RUN ./dev/make-distribution.sh --name custom-spark --pip --tgz -Pkubernetes
