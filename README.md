# Multi-Shell Setup Script

A comprehensive shell setup system that installs modern terminal utilities and configures multiple shells (bash, zsh, nushell) with consistent aliases and enhanced functionality.

## Features

- **Modern CLI Tools**: Installs 40+ modern command-line tools including exa, bat, zoxide, helix, ripgrep, and more
- **Multi-Shell Support**: Configures bash, zsh, and nushell with consistent aliases and functionality
- **Architecture Detection**: Automatically detects CPU architecture (x86_64/aarch64) for proper tool installation
- **Starship Prompt**: Configures beautiful, fast prompts across all shells
- **Docker Integration**: Installs Docker and lazydocker for container management
- **Nerd Font**: Installs MesloLGS Nerd Font Mono for proper terminal display
- **Cross-Shell Consistency**: Identical aliases and behavior across all supported shells

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd multi-shell-setup

# Run the full setup
./setup.sh

# Or with verbose output
./setup.sh --verbose
```

## Usage

```bash
./setup.sh [OPTIONS]

OPTIONS:
    --skip-tools        Skip tool installation phase
    --shell <name>      Configure only specific shell (bash|zsh|nushell)
    --test-only         Run tests without installation
    --verbose           Enable detailed logging
    --help              Show help message
```

### Examples

```bash
# Full installation with detailed output
./setup.sh --verbose

# Configure only zsh
./setup.sh --shell zsh

# Skip tool installation, configure shells only
./setup.sh --skip-tools

# Run verification tests only
./setup.sh --test-only
```

## Installed Tools

### File System & Navigation
- **exa**: Modern replacement for `ls` with colors and Git integration
- **tree**: Display directory contents in tree format
- **zoxide**: Smart `cd` replacement that learns your habits
- **fd**: Fast and user-friendly alternative to `find`
- **bat**: `cat` clone with syntax highlighting
- **superfile**: Modern terminal file manager

### Search & Processing
- **ripgrep**: Extremely fast text search tool
- **fzf**: Command-line fuzzy finder
- **jq**: Command-line JSON processor
- **delta**: Git diff viewer with syntax highlighting

### System Monitoring
- **btop**: Beautiful system monitor
- **duf**: User-friendly `df` alternative
- **procs**: Modern replacement for `ps`
- **fastfetch**: System information display

### Development Tools
- **helix**: Modern text editor (set as default)
- **lnav**: Advanced log file viewer
- **lazydocker**: Terminal UI for Docker management

### Network & API
- **dog**: Modern DNS lookup tool
- **httpie**: User-friendly HTTP client

### Terminal Management
- **zellij**: Modern terminal multiplexer
- **starship**: Fast, customizable prompt for any shell

### Help & Documentation
- **tealdeer**: Fast `tldr` client for command examples

## Shell Configurations

### Bash
- Enhanced `.bashrc` based on your existing configuration
- Modern tool aliases and functions
- Starship prompt integration
- Zoxide smart navigation

### Zsh
- Complete `.zshrc` with plugin support
- Syntax highlighting and auto-suggestions
- Auto-completion enhancements
- Consistent aliases with bash and nushell

### Nushell
- Full configuration with `config.nu` and `env.nu`
- Structured data approach to command output
- Starship and zoxide integration
- Modern tool aliases using nushell syntax

## Consistent Aliases

All shells provide identical aliases for modern tools:

```bash
# File operations
ls → exa (with various combinations: la, ll, lt, etc.)
cat → bat
find → fd

# System monitoring
ps → procs
df → duf
top → btop

# Text processing
grep → ripgrep

# Network
dig → dog

# Editor
vi/vim/nvim → helix

# Navigation
cd → enhanced with zoxide (z command)
```

## Architecture Support

The script automatically detects your CPU architecture and installs appropriate binaries:
- **x86_64**: Standard Intel/AMD 64-bit
- **aarch64**: ARM 64-bit (Apple Silicon, ARM servers)

## Requirements

- Ubuntu/Debian-based system
- `sudo` privileges
- Internet connection for downloading tools
- Basic tools: `curl`, `wget`, `git`

## Project Structure

```
multi-shell-setup/
├── setup.sh                    # Main setup script
├── scripts/                    # Child scripts
│   ├── install_tools.sh        # Tool installation
│   ├── setup_bash.sh           # Bash configuration
│   ├── setup_zsh.sh            # Zsh configuration
│   ├── setup_nushell.sh        # Nushell configuration
│   ├── create_aliases.sh       # Cross-shell aliases
│   └── test_installation.sh    # Verification tests
├── configs/                    # Configuration files
│   ├── .bashrc                 # Enhanced bash config
│   ├── .zshrc                  # Zsh configuration
│   ├── starship.toml           # Starship prompt config
│   ├── nushell/                # Nushell configs
│   └── docker/                 # Docker configuration
└── README.md                   # This file
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you have sudo privileges
2. **Network Issues**: Check internet connection for downloads
3. **Architecture Problems**: Script auto-detects, but verify with `uname -m`
4. **Package Conflicts**: Some tools may conflict with existing installations

### Logs

Check the setup log for detailed information:
```bash
cat setup.log
```

### Manual Testing

Run verification tests independently:
```bash
./scripts/test_installation.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. See LICENSE file for details.

## Acknowledgments

- Inspired by modern CLI tool collections
- Built for developers who want a consistent, powerful terminal experience
- Thanks to all the amazing tool creators in the Rust and CLI communities