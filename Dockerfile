# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG OWNER=jupyter
ARG BASE_CONTAINER=$OWNER/scipy-notebook
FROM $BASE_CONTAINER

#LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Spark dependencies
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
#ARG spark_version="3.2.1"
#ARG hadoop_version="3.2"
#ARG spark_checksum="145ADACF189FECF05FBA3A69841D2804DD66546B11D14FC181AC49D89F3CB5E4FECD9B25F56F0AF767155419CD430838FB651992AEB37D3A6F91E7E009D1F9AE"

ARG openjdk_version="11"

#ENV APACHE_SPARK_VERSION="${spark_version}" \
#    HADOOP_VERSION="${hadoop_version}"

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jdk-headless" \
    ca-certificates-java nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE

WORKDIR /tmp 

RUN git clone https://github.com/apache/spark.git

WORKDIR /tmp/spark 

RUN ./build/mvn -DskipTests clean package && ./dev/make-distribution.sh --name spark-master --pip

WORKDIR /tmp/spark/dist 


# Based on the Spark dockerfile

COPY jars /opt/spark/jars
COPY bin /opt/spark/bin
COPY sbin /opt/spark/sbin
#COPY kubernetes/dockerfiles/spark/entrypoint.sh /opt/
# Wildcard so it covers decom.sh present (3.1+) and not present (pre-3.1)
#COPY kubernetes/dockerfiles/spark/decom.sh* /opt/
COPY examples /opt/spark/examples
#COPY kubernetes/tests /opt/spark/tests
COPY data /opt/spark/data
# We need to copy over the license file so we can pip install PySpark
COPY LICENSE /opt/spark/LICENSE
COPY licenses /opt/spark/licenses

ENV SPARK_HOME /opt/spark

# Note: don't change the workdir since then your Jupyter notebooks won't persist.
RUN chmod g+w /opt/spark/work-dir
# Wildcard so it covers decom.sh present (3.1+) and not present (pre-3.1)
RUN chmod a+x /opt/decom.sh* || echo "No decom script present, assuming pre-3.1"

# Copy pyspark with setup files and everything
COPY python ${SPARK_HOME}/python

# Add PySpark to PYTHON_PATH

RUN pip install -e ${SPARK_HOME}/python

# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.179/aws-java-sdk-bundle-1.12.179.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar ${SPARK_HOME}/jars/
# Spark installation
#WORKDIR /tmp
#RUN wget -q "https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
#    echo "${spark_checksum} *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
#    tar xzf "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /usr/local --owner root --group root --no-same-owner && \
#    rm "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

#WORKDIR /usr/local

# Configure Spark
#ENV SPARK_HOME=/usr/local/spark
#ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
#    PATH="${PATH}:${SPARK_HOME}/bin"

#RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark && \
 #   # Add a link in the before_notebook hook in order to source automatically PYTHONPATH
 #   mkdir -p /usr/local/bin/before-notebook.d && \
 #   ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Fix Spark installation for Java 11 and Apache Arrow library
# see: https://github.com/apache/spark/pull/27356, https://spark.apache.org/docs/latest/#downloading
#RUN cp -p "${SPARK_HOME}/conf/spark-defaults.conf.template" "${SPARK_HOME}/conf/spark-defaults.conf" && \
#    echo 'spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
#    echo 'spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf"

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar 

# Configure IPython system-wide
COPY ipython_kernel_config.py "/etc/ipython/"
RUN fix-permissions "/etc/ipython/"

USER ${NB_UID}

# Install pyarrow
RUN arch=$(uname -m) && \
    if [ "${arch}" == "aarch64" ]; then \
        # Prevent libmamba from sporadically hanging on arm64 under QEMU
        # <https://github.com/mamba-org/mamba/issues/1611>
        export G_SLICE=always-malloc; \
    fi && \
    mamba install --quiet --yes \
    'pyarrow' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

WORKDIR "${HOME}"

# Should match the service
EXPOSE 2222
EXPOSE 7777