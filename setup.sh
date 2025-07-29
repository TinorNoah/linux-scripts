#!/bin/bash

# Multi-Shell Setup Script
# A comprehensive shell setup system that installs modern terminal utilities
# and configures bash, zsh, and nushell with consistent aliases and tools.

set -e  # Exit on any error

# Color codes for output
readonly RC=$(tput sgr0)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly GREEN=$(tput setaf 2)
readonly BLUE=$(tput setaf 4)

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"
VERBOSE=false
SKIP_TOOLS=false
SHELL_ONLY=""
TEST_ONLY=false

# Arrays to track installation results
declare -a SUCCESSFUL_TOOLS=()
declare -a FAILED_TOOLS=()

# Helper functions
print_colored() {
    printf "${1}%s${RC}\n" "$2"
}

log_info() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    print_colored "$GREEN" "✓ $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    print_colored "$RED" "✗ $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$LOG_FILE"
}

log_warning() {
    local message="$1"
    print_colored "$YELLOW" "⚠ $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$LOG_FILE"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        local message="$1"
        print_colored "$BLUE" "ℹ $message"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERBOSE: $message" >> "$LOG_FILE"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

show_usage() {
    cat << EOF
Multi-Shell Setup Script

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    --skip-tools        Skip tool installation phase
    --shell <name>      Configure only specific shell (bash|zsh|nushell)
    --test-only         Run tests without installation
    --verbose           Enable detailed logging
    --help              Show this help message

EXAMPLES:
    ./setup.sh                    # Full installation
    ./setup.sh --verbose          # Full installation with detailed output
    ./setup.sh --shell zsh        # Configure only zsh
    ./setup.sh --skip-tools       # Skip tool installation, configure shells only
    ./setup.sh --test-only        # Run verification tests only

EOF
}

check_environment() {
    log_info "Checking system environment and prerequisites..."
    
    # Check for required commands
    local requirements=('curl' 'wget' 'sudo' 'groups')
    for req in "${requirements[@]}"; do
        if ! command_exists "$req"; then
            log_error "Required command '$req' not found. Please install it first."
            exit 1
        fi
    done
    
    # Check if running on supported system
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            log_warning "This script is designed for Ubuntu/Debian. Your system: $ID"
            log_info "Continuing anyway, but some features may not work correctly."
        fi
    else
        # Handle macOS and other systems
        local os_name=$(uname -s)
        log_warning "This script is designed for Ubuntu/Debian. Your system: $os_name"
        log_info "Continuing anyway, but some features may not work correctly."
    fi
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges for package installation."
        if ! sudo true; then
            log_error "Failed to obtain sudo privileges."
            exit 1
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$SCRIPT_DIR" ]]; then
        log_error "Cannot write to script directory: $SCRIPT_DIR"
        exit 1
    fi
    
    # Detect architecture
    local arch=$(uname -m)
    log_info "Detected architecture: $arch"
    export SYSTEM_ARCH="$arch"
    
    log_success "Environment check completed successfully"
}

run_child_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/scripts/$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Child script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path"
    fi
    
    log_info "Running $script_name..."
    if "$script_path"; then
        log_success "$script_name completed successfully"
        return 0
    else
        log_error "$script_name failed"
        return 1
    fi
}

main() {
    # Initialize log file
    echo "=== Multi-Shell Setup Script Started at $(date) ===" > "$LOG_FILE"
    
    print_colored "$BLUE" "🚀 Multi-Shell Setup Script"
    print_colored "$BLUE" "================================"
    
    # Environment check
    check_environment
    
    # Tool installation phase
    if [[ "$SKIP_TOOLS" != true && "$TEST_ONLY" != true ]]; then
        log_info "Starting tool installation phase..."
        if run_child_script "install_tools.sh"; then
            log_success "Tool installation completed"
        else
            log_warning "Tool installation had some failures, continuing with shell configuration"
        fi
    else
        log_info "Skipping tool installation phase"
    fi
    
    # Shell configuration phase
    if [[ "$TEST_ONLY" != true ]]; then
        log_info "Starting shell configuration phase..."
        
        if [[ -z "$SHELL_ONLY" || "$SHELL_ONLY" == "bash" ]]; then
            run_child_script "setup_bash.sh" || log_warning "Bash setup failed"
        fi
        
        if [[ -z "$SHELL_ONLY" || "$SHELL_ONLY" == "zsh" ]]; then
            run_child_script "setup_zsh.sh" || log_warning "Zsh setup failed"
        fi
        
        if [[ -z "$SHELL_ONLY" || "$SHELL_ONLY" == "nushell" ]]; then
            run_child_script "setup_nushell.sh" || log_warning "Nushell setup failed"
        fi
        
        # Create cross-shell aliases
        run_child_script "create_aliases.sh" || log_warning "Alias creation failed"
        
        log_success "Shell configuration completed"
    else
        log_info "Skipping shell configuration phase"
    fi
    
    # Testing phase
    log_info "Starting verification tests..."
    if run_child_script "test_installation.sh"; then
        log_success "All tests passed"
    else
        log_warning "Some tests failed, check the log for details"
    fi
    
    # Final summary
    print_colored "$GREEN" ""
    print_colored "$GREEN" "🎉 Setup completed!"
    print_colored "$GREEN" "==================="
    
    if [[ ${#SUCCESSFUL_TOOLS[@]} -gt 0 ]]; then
        print_colored "$GREEN" "Successfully installed tools: ${SUCCESSFUL_TOOLS[*]}"
    fi
    
    if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
        print_colored "$YELLOW" "Failed to install: ${FAILED_TOOLS[*]}"
    fi
    
    print_colored "$BLUE" ""
    print_colored "$BLUE" "Next steps:"
    print_colored "$BLUE" "1. Restart your terminal or run: source ~/.bashrc"
    print_colored "$BLUE" "2. Try the new tools: exa, bat, zoxide, helix, etc."
    print_colored "$BLUE" "3. Switch shells: zsh, nu (nushell)"
    print_colored "$BLUE" "4. Check the log file: $LOG_FILE"
    
    echo "=== Multi-Shell Setup Script Completed at $(date) ===" >> "$LOG_FILE"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tools)
            SKIP_TOOLS=true
            shift
            ;;
        --shell)
            SHELL_ONLY="$2"
            if [[ "$SHELL_ONLY" != "bash" && "$SHELL_ONLY" != "zsh" && "$SHELL_ONLY" != "nushell" ]]; then
                log_error "Invalid shell: $SHELL_ONLY. Must be bash, zsh, or nushell"
                exit 1
            fi
            shift 2
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"