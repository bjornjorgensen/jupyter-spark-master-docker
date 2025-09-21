# Jupyter Spark Master Docker

[![Build Status](https://github.com/bjornjorgensen/jupyter-spark-master-docker/actions/workflows/build_and_push_spark_images.yml/badge.svg)](https://github.com/bjornjorgensen/jupyter-spark-master-docker/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/bjornjorgensen/spark-driver)](https://hub.docker.com/r/bjornjorgensen/spark-driver)

This project provides daily-built Docker images designed for distributed data science workflows. These images combine Debian Testing, JupyterLab, Apache Spark (master branch), and optimized Python packages for both local development and production Kubernetes deployments.

## 🚀 Quick Start

1. Copy the environment template:
   ```bash
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

2. Start the environment:
   ```bash
   docker-compose up -d
   ```

3. Access JupyterLab at http://localhost:8888 (use token from .env file)

## Features

- **Debian Testing**: Ensures a stable and up-to-date operating system environment.
- **JupyterLab**: Offers an interactive development environment for data science projects.
- **Apache Spark (master branch)**: Provides the latest features and improvements from the Apache Spark project. Only Python and K8S package included.
- **Pandas (latest Spark supported version)**: Includes the most recent enhancements and fixes from the Pandas library.

## 📋 Prerequisites

- Docker and Docker Compose
- For Kubernetes: kubectl and Helm
- Minimum 4GB RAM recommended
- For production: 16GB+ RAM recommended

## 🏗️ Architecture

### Multi-Stage Build System
- **spark-builder**: Base image that compiles Apache Spark from source with all dependencies (`spark-builder/Dockerfile`)
- **spark-driver**: JupyterLab-enabled container for interactive development (`driver/Dockerfile`) 
- **spark-worker**: Lightweight Spark executor nodes for distributed processing (`worker/Dockerfile`)

### Key Technologies
- **OS**: Debian Testing (rolling release)
- **Python**: Latest stable with `uv` package manager
- **Spark**: Master branch with Kubernetes support
- **Storage**: S3A support for object storage integration

## 🐳 Usage

### Local Development

1. **Configuration**: Copy and customize the environment file:
   ```bash
   cp .env.example .env
   # Edit JUPYTER_TOKEN and other settings
   ```

2. **Start Services**:
   ```bash
   docker-compose up -d
   ```

3. **Access Points**:
   - JupyterLab: http://localhost:8888
   - Spark UI: http://localhost:4040

### Directory Structure
```
your-project/
├── .env                 # Your environment configuration
├── data/               # Mount point for datasets
├── test_notebooks/     # Jupyter notebooks
└── docker-compose.yaml # Service configuration
```

You can interact with the Apache Spark and Pandas frameworks directly from Python. Here's a brief setup for initializing a SparkSession and configuring it for your needs:

This configuration will start Spark utilizing all available memory and CPU cores on a single machine.

```python
import multiprocessing
import os
import numpy as np
import pandas as pd
import pyarrow as pa
from pyspark import pandas as ps
from pyspark.sql import SparkSession
import pyspark.sql.functions as SF

# Calculate the number of cores and memory usage for Spark configuration
number_cores = multiprocessing.cpu_count()
mem_bytes = os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES")  # Total memory in bytes
memory_gb = int(mem_bytes / (1024.0 ** 3))  # Convert bytes to gigabytes

# Initialize a SparkSession with custom configurations
spark = (SparkSession.builder
         .appName("pandas-on-spark")
         .master(f"local[{number_cores}]")  # Use all available cores
         # Set driver memory to the calculated memory size
         .config("spark.driver.memory", f"{memory_gb}g")
         # Enable adaptive query execution, which can optimize query plans automatically
         .config("spark.sql.adaptive.enabled", "True")
         # Use KryoSerializer for better performance in shuffle and cache operations
         .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
         # Limit the number of rows shown in eager evaluation output
         .config("spark.sql.repl.eagerEval.maxNumRows", "50")
         .getOrCreate())

# Optionally set log level to ERROR to reduce the amount of logs shown
spark.sparkContext.setLogLevel("ERROR")
```

`spark`

![alt text](media/image.png)

## Kubernetes Configuration

Run `kubectl label nodes <NODE> node-role=spark-driver` on the machine with the best specs. This is because `pandas-on-spark` will pull all data into the driver if the pandas function is not natively integrated in `pandas-on-spark`.

Run `kubectl label nodes <NODE> node-role=spark-worker` on every worker node you have in your K8S cluster.

This setup is tailored for data science workloads that require scalability and distributed processing capabilities.

```python

import numpy as np
import pandas as pd
import pyarrow as pa
from pyspark import pandas as ps
from pyspark.sql import SparkSession
import pyspark.sql.functions as SF

# Initialize a SparkSession with custom configurations
spark = SparkSession.builder \
  # Set the Spark master to connect to a Kubernetes cluster
  .master("k8s://https://kubernetes.default.svc.cluster.local:443") \
  # Specify the container image for the Spark worker nodes
  .config("spark.kubernetes.container.image", "bjornjorgensen/spark-worker") \
  # Set the pull policy for the container image to always pull the latest version
  .config("spark.kubernetes.container.image.pullPolicy", "Always") \
  # Configure authentication using a CA certificate file for Kubernetes
  .config("spark.kubernetes.authenticate.caCertFile", "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt") \
  # Configure authentication using an OAuth token file for Kubernetes
  .config("spark.kubernetes.authenticate.oauthTokenFile", "/var/run/secrets/kubernetes.io/serviceaccount/token") \
  # Set the service account name for the Spark driver
  .config("spark.kubernetes.authenticate.driver.serviceAccountName", "my-pyspark-notebook") \
  # Set the number of executor instances to 4
  .config("spark.executor.instances", "4") \
  # Set the hostname for the Spark driver
  .config("spark.driver.host", "my-pyspark-notebook-spark-driver.default.svc.cluster.local") \
  # Set the port for the Spark driver
  .config("spark.driver.port", "29413") \
  # Enable eager evaluation in Spark SQL REPL
  .config("spark.sql.repl.eagerEval.enabled", "True") \
  # Set the memory for the Spark driver to 50GB
  .config("spark.driver.memory", "50g") \
  # Set the memory for each Spark executor to 13GB
  .config("spark.executor.memory", "13g") \
  # Set the number of cores for the Spark driver to 13
  .config("spark.driver.cores", "13") \
  # Set the number of cores for each Spark executor to 6
  .config("spark.executor.cores", "6") \
  # Configure a persistent volume claim named "300gb" for the Spark driver
  .config("spark.kubernetes.driver.volumes.persistentVolumeClaim.300gb.options.claimName", "300gb") \
  # Mount the persistent volume claim at the specified path in the driver container
  .config("spark.kubernetes.driver.volumes.persistentVolumeClaim.300gb.mount.path", "/opt/spark/work-dir") \
  # Set the mount for the persistent volume claim to be read-write
  .config("spark.kubernetes.driver.volumes.persistentVolumeClaim.300gb.mount.readOnly", "False") \
  # Configure the same persistent volume claim for the Spark executors
  .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.300gb.options.claimName", "300gb") \
  .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.300gb.mount.path", "/opt/spark/work-dir") \
  .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.300gb.mount.readOnly", "False") \
  # Configure the access key for connecting to MinIO (S3-compatible storage)
  .config("fs.s3a.access.key", "minioadmin") \
  # Configure the secret key for connecting to MinIO
  .config("fs.s3a.secret.key", "Password") \
  # Set the endpoint URL for MinIO
  .config("fs.s3a.endpoint", "http://LOCALHOST:9000") \
  # Specify the implementation class for the S3 file system
  .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
  # Enable path-style access for S3 (required for MinIO)
  .config("spark.hadoop.fs.s3a.path.style.access", "true") \
  # Set a node selector to run the Spark driver on nodes with the label "node-role=spark-driver"
  .config("spark.kubernetes.node.selector.node-role", "spark-driver") \
  # Set a node selector to run the Spark executors on nodes with the label "node-role=spark-worker"
  .config("spark.kubernetes.executor.node.selector.node-role", "spark-worker") \
  # Enable adaptive query execution in Spark SQL for automatic query optimization
  .config("spark.sql.adaptive.enabled", "True") \
  # Use Kryo serialization for improved performance in shuffle and cache operations
  .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
  # Limit the maximum number of rows displayed in eager evaluation output to 50
  .config("spark.sql.repl.eagerEval.maxNumRows", "50") \
  # Set the application name to "pandas-on-spark"
  .appName("pandas-on-spark") \
  # Create the SparkSession with the specified configurations
  .getOrCreate()
```

## 📊 Performance Tuning

### Memory Configuration
- **Local**: Automatically detects and uses available system resources
- **Kubernetes**: Configure based on node capacity and workload requirements

### Recommended Settings
```yaml
# For 16GB nodes
spark.driver.memory: "8g"
spark.executor.memory: "6g"
spark.executor.cores: "4"

# For 32GB nodes  
spark.driver.memory: "16g"
spark.executor.memory: "12g"
spark.executor.cores: "6"
```

## 🔧 Troubleshooting

### Common Issues

**Issue**: JupyterLab won't start
```bash
# Check logs
docker-compose logs jupyter

# Verify port availability
netstat -tlnp | grep 8888
```

**Issue**: Spark jobs fail in Kubernetes
```bash
# Check Spark driver logs
kubectl logs -l app=my-pyspark-notebook

# Verify node labels
kubectl get nodes --show-labels | grep node-role
```

**Issue**: Out of memory errors
```bash
# Increase memory limits in .env
SPARK_DRIVER_MEMORY=8g
SPARK_EXECUTOR_MEMORY=6g

# Restart services
docker-compose restart
```

### Debug Mode
Enable debug logging:
```python
spark.sparkContext.setLogLevel("DEBUG")
```

## 🔒 Security

- **Default Authentication**: Token-based access to JupyterLab
- **Network Security**: Services bound to localhost by default
- **Container Security**: Runs as non-root user (jovyan)
- **Kubernetes**: RBAC-enabled with service accounts

See [SECURITY.md](SECURITY.md) for detailed security guidelines.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/improvement`
3. Make your changes and test them
4. Submit a pull request

### Development Setup
```bash
# Clone the repository
git clone https://github.com/bjornjorgensen/jupyter-spark-master-docker.git
cd jupyter-spark-master-docker

# Build images locally  
docker-compose build

# Test the setup
docker-compose up -d
```

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/bjornjorgensen/jupyter-spark-master-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bjornjorgensen/jupyter-spark-master-docker/discussions)
- **Documentation**: [Wiki](https://github.com/bjornjorgensen/jupyter-spark-master-docker/wiki)

## 🏷️ Tags and Versions

- `latest`: Most recent stable build
- `DDMMYYYY`: Daily builds (e.g., `23092025`)
- `spark-builder`: Base Spark compilation image
- `spark-driver`: JupyterLab-enabled driver image
- `spark-worker`: Lightweight worker image

````
```
