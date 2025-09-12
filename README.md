# ccc (claude-code-config)

Enhanced Claude Code configuration with custom commands, statusline, and workflow automation.

## 🚀 Quick Installation

```bash
curl -fsSL https://raw.githubusercontent.com/plusplusoneplusplus/ccc/main/install.sh | bash
```

## 📦 Manual Installation

```bash
git clone https://github.com/plusplusoneplusplus/ccc.git
cd ccc
./setup.sh
```

## ✨ Features

- **Enhanced Statusline**: Custom statusline with git status and project information
- **GitHub Workflows**: Automated PR creation and submission workflows
- **One-liner Install**: oh-my-zsh style installation
- **Backup Protection**: Automatically backs up existing configurations
- **Dry Run Mode**: Preview changes before applying

## ⚙️ Installation Options

```bash
# Standard installation
./setup.sh

# Force overwrite existing setup
./setup.sh --force

# Preview what would happen
./setup.sh --dry-run

# Install to custom directory
./setup.sh --claude-dir ~/my-claude

# Show all options
./setup.sh --help
```

## 📁 What Gets Installed

- `~/.claude/settings.json` - Main configuration
- `~/.claude/statusline-enhanced.sh` - Custom statusline
- `~/.claude/commands/` - Custom command library
- `~/.claude/link_claude.sh` - Symlink management

## 🔄 Updating

```bash
# Re-run installer to get latest version
curl -fsSL https://raw.githubusercontent.com/plusplusoneplusplus/ccc/main/install.sh | bash
```

## 🛠️ Development

```bash
# Clone for development
git clone https://github.com/plusplusoneplusplus/ccc.git
cd ccc

# Test changes
./setup.sh --dry-run

# Install locally
./setup.sh --force
```

---

**Repository**: [https://github.com/plusplusoneplusplus/ccc](https://github.com/plusplusoneplusplus/ccc)