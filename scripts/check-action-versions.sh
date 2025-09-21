#!/bin/bash

# GitHub Actions Version Checker
# This script checks for the latest versions of GitHub Actions used in workflows

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get latest release tag from GitHub API
get_latest_version() {
    local repo=$1
    local current_version=$2
    
    # Use GitHub API to get latest release
    local latest=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -z "$latest" ]; then
        # Fallback to tags if no releases
        latest=$(curl -s "https://api.github.com/repos/$repo/tags" | grep '"name":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    fi
    
    echo "$latest"
}

# Function to compare versions
compare_versions() {
    local current=$1
    local latest=$2
    
    if [ "$current" = "$latest" ]; then
        return 0  # Same version
    elif [ "$(printf '%s\n' "$current" "$latest" | sort -V | head -n1)" = "$current" ]; then
        return 1  # Current is older
    else
        return 2  # Current is newer (pre-release?)
    fi
}

print_info "Checking GitHub Actions versions in workflow files..."
echo

# Find all workflow files
workflow_files=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null || echo "")

if [ -z "$workflow_files" ]; then
    print_error "No workflow files found in .github/workflows/"
    exit 1
fi

# Track actions to check
declare -A actions_found

# Parse workflow files for actions
for file in $workflow_files; do
    print_info "Checking $file..."
    
    # Extract action uses with versions
    while IFS= read -r line; do
        if [[ $line =~ uses:.*@ ]]; then
            # Extract the action reference
            action_ref=$(echo "$line" | sed 's/.*uses: *//; s/ *$//' | tr -d '"')
            
            # Skip local actions or actions without version
            if [[ "$action_ref" == ./* ]] || [[ "$action_ref" != *"@"* ]]; then
                continue
            fi
            
            action_name=$(echo "$action_ref" | cut -d@ -f1)
            current_version=$(echo "$action_ref" | cut -d@ -f2)
            
            # Skip if we've already processed this action
            if [[ -n "${actions_found[$action_name]}" ]]; then
                continue
            fi
            
            actions_found[$action_name]=$current_version
            
            print_info "  Found: $action_name@$current_version"
            
            # Get latest version
            print_info "  Checking latest version for $action_name..."
            latest_version=$(get_latest_version "$action_name" "$current_version")
            
            if [ -n "$latest_version" ]; then
                compare_versions "$current_version" "$latest_version"
                case $? in
                    0)
                        print_success "  ✓ $action_name is up to date ($current_version)"
                        ;;
                    1)
                        print_warning "  ⚠ $action_name can be updated: $current_version → $latest_version"
                        echo "    Repository: https://github.com/$action_name"
                        echo "    Changelog: https://github.com/$action_name/releases"
                        ;;
                    2)
                        print_info "  ℹ $action_name is using a pre-release or newer version: $current_version (latest: $latest_version)"
                        ;;
                esac
            else
                print_error "  ✗ Could not fetch latest version for $action_name"
            fi
            
            echo
        fi
    done < "$file"
done

echo
print_info "Version check complete!"
print_info "Consider updating outdated actions after reviewing their changelogs."
print_info "You can also enable Dependabot to automatically create PRs for updates."