#!/bin/bash

# Jupyter Spark Development Environment Helper Script
# This script provides convenient commands for managing the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Function to show help
show_help() {
    cat << EOF
Jupyter Spark Development Environment Helper

Usage: $0 [COMMAND]

Commands:
    setup      - Initial setup: copy .env.example to .env and create directories
    start      - Start the development environment
    stop       - Stop the development environment
    restart    - Restart the development environment
    logs       - Show container logs
    status     - Show container status
    clean      - Stop and remove containers, networks, and volumes
    build      - Build images locally
    shell      - Open shell in running container
    notebook   - Open JupyterLab in browser
    spark-ui   - Open Spark UI in browser
    help       - Show this help message

Examples:
    $0 setup     # First time setup
    $0 start     # Start services
    $0 logs      # View logs
    $0 clean     # Clean up everything

EOF
}

# Function to check if docker-compose is available
check_dependencies() {
    if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
        print_error "Docker and docker-compose are required but not installed."
        exit 1
    fi
    
    # Check if we're using docker compose (new) or docker-compose (old)
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        print_error "Neither 'docker compose' nor 'docker-compose' is available."
        exit 1
    fi
}

# Function for initial setup
setup() {
    print_info "Setting up development environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
            print_warning "Please edit .env file with your preferred settings"
        else
            print_error ".env.example file not found"
            exit 1
        fi
    else
        print_info ".env file already exists"
    fi
    
    # Create necessary directories
    mkdir -p test_notebooks data
    print_success "Created directories: test_notebooks, data"
    
    print_success "Setup complete! Run '$0 start' to begin"
}

# Start services
start() {
    print_info "Starting development environment..."
    $DOCKER_COMPOSE up -d
    print_success "Services started!"
    print_info "JupyterLab: http://localhost:8888"
    print_info "Spark UI: http://localhost:4040 (available when running Spark jobs)"
}

# Stop services
stop() {
    print_info "Stopping development environment..."
    $DOCKER_COMPOSE down
    print_success "Services stopped!"
}

# Restart services
restart() {
    print_info "Restarting development environment..."
    $DOCKER_COMPOSE restart
    print_success "Services restarted!"
}

# Show logs
logs() {
    print_info "Showing container logs (press Ctrl+C to exit)..."
    $DOCKER_COMPOSE logs -f
}

# Show status
status() {
    print_info "Container status:"
    $DOCKER_COMPOSE ps
}

# Clean up
clean() {
    print_warning "This will remove all containers, networks, and volumes."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning up..."
        $DOCKER_COMPOSE down -v --remove-orphans
        docker system prune -f
        print_success "Cleanup complete!"
    else
        print_info "Cleanup cancelled"
    fi
}

# Build images
build() {
    print_info "Building images locally..."
    $DOCKER_COMPOSE build --no-cache
    print_success "Build complete!"
}

# Open shell in container
shell() {
    print_info "Opening shell in jupyter container..."
    $DOCKER_COMPOSE exec jupyter bash
}

# Open JupyterLab in browser
notebook() {
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:8888
    elif command -v open &> /dev/null; then
        open http://localhost:8888
    else
        print_info "Please open http://localhost:8888 in your browser"
    fi
}

# Open Spark UI in browser
spark_ui() {
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:4040
    elif command -v open &> /dev/null; then
        open http://localhost:4040
    else
        print_info "Please open http://localhost:4040 in your browser"
    fi
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-help}" in
        setup)
            setup
            ;;
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        logs)
            logs
            ;;
        status)
            status
            ;;
        clean)
            clean
            ;;
        build)
            build
            ;;
        shell)
            shell
            ;;
        notebook)
            notebook
            ;;
        spark-ui)
            spark_ui
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"