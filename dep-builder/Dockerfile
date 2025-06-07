FROM debian:testing AS dep-builder

ARG openjdk_version="21"

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk" \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java \
    git wget python3 curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Create virtual environment using uv
RUN uv venv /opt/venv

# Activate virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Now use uv to install packages
RUN uv pip install --upgrade pip setuptools

WORKDIR /tmp/

RUN git clone https://github.com/apache/spark.git

WORKDIR /tmp/spark 

RUN ./dev/make-distribution.sh --name custom-spark --pip -Pkubernetes

RUN rm -rf /tmp/spark
