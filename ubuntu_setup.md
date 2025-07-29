# Ubuntu Server Setup Script

This script installs all necessary packages, dependencies, and binaries. It now automatically detects your server's architecture (x86_64 or aarch64) to download the correct files. Run this entire block on both servers.

## Step A: Install Base Tools and Dependencies

```bash
# --- Install Base Tools & Dependencies via apt ---
sudo apt update
# Added zsh and its plugins for the backup shell
sudo apt install -y git curl wget tree jq fzf ripgrep fd-find bat unzip build-essential lnav httpie zsh zsh-syntax-highlighting zsh-autosuggestions

# --- Create common symlinks for Ubuntu packages ---
# On Ubuntu, 'fd-find' installs as 'fdfind' and 'bat' as 'batcat'
# We create symlinks for the common names 'fd' and 'bat'
sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
sudo ln -s /usr/bin/batcat /usr/local/bin/bat

# --- Configure System-Wide PATH for Snap ---
# This ensures snap binaries are found by all shells
sudo tee /etc/profile.d/snap.sh <<'EOF'
export PATH=$PATH:/snap/bin
EOF

# --- Install Rust and Cargo Package Manager ---
curl --proto '=https' --tlsv_1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# --- Install Rust-based Tools via Cargo ---
cargo install exa zoxide git-delta duf procs tealdeer

# --- Install Specific Tools via other methods (Architecture Aware) ---
# Detect machine architecture
ARCH=$(uname -m)

# Map uname arch to asset naming conventions
HELIX_ARCH=$ARCH
LAZYDOCKER_ARCH=$ARCH
if [ "$ARCH" = "aarch64" ]; then
    LAZYDOCKER_ARCH="arm64"
fi

# Helix (Text Editor)
LATEST_HELIX=$(curl -s "https://api.github.com/repos/helix-editor/helix/releases/latest" | jq -r .tag_name)
wget "https://github.com/helix-editor/helix/releases/download/${LATEST_HELIX}/helix-${LATEST_HELIX}-${HELIX_ARCH}-linux.tar.xz"
tar -xvf "helix-${LATEST_HELIX}-${HELIX_ARCH}-linux.tar.xz"
sudo mv helix-*/hx /usr/local/bin/
# Clean up downloaded files
rm -rf "helix-${LATEST_HELIX}-${HELIX_ARCH}-linux.tar.xz" helix-*

# Zellij (Terminal Multiplexer)
cargo install --locked zellij

# lazydocker (Docker TUI)
LATEST_LAZYDOCKER=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | jq -r .tag_name)
curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LATEST_LAZYDOCKER//v/}_Linux_${LAZYDOCKER_ARCH}.tar.gz"
tar xf lazydocker.tar.gz lazydocker
sudo install lazydocker /usr/local/bin
# Clean up downloaded files
rm -f lazydocker.tar.gz lazydocker

# Install tools via Snap for simplicity and latest versions
sudo snap install dog
sudo snap install btop

# superfile (File Manager) - Installed via official script
bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"

# --- Install Latest Nushell and Starship ---
curl -fsSL https://apt.fury.io/nushell/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg
echo "deb https://apt.fury.io/nushell/ /" | sudo tee /etc/apt/sources.list.d/fury.list
sudo apt update
sudo apt install -y nushell
curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.cargo/bin"
```

## Step B: Configure Zsh Shell (Manual Method)

These commands will create a .zshrc file that sources the plugins you installed via apt.

```bash
# Create .zshrc and configure plugins and Starship
tee ~/.zshrc <<'EOF'
# Source plugins directly from apt-installed paths
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Initialize Starship Prompt
eval "$(starship init zsh)"
EOF
```

## Step C: Configure Nushell Shell

Now that everything is installed, you will start Nushell, run the configuration commands inside it, and then exit.

1. Start Nushell by typing:

```bash
nu
```

2. Your prompt will change. Now, run the following Nushell commands to configure Starship:

```nu
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
```

3. Exit Nushell to return to your Bash prompt:

```nu
exit
```

## Step D: Set Nushell as the Default Shell

Now, back in your Bash shell, run the following to make Nushell your default for future logins:

```bash
# Find the path to Nushell
NU_PATH=$(which nu)

# Add the path to /etc/shells if it's not already there
if ! grep -q "$NU_PATH" /etc/shells; then
    echo "$NU_PATH" | sudo tee -a /etc/shells
fi

# Change the shell for the current user
chsh -s "$NU_PATH"
```

*(You may be prompted for your password and will need to log out and back in for the change to take effect).*

## Step E: Verify Tool Installations

After logging back in with Nushell as your default, run these commands to verify the installations:

```nu
# Check versions of multiple tools
exa --version
bat --version
tree --version
zoxide --version
delta --version
duf --version
procs --version
tldr --version
lnav --version
# Use ^ to bypass the Nushell built-in http command and call the external httpie executable
^http --version
hx --version
zellij --version
lazydocker --version
dog --version
superfile --version
git --version
curl --version

# Test functionality
fd lazydocker
btop # (Press 'q' to quit)
tldr tar
dog google.com

# Test Zsh installation by starting it
zsh
# (You should see the Starship prompt. Type 'exit' to return to Nushell)
```

*(If all commands run and show a version number or expected output, the installation was successful).*

## Install Docker Engine

On both servers, install Docker using the official convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# Use Nushell syntax ($env.USER) since it's now the default shell
sudo usermod -aG docker $env.USER
```

*(You will need to log out and back in for the group change to take effect).*

Configure Docker's logging driver to prevent excessive log file sizes. Create or edit `/etc/docker/daemon.json`:

```bash
sudo tee /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
```

Restart Docker to apply changes:

```bash
sudo systemctl restart docker
```
