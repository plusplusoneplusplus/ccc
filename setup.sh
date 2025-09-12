#!/usr/bin/env bash
# Claude Code Setup Script - Similar to oh-my-zsh installer
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default settings
CLAUDE_DIR="${HOME}/.claude"
REPO_URL="https://github.com/plusplusoneplusplus/breadthseek.git"
BACKUP_DIR="${HOME}/.claude.backup.$(date +%Y%m%d_%H%M%S)"
FORCE=0
DRY_RUN=0

usage() {
    cat <<EOF
${BLUE}Claude Code Setup Script${NC}

${PURPLE}Usage:${NC} $(basename "$0") [options]

${PURPLE}Options:${NC}
  -f, --force        Replace existing ~/.claude directory
  -n, --dry-run      Show what would be done without making changes
  -d, --claude-dir   Custom claude directory (default: ~/.claude)
  -r, --repo-url     Repository URL to clone from
  -h, --help         Show this help message

${PURPLE}Examples:${NC}
  $(basename "$0")                          # Standard installation
  $(basename "$0") --force                  # Force overwrite existing setup
  $(basename "$0") --claude-dir ~/myclaude  # Use custom directory
  $(basename "$0") --dry-run                # Preview installation steps

${BLUE}This script will:${NC}
  • Clone the Claude configuration repository
  • Set up symlinks to ~/.claude
  • Configure statusline and commands
  • Create necessary directories
  • Backup existing configuration if present

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
        -d|--claude-dir)
            CLAUDE_DIR="$2"
            shift 2
            ;;
        -r|--repo-url)
            REPO_URL="$2"
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
    echo -e "${PURPLE}║                        Claude Code Configuration Setup                      ║${NC}"
    echo -e "${PURPLE}║                                                                              ║${NC}"
    echo -e "${PURPLE}║  This script will set up your Claude Code configuration directory with      ║${NC}"
    echo -e "${PURPLE}║  custom commands, statusline, and other enhancements.                       ║${NC}"
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

backup_existing() {
    if [[ -e "$CLAUDE_DIR" ]]; then
        if [[ $FORCE -eq 0 ]]; then
            warn "Existing Claude configuration found at $CLAUDE_DIR"
            echo -n "Do you want to backup and replace it? [Y/n] "
            read -r response
            if [[ "$response" =~ ^[Nn]$ ]]; then
                log "Setup cancelled by user"
                exit 0
            fi
        fi
        
        log "Creating backup at $BACKUP_DIR"
        run_command "cp -r \"$CLAUDE_DIR\" \"$BACKUP_DIR\""
        log "✓ Backup created at $BACKUP_DIR"
        
        log "Removing existing configuration"
        run_command "rm -rf \"$CLAUDE_DIR\""
    fi
}

clone_or_copy_config() {
    log "Setting up Claude configuration..."
    
    # Check if we're running from within the repo
    if [[ -f "$(dirname "$0")/link_claude.sh" && -f "$(dirname "$0")/settings.json" ]]; then
        log "Detected local repository, copying configuration..."
        local source_dir="$(cd "$(dirname "$0")" && pwd)"
        
        run_command "mkdir -p \"$(dirname "$CLAUDE_DIR")\""
        run_command "cp -r \"$source_dir\" \"$CLAUDE_DIR\""
        
        # Make scripts executable
        run_command "find \"$CLAUDE_DIR\" -name '*.sh' -type f -exec chmod +x {} +"
        
        log "✓ Configuration copied from local repository"
    else
        if [[ "$REPO_URL" == "https://github.com/yourusername/yourrepo.git" ]]; then
            error "Repository URL not configured. Please update REPO_URL in the script or use --repo-url"
            exit 1
        fi
        
        log "Cloning configuration from $REPO_URL"
        run_command "git clone \"$REPO_URL\" \"$CLAUDE_DIR\""
        log "✓ Configuration cloned from repository"
    fi
}

create_directories() {
    log "Creating necessary directories..."
    
    local dirs=(
        "$CLAUDE_DIR/commands"
        "$CLAUDE_DIR/projects"
        "$CLAUDE_DIR/todos"
        "$CLAUDE_DIR/shell-snapshots"
        "$CLAUDE_DIR/statsig"
        "$CLAUDE_DIR/local"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            run_command "mkdir -p \"$dir\""
            log "✓ Created directory: $dir"
        else
            log "✓ Directory already exists: $dir"
        fi
    done
}

setup_symlinks() {
    log "Setting up symlinks (if needed)..."
    
    # Check if we need to create symlinks or if we already installed directly to ~/.claude
    if [[ "$CLAUDE_DIR" != "${HOME}/.claude" ]]; then
        local target_claude="${HOME}/.claude"
        
        if [[ -e "$target_claude" || -L "$target_claude" ]]; then
            if [[ -L "$target_claude" ]]; then
                local current_target
                current_target="$(readlink "$target_claude")"
                if [[ "$current_target" == "$CLAUDE_DIR" ]]; then
                    log "✓ Symlink already exists: $target_claude -> $CLAUDE_DIR"
                    return
                fi
            fi
            
            warn "Removing existing ~/.claude to create symlink"
            run_command "rm -rf \"$target_claude\""
        fi
        
        log "Creating symlink: $target_claude -> $CLAUDE_DIR"
        run_command "ln -s \"$CLAUDE_DIR\" \"$target_claude\""
        log "✓ Symlink created successfully"
    else
        log "✓ Configuration installed directly to ~/.claude"
    fi
}

verify_installation() {
    log "Verifying installation..."
    
    local files_to_check=(
        "$CLAUDE_DIR/settings.json"
        "$CLAUDE_DIR/statusline-enhanced.sh"
        "$CLAUDE_DIR/link_claude.sh"
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
    echo -e "${GREEN}║                          Setup Complete! 🎉                                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}Your Claude Code configuration has been successfully set up!${NC}"
    echo
    echo -e "${PURPLE}Configuration location:${NC} $CLAUDE_DIR"
    if [[ -L "${HOME}/.claude" ]]; then
        echo -e "${PURPLE}Symlinked to:${NC} ${HOME}/.claude"
    fi
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${PURPLE}Previous config backed up to:${NC} $BACKUP_DIR"
    fi
    echo
    echo -e "${BLUE}Available features:${NC}"
    echo -e "  • Custom statusline with enhanced information"
    echo -e "  • GitHub submission workflow commands"
    echo -e "  • Project-specific configurations"
    echo -e "  • Command history and shell snapshots"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Restart Claude Code or reload your configuration"
    echo -e "  2. Check ${CLAUDE_DIR}/settings.json for customization options"
    echo -e "  3. Explore ${CLAUDE_DIR}/commands/ for available commands"
    echo
    echo -e "${BLUE}For help and documentation:${NC}"
    echo -e "  • Check the commands directory for usage examples"
    echo -e "  • Modify settings.json to customize your setup"
    echo -e "  • Use the link_claude.sh script to manage symlinks"
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
    
    check_dependencies
    backup_existing
    clone_or_copy_config
    create_directories
    setup_symlinks
    
    if [[ $DRY_RUN -eq 0 ]]; then
        verify_installation
    fi
    
    print_completion_message
}

# Run main function
main "$@"