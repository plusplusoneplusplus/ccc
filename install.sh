#!/usr/bin/env bash
# Claude Code One-line installer
# Usage: curl -fsSL https://your-repo.com/install.sh | bash
# or: wget -qO- https://your-repo.com/install.sh | bash

set -euo pipefail

# Configuration
REPO_URL="https://github.com/plusplusoneplusplus/breadthseek.git"
REPO_NAME="breadthseek"
CLAUDE_DIR="${HOME}/.claude"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

print_header() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     Claude Code Configuration Installer                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v git &> /dev/null; then
        error "git is required but not installed. Please install git and try again."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        error "Either curl or wget is required but neither is installed."
        exit 1
    fi
    
    log "✓ Dependencies satisfied"
}

install_config() {
    log "Installing Claude Code configuration..."
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Cleanup function
    cleanup() {
        rm -rf "$temp_dir"
    }
    trap cleanup EXIT
    
    # Clone repository
    log "Downloading configuration from $REPO_URL"
    if ! git clone "$REPO_URL" "$temp_dir/$REPO_NAME" 2>/dev/null; then
        error "Failed to clone repository. Please check the URL and your internet connection."
        exit 1
    fi
    
    # Check if claude directory exists in the repo
    local claude_source="$temp_dir/$REPO_NAME/claude"
    if [[ ! -d "$claude_source" ]]; then
        error "Claude configuration directory not found in repository"
        exit 1
    fi
    
    # Run the setup script
    if [[ -x "$claude_source/setup.sh" ]]; then
        log "Running setup script..."
        "$claude_source/setup.sh" --force
    else
        error "Setup script not found or not executable"
        exit 1
    fi
}

main() {
    print_header
    
    log "Welcome to the Claude Code configuration installer!"
    echo
    
    check_dependencies
    install_config
    
    echo
    echo -e "${GREEN}🎉 Installation complete!${NC}"
    echo -e "Your Claude Code configuration is now set up at ${BLUE}$CLAUDE_DIR${NC}"
    echo
    echo -e "To get started:"
    echo -e "  • Restart Claude Code"
    echo -e "  • Check $CLAUDE_DIR/settings.json for configuration options"
    echo -e "  • Explore $CLAUDE_DIR/commands/ for available commands"
    echo
}

main "$@"