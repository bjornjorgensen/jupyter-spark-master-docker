# Copilot Instructions

## Project Overview

This project builds daily Docker images for distributed data science workflows, combining Debian Testing, JupyterLab, Apache Spark (master branch), and optimized Python packages. The architecture supports both local Docker development and Kubernetes production deployments.

## Architecture Components

### Multi-Stage Docker Build System
- **spark-builder**: Base image that compiles Apache Spark from source (`spark-builder/Dockerfile`)
- **spark-driver**: JupyterLab-enabled container for interactive development (`driver/Dockerfile`) 
- **spark-worker**: Lightweight Spark executor nodes for distributed processing (`worker/Dockerfile`)
- **dep-builder**: Base dependency layer (referenced but not in this repo)

### Key Build Dependencies
- Uses `uv` package manager instead of pip for faster Python dependency resolution
- Builds Apache Spark from master branch using `./dev/make-distribution.sh --name custom-spark --pip --tgz -Pkubernetes`
- Includes S3A support with specific AWS SDK and Hadoop versions (1.12.608 and 3.3.6)
- OpenJDK 25 for latest Java compatibility

## Development Workflows

### Local Development
```bash
# Change JUPYTER_TOKEN in docker-compose.yaml first
docker-compose up -d
# Access JupyterLab at localhost:8888, Spark UI at localhost:4040
```

### Kubernetes Deployment
Use Helm chart in `charts/pyspark-notebook/` with required node labeling:
```bash
kubectl label nodes <NODE> node-role=spark-driver  # Best specs node
kubectl label nodes <NODE> node-role=spark-worker  # All worker nodes
```

### Spark Session Patterns
The project uses two distinct SparkSession configurations:
- **Local mode**: Auto-detects all CPU cores and memory (`local[{number_cores}]`)
- **K8s mode**: Complex configuration with persistent volumes, MinIO integration, and node selectors

## Critical Configuration Points

### Python Environment
- Virtual environment at `/opt/venv` activated via `docker-entrypoint.sh`
- Key packages: `jupyterlab`, `google-generativeai`, `psycopg2-binary`, `pandas`, `openpyxl`
- PySpark installed from compiled Spark distribution, not PyPI

### Kubernetes Specifics
- ServiceAccount with `cluster-admin` role required for Spark driver authentication
- Persistent volume claims expected at `/opt/spark/work-dir`
- MinIO S3 integration with path-style access enabled
- Driver runs on `spark-driver` labeled nodes, executors on `spark-worker` nodes

### Build Automation
- Daily builds triggered at 7 AM UTC via GitHub Actions
- Three-stage build: spark-builder → worker/driver (parallel)
- Images tagged with date (`ddmmyyyy`) and `latest`

## File Structure Conventions

- `driver/`: JupyterLab + Spark driver image with development tools
- `worker/`: Minimal Spark executor image for distributed processing
- `spark-builder/`: Base image for compiling Spark from source
- `charts/pyspark-notebook/`: Helm deployment templates with RBAC and persistence
- Configuration files follow Kubernetes naming: `configMap`, `serviceAccount`, `roleBinding`

## Important Notes

- Spark master branch provides bleeding-edge features but may have stability issues
- Memory allocation in K8s mode assumes driver pulls all data for pandas operations
- S3A jars are manually added for object storage compatibility
- JupyterLab announcements extension disabled by default
- Uses `tini` as init system in all containers for proper signal handling