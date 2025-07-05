# Builder stage for Spark
FROM bjornjorgensen/spark-builder AS builder

# Our main image starts here
FROM debian:testing

# Set environment variables to non-interactive (to avoid prompts during package installation)
ENV DEBIAN_FRONTEND=noninteractive

# Define the OpenJDK version
ARG openjdk_version="21"

# Update the package lists, install Python 3.11, tini, OpenJDK, and required certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    tini \
    procps \
    "openjdk-${openjdk_version}-jdk-headless" \
    nodejs \
    npm \
    ca-certificates-java \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Define default environment variables for user 'jovyan'
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="1000"

# Create jovyan user with the specified UID/GID and ensure directory permissions are correct
RUN groupadd --gid "${NB_GID}" "${NB_USER}" && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${NB_UID}" --gid "${NB_GID}" "${NB_USER}" && \
    mkdir -p "/home/${NB_USER}" && \
    chown -R "${NB_UID}:${NB_GID}" "/home/${NB_USER}"

# Install uv as root
USER root
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# Move uv to system-wide location
RUN mv /root/.local/bin/uv /usr/local/bin/uv

# Create virtual environment using uv
RUN uv venv /opt/venv && \
    chown -R ${NB_UID}:${NB_GID} /opt/venv

# Switch to the jovyan user
USER "${NB_USER}"
WORKDIR "/home/${NB_USER}"

# Set the PATH to include the virtual environment's executables
ENV PATH="/opt/venv/bin:${PATH}"

# Install packages using uv in the virtual environment
RUN uv pip install \
        jupyterlab \
        "marimo[recommended]" \
        google-generativeai \
        psycopg2-binary \
        pandas \
        openpyxl

USER root
# Copy the Spark distribution from the builder stage
COPY --from=builder /tmp/spark/spark-4.1.0-SNAPSHOT-bin-custom-spark.tgz /tmp/spark.tgz

# Unpack Spark, move it to /opt/spark, and remove the tarball
RUN tar xzf /tmp/spark.tgz -C /usr/local && \
    rm /tmp/spark.tgz && \
    mv /usr/local/spark-4.1.0-SNAPSHOT-bin-custom-spark /opt/spark

# Configure Spark paths
ENV SPARK_HOME="/opt/spark"
ENV PATH="${SPARK_HOME}/bin:${PATH}"

# Install PySpark directly without editable mode
RUN uv pip install --break-system-packages /opt/spark/python/packaging/classic/

USER root
# Add Jars for S3A support to the Spark Jars directory and update the permissions
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.608/aws-java-sdk-bundle-1.12.608.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/
RUN chmod a+rx ${SPARK_HOME}/jars/*.jar

# Expose the port for JupyterLab
EXPOSE 8888

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Copy the entrypoint script into the container and set permissions
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir

# Switch to the jovyan user
USER "${NB_USER}"
WORKDIR "/home/${NB_USER}"

# Set the entrypoint to the script
ENTRYPOINT ["/docker-entrypoint.sh"]

# Start JupyterLab
CMD ["jupyter-lab", "--ip=0.0.0.0", "--no-browser"]



