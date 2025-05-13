# Builder stage for Spark
FROM bjornjorgensen/spark-builder AS builder

# Our main image starts here
FROM debian:testing

# Set environment variables to non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Define the OpenJDK version
ARG openjdk_version="21"

# Update the package lists, install Python 3, venv, tini, OpenJDK, and required certificates
# Using python3-venv ensures the venv module is available for the default python3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    tini \
    procps \
    "openjdk-${openjdk_version}-jdk-headless" \
    ca-certificates-java && \
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

# As root user create the virtual environment and set ownership
RUN python3 -m venv /opt/venv && \
    chown -R ${NB_UID}:${NB_GID} /opt/venv

# --- Switch to jovyan user to install Python packages into the venv ---
USER "${NB_USER}"
WORKDIR "/home/${NB_USER}"

# Set the PATH to include the virtual environment's executables FOR THE JOVYAN USER
# This ensures subsequent RUN commands as jovyan use the venv
ENV PATH="/opt/venv/bin:${PATH}"

# Install Python packages using pip in the virtual environment as jovyan user
RUN pip install --no-cache-dir --upgrade \
        pip \
        setuptools \
        wheel && \
    pip install --no-cache-dir \
        jupyterlab \
        'black[jupyter]' \
        xmltodict \
        jupyterlab-code-formatter \
        isort \
        python-dotenv \
        nbdev \
        lxml \
        plotly \
        psycopg2-binary \
        sqlalchemy \
        pyarrow \
        flatterer \
        pandas


# --- Switch back to root for system-level changes (Spark install, JARs) ---
USER root

# Copy the Spark distribution from the builder stage
COPY --from=builder /tmp/spark/spark-4.1.0-SNAPSHOT-bin-custom-spark.tgz /spark.tgz

# Create directory first and then unpack Spark
RUN mkdir -p /local && \
    tar xzf /spark.tgz -C /local && \
    rm /spark.tgz && \
    mv /local/spark-4.1.0-SNAPSHOT-bin-custom-spark /spark

# Configure Spark paths globally
ENV SPARK_HOME="/spark"
# Update PATH globally to include Spark binaries *and* ensure venv is still prioritized if user switches back
ENV PATH="/opt/venv/bin:${SPARK_HOME}/bin:${PATH}"

# Add Jars for S3A support to the Spark Jars directory
# Using ADD for URLs is convenient but COPY from a local download can improve build caching
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.608/aws-java-sdk-bundle-1.12.608.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

# Update the permissions for JARs - Readable by all, owned by root (Spark usually runs fine like this)
# Also explicitly ensure jovyan group can read them just in case
RUN chmod a+r ${SPARK_HOME}/jars/*.jar && \
    chown -R root:${NB_GID} ${SPARK_HOME}/jars


# --- Switch back to jovyan user to install PySpark into the venv ---
USER "${NB_USER}"
# Ensure PATH is set correctly for this user session
ENV PATH="/opt/venv/bin:${SPARK_HOME}/bin:${PATH}"

# Install PySpark from the correct directory where setup.py is located
RUN cd ${SPARK_HOME}/python/packaging/classic && \
    pip install --no-cache-dir .

# --- Final configuration steps ---

# Disable announcements extension (run as the user who runs jupyterlab)
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Expose the port for JupyterLab (can be done as root or user, doesn't matter much)
EXPOSE 8888

# Copy the entrypoint script into the container and set permissions (Do as root for /)
USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
# Optional: Ensure jovyan can execute it if needed, although entrypoint usually runs as root initally via tini
# RUN chown ${NB_USER}:${NB_GID} /docker-entrypoint.sh

# Optional: Grant write permissions to Spark's default work-dir if needed by applications run by jovyan
# Ensure the directory exists first
RUN mkdir -p ${SPARK_HOME}/work-dir && \
    chown ${NB_USER}:${NB_GID} ${SPARK_HOME}/work-dir && \
    chmod g+w ${SPARK_HOME}/work-dir

# Switch back to jovyan user for the runtime environment
USER "${NB_USER}"
WORKDIR "/home/${NB_USER}"

# Set the entrypoint to the script (will be run via tini)
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

# Default command to start JupyterLab
CMD ["jupyter-lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
# Note: Added --allow-root just in case entrypoint script or tini causes Jupyter to run as effective root initially.
# If your entrypoint script correctly switches to jovyan before launching Jupyter, you might not need --allow-root.
# Test without it first if preferred.

