FROM bjornjorgensen/spark-builder AS builder

FROM debian:testing

USER root

ARG openjdk_version="22"
ARG spark_uid=185

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    apt install -y "openjdk-${openjdk_version}-jdk-headless" \
    ca-certificates-java \
    bash \
    tini \
    libc6 \
    libpam-modules \
    krb5-user \
    libnss3 \
    procps \
    net-tools \
    curl \
    bzip2 \
    python3 \
    python3-pip \
    procps && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

# Install pandas using pip
RUN python3 -m pip install --no-cache-dir --break-system-packages pandas==2.2.2 pyarrow


# Spark installation
WORKDIR /tmp


COPY --from=builder /tmp/spark/spark-4.0.0-SNAPSHOT-bin-custom-spark.tgz /tmp/spark.tgz

RUN tar xzf "spark.tgz" -C /usr/local --owner root --group root --no-same-owner && \
  rm "spark.tgz"

RUN mv /usr/local/spark-4.0.0-SNAPSHOT-bin-custom-spark /opt/spark

# Configure Spark paths
ENV SPARK_HOME="/opt/spark"
ENV PATH="${SPARK_HOME}/bin:${PATH}"


# Install PySpark from the local Spark directory
RUN python3 -m pip install --no-cache-dir --break-system-packages -e /opt/spark/python/packaging/classic

RUN ln -s "spark" "${SPARK_HOME}";

RUN cp ${SPARK_HOME}/kubernetes/dockerfiles/spark/entrypoint.sh /opt/
RUN cp ${SPARK_HOME}/kubernetes/dockerfiles/spark/decom.sh /opt/

RUN ln -s $(basename $(ls /opt/spark/examples/jars/spark-examples_*.jar)) /opt/spark/examples/jars/spark-examples.jar
RUN cp -r ${SPARK_HOME}/kubernetes/tests /opt/spark/tests


# Add S3A support
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.608/aws-java-sdk-bundle-1.12.608.jar ${SPARK_HOME}/jars/
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar ${SPARK_HOME}/jars/

RUN chmod a+rx ${SPARK_HOME}/jars/*.jar
WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}
