# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| daily builds | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it by:

1. **DO NOT** create a public GitHub issue
2. Send an email to the maintainer with details of the vulnerability
3. Include steps to reproduce the issue
4. Provide any relevant logs or error messages

### What to include in your report:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if known)

### Response Timeline:

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Fix and Release**: Varies based on severity

## Security Best Practices

When using these Docker images:

1. **Never use default passwords** - Always change `JUPYTER_TOKEN` in production
2. **Use HTTPS** - Configure TLS for JupyterLab in production environments
3. **Limit network exposure** - Use firewalls and proper network segmentation
4. **Regular updates** - Pull latest images regularly for security patches
5. **Resource limits** - Set appropriate memory and CPU limits in Kubernetes
6. **Secrets management** - Use Kubernetes secrets or similar for sensitive data

## Known Security Considerations

- Images run with non-root user by default
- JupyterLab runs with token authentication
- Spark uses cluster authentication in Kubernetes mode
- S3 credentials should be provided via environment variables or IAM roles