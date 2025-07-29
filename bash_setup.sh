#!/bin/sh -e

# Define color codes using tput for better compatibility
RC=$(tput sgr0)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
GREEN=$(tput setaf 2)

PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""

# Helper functions
print_colored() {
    printf "${1}%s${RC}\n" "$2"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_environment() {
    # Check for required commands
    REQUIREMENTS='curl groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            print_colored "$RED" "To run me, you need: $REQUIREMENTS"
            exit 1
        fi
    done

    # Set package manager to apt by default
    PACKAGER="apt"
    printf "Using %s\n" "$PACKAGER"

    # Determine sudo command
    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi
    printf "Using %s as privilege escalation software\n" "$SUDO_CMD"

    # Check write permissions
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        print_colored "$RED" "Can't write to $GITPATH"
        exit 1
    fi

    # Check superuser group
    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            printf "Super user group %s\n" "$SUGROUP"
            break
        fi
    done

    if ! groups | grep -q "$SUGROUP"; then
        print_colored "$RED" "You need to be a member of the sudo group to run me!"
        exit 1
    fi
}

install_dependencies() {
    # Modified list of dependencies
    DEPENDENCIES='bash bash-completion multitail fontconfig trash-cli'
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

    print_colored "$YELLOW" "Installing dependencies using apt..."
    ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}

    # Re-added font installation call
    install_font
}

install_font() {
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "Font '%s' is installed.\n" "$FONT_NAME"
    else
        printf "Installing font '%s'\n" "$FONT_NAME"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        if wget -q --spider "$FONT_URL"; then
            TEMP_DIR=$(mktemp -d)
            wget -q $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip
            unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
            mkdir -p "$FONT_DIR"/"$FONT_NAME"
            mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
            # Update the font cache
            fc-cache -fv
            rm -rf "${TEMP_DIR}"
            printf "'%s' installed successfully.\n" "$FONT_NAME"
        else
            printf "Font '%s' not installed. Font URL is not accessible.\n" "$FONT_NAME"
        fi
    fi
}

link_config() {
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    OLD_BASHRC="$USER_HOME/.bashrc"
    BASH_PROFILE="$USER_HOME/.bash_profile"
    CONFIG_DIR="$USER_HOME/.config"

    if [ -e "$OLD_BASHRC" ]; then
        print_colored "$YELLOW" "Moving old bash config file to $USER_HOME/.bashrc.bak"
        if ! mv "$OLD_BASHRC" "$USER_HOME/.bashrc.bak"; then
            print_colored "$RED" "Can't move the old bash config file!"
            exit 1
        fi
    fi
    
    # Ensure .config directory exists before linking
    mkdir -p "$CONFIG_DIR"

    print_colored "$YELLOW" "Linking new config files..."
    if ! ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || ! ln -svf "$GITPATH/starship.toml" "$CONFIG_DIR/starship.toml"; then
        print_colored "$RED" "Failed to create symbolic links"
        exit 1
    fi

    # Create .bash_profile if it doesn't exist
    if [ ! -f "$BASH_PROFILE" ]; then
        print_colored "$YELLOW" "Creating .bash_profile..."
        echo "[ -f ~/.bashrc ] && . ~/.bashrc" > "$BASH_PROFILE"
        print_colored "$GREEN" ".bash_profile created and configured to source .bashrc"
    else
        print_colored "$YELLOW" ".bash_profile already exists. Please ensure it sources .bashrc if needed."
    fi
}

# Main execution
check_environment
install_dependencies

if link_config; then
    print_colored "$GREEN" "Done!\nrestart your shell to see the changes."
else
    print_colored "$RED" "Something went wrong!"
fi