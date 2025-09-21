# GitHub Actions Update Management for Jupyter Spark Docker

## Overview

This directory contains automation to help keep GitHub Actions up to date in your workflows. Keeping actions updated is important for security, bug fixes, and new features.

## Automated Update Systems

### 1. Dependabot Configuration (`.github/dependabot.yml`)

**What it does:**
- Automatically checks for GitHub Actions updates weekly
- Creates pull requests when new versions are available
- Groups related actions together (e.g., all Docker actions)
- Also monitors Dockerfile base images

**Configuration:**
- Runs weekly on Mondays at 9:00 AM UTC
- Limited to 10 open PRs to avoid spam
- Automatically assigns PRs to repository owner

### 2. Weekly Update Check Workflow (`.github/workflows/check-action-updates.yml`)

**What it does:**
- Runs weekly on Mondays at 9:00 AM UTC
- Scans all workflow files for action versions
- Creates a summary report of current versions
- Opens GitHub issues as reminders to check for updates

**Manual trigger:**
```bash
# You can manually trigger this via GitHub UI or:
gh workflow run check-action-updates.yml
```

### 3. Manual Update Checker Script (`scripts/check-action-versions.sh`)

**What it does:**
- Local script to check action versions against latest releases
- Provides colored output showing which actions need updates
- Can be run locally during development

**Usage:**
```bash
# Run from repository root
./scripts/check-action-versions.sh
```

## Current Actions in Use

The project currently uses these GitHub Actions:

| Action | Purpose | Current Version |
|--------|---------|-----------------|
| `actions/checkout` | Checkout repository code | `v4` |
| `docker/setup-qemu-action` | Set up QEMU for multi-arch builds | `v3` |
| `docker/setup-buildx-action` | Set up Docker Buildx | `v3` |
| `docker/login-action` | Login to Docker registry | `v3` |
| `docker/build-push-action` | Build and push Docker images | `v6` |
| `actions/github-script` | Run JavaScript in workflows | `v7` |

## Manual Update Process

### Step 1: Check for Updates
1. Visit each action's GitHub repository
2. Check the "Releases" tab for latest versions
3. Review changelog for breaking changes

### Step 2: Update Workflow Files
1. Edit `.github/workflows/*.yml` files
2. Update version numbers (e.g., `@v4` → `@v5`)
3. Update version comments in workflow files

### Step 3: Test Updates
1. Create a test branch
2. Push changes to trigger workflows
3. Verify all workflows run successfully
4. Check for any deprecation warnings

### Step 4: Apply Updates
1. Merge changes to main branch
2. Monitor subsequent workflow runs
3. Close any related update issues

## Security Best Practices

### Use Specific Version Tags
```yaml
# ✅ Good - Specific version
uses: actions/checkout@v4

# ❌ Avoid - Branch names (security risk)
uses: actions/checkout@main
```

### Pin to Full SHA (for sensitive workflows)
```yaml
# 🔒 Most secure - Full SHA pin
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

### Monitor Security Advisories
- Enable GitHub security alerts for the repository
- Subscribe to security advisories for critical actions
- Review Dependabot security updates promptly

## Troubleshooting

### Dependabot PRs Not Created
1. Check if Dependabot is enabled in repository settings
2. Verify `.github/dependabot.yml` syntax is correct
3. Ensure repository has appropriate permissions

### Workflow Update Check Fails
1. Check if workflow has necessary permissions
2. Verify GitHub token has required scopes
3. Check workflow syntax in GitHub Actions tab

### Action Updates Break Workflows
1. Review action's changelog for breaking changes
2. Check workflow logs for specific error messages
3. Consider pinning to previous working version temporarily
4. Update workflow syntax for breaking changes

## Maintenance Schedule

| Task | Frequency | Automation |
|------|-----------|------------|
| Check for updates | Weekly | ✅ Automated |
| Review Dependabot PRs | As needed | 📧 Notifications |
| Apply critical security updates | Immediately | 🚨 Manual priority |
| Test major version updates | Before applying | 🧪 Manual testing |

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)