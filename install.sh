#!/usr/bin/env bash
# Claude Code Merged Installer
# Usage: curl -fsSL https://your-repo.com/merged_install.sh | bash
# or: wget -qO- https://your-repo.com/merged_install.sh | bash

set -euo pipefail

# Configuration
REPO_URL="https://github.com/plusplusoneplusplus/ccc.git"
REPO_NAME="ccc"
CLAUDE_SOURCE_DIR="${HOME}/.claude-source-git"
CLAUDE_DIR="${HOME}/.claude"
BACKUP_DIR="${HOME}/.claude.backup.$(date +%Y%m%d_%H%M%S)"

# Default options
FORCE=0
DRY_RUN=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

usage() {
    cat <<EOF
${BLUE}Claude Code Merged Installer${NC}

${PURPLE}Usage:${NC} $(basename "$0") [options]

${PURPLE}Options:${NC}
  -f, --force        Replace existing configuration and source
  -n, --dry-run      Show what would be done without making changes
  -r, --repo-url     Repository URL to clone from (default: $REPO_URL)
  -s, --source-dir   Source directory for persistent storage (default: $CLAUDE_SOURCE_DIR)
  -h, --help         Show this help message

${PURPLE}Examples:${NC}
  $(basename "$0")                          # Standard installation
  $(basename "$0") --force                  # Force overwrite existing setup
  $(basename "$0") --dry-run                # Preview installation steps

${BLUE}This script will:${NC}
  • Clone the Claude configuration repository to a persistent location
  • Create backup of existing ~/.claude if present
  • Set up symbolic link from ~/.claude to the source directory
  • Configure necessary permissions and directories

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=1
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -r|--repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        -s|--source-dir)
            CLAUDE_SOURCE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Utility functions
log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

run_command() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${BLUE}[DRY-RUN]${NC} $*"
    else
        eval "$*"
    fi
}

print_header() {
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                     Claude Code Configuration Installer                      ║${NC}"
    echo -e "${PURPLE}║                                                                              ║${NC}"
    echo -e "${PURPLE}║  This script will download and set up your Claude Code configuration         ║${NC}"
    echo -e "${PURPLE}║  with persistent storage and symbolic linking.                               ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

check_dependencies() {
    log "Checking system dependencies..."
    
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl or wget")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        error "Please install the missing dependencies and try again."
        exit 1
    fi
    
    log "✓ All dependencies satisfied"
}

backup_existing_claude() {
    if [[ -e "$CLAUDE_DIR" ]]; then
        if [[ $FORCE -eq 0 && $DRY_RUN -eq 0 ]]; then
            warn "Existing Claude configuration found at $CLAUDE_DIR"
            echo -n "Do you want to backup and replace it? [Y/n] "
            read -r response
            if [[ "$response" =~ ^[Nn]$ ]]; then
                log "Setup cancelled by user"
                exit 0
            fi
        elif [[ $DRY_RUN -eq 1 ]]; then
            warn "Existing Claude configuration found at $CLAUDE_DIR"
            log "In dry-run mode: would prompt to backup and replace"
        fi
        
        log "Creating backup at $BACKUP_DIR"
        run_command "cp -r \"$CLAUDE_DIR\" \"$BACKUP_DIR\""
        log "✓ Backup created at $BACKUP_DIR"
        
        log "Removing existing configuration"
        run_command "rm -rf \"$CLAUDE_DIR\""
    fi
}

download_or_update_source() {
    log "Setting up Claude source repository..."
    
    if [[ -d "$CLAUDE_SOURCE_DIR" ]]; then
        if [[ $FORCE -eq 1 ]]; then
            log "Removing existing source directory"
            run_command "rm -rf \"$CLAUDE_SOURCE_DIR\""
        else
            log "Updating existing repository at $CLAUDE_SOURCE_DIR"
            if [[ $DRY_RUN -eq 0 ]]; then
                cd "$CLAUDE_SOURCE_DIR"
                if git rev-parse --git-dir > /dev/null 2>&1; then
                    run_command "git fetch origin"
                    run_command "git reset --hard origin/main"
                    log "✓ Repository updated successfully"
                    return
                else
                    warn "Source directory exists but is not a git repository"
                    log "Removing and re-cloning"
                    run_command "rm -rf \"$CLAUDE_SOURCE_DIR\""
                fi
            else
                echo -e "${BLUE}[DRY-RUN]${NC} cd \"$CLAUDE_SOURCE_DIR\" && git fetch origin && git reset --hard origin/main"
                return
            fi
        fi
    fi
    
    log "Cloning repository from $REPO_URL"
    run_command "git clone \"$REPO_URL\" \"$CLAUDE_SOURCE_DIR\""
    
    log "✓ Repository downloaded successfully"
}

setup_permissions() {
    log "Setting up file permissions..."
    
    # Make shell scripts executable
    run_command "find \"$CLAUDE_SOURCE_DIR\" -name '*.sh' -type f -exec chmod +x {} +"
    
    log "✓ Permissions configured"
}

create_symlink() {
    log "Setting up symbolic link..."
    
    if [[ -e "$CLAUDE_DIR" || -L "$CLAUDE_DIR" ]]; then
        if [[ -L "$CLAUDE_DIR" ]]; then
            local current_target
            current_target="$(readlink "$CLAUDE_DIR")"
            if [[ "$current_target" == "$CLAUDE_SOURCE_DIR" ]]; then
                log "✓ Symbolic link already exists and points to correct location"
                return
            fi
        fi
        
        warn "Removing existing ~/.claude to create symbolic link"
        run_command "rm -rf \"$CLAUDE_DIR\""
    fi
    
    log "Creating symbolic link: $CLAUDE_DIR -> $CLAUDE_SOURCE_DIR"
    run_command "ln -s \"$CLAUDE_SOURCE_DIR\" \"$CLAUDE_DIR\""
    log "✓ Symbolic link created successfully"
}

verify_installation() {
    log "Verifying installation..."
    
    local files_to_check=(
        "$CLAUDE_DIR/settings.json"
        "$CLAUDE_DIR/statusline-enhanced.sh"
    )
    
    local all_good=1
    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            log "✓ Found: $(basename "$file")"
        else
            error "✗ Missing: $file"
            all_good=0
        fi
    done
    
    # Check if symlink is correct
    if [[ -L "$CLAUDE_DIR" ]]; then
        local link_target
        link_target="$(readlink "$CLAUDE_DIR")"
        if [[ "$link_target" == "$CLAUDE_SOURCE_DIR" ]]; then
            log "✓ Symbolic link is correctly configured"
        else
            error "✗ Symbolic link points to wrong location: $link_target"
            all_good=0
        fi
    else
        error "✗ ~/.claude is not a symbolic link"
        all_good=0
    fi
    
    if [[ $all_good -eq 1 ]]; then
        log "✓ Installation verification passed"
    else
        error "Installation verification failed"
        exit 1
    fi
}

print_completion_message() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          Installation Complete! 🎉                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}Your Claude Code configuration has been successfully installed!${NC}"
    echo
    echo -e "${PURPLE}Source repository:${NC} $CLAUDE_SOURCE_DIR"
    echo -e "${PURPLE}Configuration symlink:${NC} $CLAUDE_DIR -> $CLAUDE_SOURCE_DIR"
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${PURPLE}Previous config backed up to:${NC} $BACKUP_DIR"
    fi
    echo
    echo -e "${BLUE}Key features:${NC}"
    echo -e "  • Persistent source repository for easy updates"
    echo -e "  • Custom statusline with enhanced information"
    echo -e "  • GitHub submission workflow commands"
    echo -e "  • Project-specific configurations"
    echo -e "  • Command history and shell snapshots"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Restart Claude Code or reload your configuration"
    echo -e "  2. Check ~/.claude/settings.json for customization options"
    echo -e "  3. Explore ~/.claude/commands/ for available commands"
    echo
    echo -e "${BLUE}To update in the future:${NC}"
    echo -e "  • Run this script again to pull the latest changes"
    echo -e "  • Or manually: cd $CLAUDE_SOURCE_DIR && git pull"
    echo
    echo -e "${GREEN}Happy coding with Claude! 🚀${NC}"
}

# Main execution
main() {
    print_header
    
    if [[ $DRY_RUN -eq 1 ]]; then
        warn "DRY RUN MODE - No actual changes will be made"
        echo
    fi
    
    log "Welcome to the Claude Code configuration installer!"
    echo
    
    check_dependencies
    backup_existing_claude
    download_or_update_source
    setup_permissions
    create_symlink
    
    if [[ $DRY_RUN -eq 0 ]]; then
        verify_installation
    fi
    
    print_completion_message
}

# Run main function
main "$@"
