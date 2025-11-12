#!/usr/bin/env bash
# SoltrOS Helper Tool

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Detect desktop variant from /etc/os-release
detect_variant() {
    local variant_id=""
    if [ -f /etc/os-release ]; then
        # Source the os-release file to get VARIANT_ID
        source /etc/os-release
        variant_id="${VARIANT_ID:-}"
    fi

    # Default to kde if no variant detected
    if [ -z "$variant_id" ]; then
        variant_id="kde"
    fi

    echo "$variant_id"
}

show_help() {
    cat << 'EOF'
SoltrOS Helper Tool

Usage: helper [COMMAND]

INSTALL COMMANDS:
  install                   Install all SoltrOS components
  install-flatpaks          Install Flatpak applications from remote list
  install-dev-tools         Install development tools via Flatpak
  install-gaming            Install gaming tools via Flatpak
  install-multimedia        Install multimedia tools via Flatpak
  install-homebrew          Install the Homebrew package manager
  install-nix               Install the Nix package manager
  setup-nixmanager          Add the nixmanager.sh script to ~/scripts for easy Nix use
  add-helper                This adds the helper.sh alias to Bash to make it easier to access
  add-nixmanager            This adds the nixmanager.sh alias to Bash to make it easier to use Nix packages on SoltrOS
  download-appimages        Download Feishin and Ryubing to the ~/AppImages folder
  change-to-zsh             Swap shell to Zsh
  change-to-fish            Swap shell to Fish
  change-to-bash            Swap shell to Bash
  change-to-stable          Swap from Soltros OS unstable rolling to LTS rolling
  change-to-unstable        Swap from Soltros OS LTS rolling to unstable rolling
  apply-soltros-look_plasma Apply the SoltrOS theme to Plasma
  apply-soltros-look_cosmic Apply the SoltrOS theme to Cosmic
  set-hyprvibe-theme        Apply Hyprvibe theme from /etc/skel (overwrites Hyprland/Dunst/Waybar configs)
  helper-off                Turn off the helper prompt in Zsh (delete ~/.no-helper-reminder to re-enable)

SETUP COMMANDS:
  setup-git              Configure Git with user credentials and SSH signing
  setup-distrobox        Setup distrobox containers for development

CONFIGURE COMMANDS:
  enable-amdgpu-oc       Enable AMD GPU overclocking support
  toggle-session         Toggle between X11 and Wayland sessions

OTHER COMMANDS:
  update                 Update the system (rpm-ostree, flatpaks, etc.)
  clean                  Clean up the system
  distrobox              Manage distrobox containers
  toolbox                Manage toolbox containers
  help                   Show this help message
  list                   List all available commands

If no command is provided, the help will be shown.
EOF
}

list_commands() {
    echo "Available commands:"
    echo "  install install-flatpaks uninstall-flatpaks install-dev-tools install-gaming install-multimedia"
    echo "  install-homebrew install-nix setup-nixmanager add-helper add-nixmanager download-appimages"
    echo "  change-to-zsh change-to-fish change-to-bash change-to-stable change-to-unstable"
    echo "  apply-soltros-look_plasma apply-soltros-look_cosmic set-hyprvibe-theme helper-off"
    echo "  setup-git setup-distrobox enable-amdgpu-oc toggle-session"
    echo "  update clean distrobox toolbox help list"
}

# ───────────────────────────────────────────────
# INSTALL FUNCTIONS
# ───────────────────────────────────────────────

soltros_install() {
    print_header "Installing all SoltrOS components"
    soltros_install_flatpaks
}

soltros_install_flatpaks() {
    print_header "Installing Flatpak applications from remote list"

    print_info "Setting up Flathub repository..."
    if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        print_error "Failed to add Flathub repository"
        return 1
    fi

    # Detect desktop variant
    local variant_id=$(detect_variant)

    # Determine which flatpak list to use based on variant
    local flatpak_url=""
    case "$variant_id" in
        kde)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_kde"
            print_info "Detected KDE Plasma variant"
            ;;
        cosmic)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_cosmic"
            print_info "Detected COSMIC variant"
            ;;
        gnome)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_gnome"
            print_info "Detected Gnome variant"
            ;;
        hyprvibe)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_hyprvibe"
            print_info "Detected Hyprvibe variant"
            ;;
        *)
            print_warning "Unknown variant '$variant_id', defaulting to KDE"
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_kde"
            ;;
    esac

    print_info "Downloading flatpak list for $variant_id and installing..."
    if xargs -a <(curl --retry 3 -sL "$flatpak_url") flatpak --system -y install --reinstall; then
        print_success "Flatpaks installation complete for $variant_id variant"
    else
        print_error "Failed to install flatpaks"
        return 1
    fi
}

soltros_uninstall_flatpaks() {
    print_header "Uninstalling Flatpak applications from variant list"

    # Detect desktop variant
    local variant_id=$(detect_variant)

    # Determine which flatpak list to use based on variant
    local flatpak_url=""
    case "$variant_id" in
        kde)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_kde"
            print_info "Detected KDE Plasma variant"
            ;;
        cosmic)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_cosmic"
            print_info "Detected COSMIC variant"
            ;;
        gnome)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_gnome"
            print_info "Detected Gnome variant"
            ;;
        hyprvibe)
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_hyprvibe"
            print_info "Detected Hyprvibe variant"
            ;;
        *)
            print_warning "Unknown variant '$variant_id', defaulting to KDE"
            flatpak_url="https://raw.githubusercontent.com/soltros/Soltros-OS-Components/refs/heads/master/flatpaks_kde"
            ;;
    esac

    print_info "Downloading flatpak list for $variant_id and uninstalling..."
    if xargs -a <(curl --retry 3 -sL "$flatpak_url") flatpak --system -y uninstall; then
        print_success "Flatpaks uninstallation complete for $variant_id variant"
    else
        print_error "Failed to uninstall flatpaks"
        return 1
    fi
}

change_to_stable() {
    # Usage:
    #   change_to_stable                  # interactive prompt
    #   change_to_stable kde|plasma       # non-interactive
    #   change_to_stable cosmic
    #   change_to_stable hyprvibe

    # Normalize a string to lowercase alphanumerics/underscores
    _norm() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g'; }

    local choice_raw="${1:-}"
    local choice norm choice_label image_suffix variant variant_id

    if [[ -z "$choice_raw" ]]; then
        echo "Select SoltrOS LTS desktop:"
        echo "  1) KDE Plasma (default)"
        echo "  2) COSMIC"
        echo "  3) Gnome"
        echo "  4) Hyprvibe"
        echo "  5) Cancel"

        printf "Enter a number [1]: "
        read -r choice
        case "${choice:-1}" in
            1|'') norm="kde"    ; choice_label="KDE Plasma" ; image_suffix="soltros-os_lts"        ; variant="KDE Plasma" ; variant_id="kde"    ;;
            2)    norm="cosmic" ; choice_label="COSMIC"     ; image_suffix="soltros-lts_cosmic" ; variant="COSMIC"     ; variant_id="cosmic" ;;
            3)    norm="gnome" ; choice_label="Gnome" ; image_suffix="soltros-os-lts_gnome" ; variant="gnome"     ; variant_id="gnome" ;;
            4)    norm="hyprvibe" ; choice_label="Hyprvibe" ; image_suffix="soltros-os-lts_hyprvibe" ; variant="hyprvibe"     ; variant_id="hyprvibe" ;;
            5)    echo "Canceled."; return 1 ;;
            *)    echo "Invalid selection."; return 2 ;;
        esac
    else
        norm="$(_norm "$choice_raw")"
        case "$norm" in
            kde|plasma|kde_plasma|default)
                choice_label="KDE Plasma"
                image_suffix="soltros-os_lts"
                variant="KDE Plasma"
                variant_id="kde"
                ;;
            cosmic)
                choice_label="COSMIC"
                image_suffix="soltros-lts_cosmic"
                variant="COSMIC"
                variant_id="cosmic"
                ;;
            gnome)
                choice_label="Gnome"
                variant="gnome"
                image_suffix="soltros-os-lts_gnome"
                variant_id="gnome"
                ;;
            hyprvibe)
                choice_label="Hyprvibe"
                variant="hyprvibe"
                image_suffix="soltros-os-lts_hyprvibe"
                variant_id="hyprvibe"
                ;;
            *)
                echo "Unknown desktop '$choice_raw'. Use: kde|cosmic|gnome|hyprvibe"
                return 2
                ;;
        esac
    fi

    local target_ref="ghcr.io/soltros/${image_suffix}:latest"

    print_header "Swapping to ${choice_label} LTS"
    print_info  "Target image: ${target_ref}"

    if sudo bootc switch "${target_ref}"; then
        print_success "Swapped releases successfully! Updating /etc/os-release…"

        # Prepare new os-release in a temp file
        tmp_osrel="$(mktemp /tmp/os-release.XXXXXX)"
        cat >"$tmp_osrel" <<EOF
NAME="SoltrOS"
VERSION="Long-Term Support (LTS)"
ID=fedora
ID_LIKE=fedora
VERSION_ID=LTS
PLATFORM_ID="platform:f42"
PRETTY_NAME="SoltrOS Long-Term Support (LTS)"
ANSI_COLOR="0;36"
CPE_NAME="cpe:/o:fedoraproject:fedora:42"
HOME_URL="https://github.com/soltros/soltros-os"
SUPPORT_URL="https://github.com/soltros/soltros-os"
BUG_REPORT_URL="https://github.com/soltros/soltros-os/issues"
VARIANT="${variant}"
VARIANT_ID=${variant_id}
EOF

        # If /etc/os-release is a symlink, replace it with a real file
        if [ -L /etc/os-release ]; then
            sudo rm -f /etc/os-release
        fi

        # Backup existing file once (best-effort)
        if [ -e /etc/os-release ] && [ ! -e /etc/os-release.bak ]; then
            sudo cp -p /etc/os-release /etc/os-release.bak || true
        fi

        # Install atomically with correct ownership/permissions
        sudo install -o root -g root -m 0644 "$tmp_osrel" /etc/os-release
        rm -f "$tmp_osrel"

        # Restore SELinux context if available
        if command -v restorecon >/dev/null 2>&1; then
            sudo restorecon /etc/os-release
        fi

        echo
        print_success "Updated /etc/os-release (VARIANT=${variant_id}). Reboot recommended."
    else
        print_error "Failed to swap releases."
        return 1
    fi
}

change_to_unstable() {
    # Usage:
    #   change_to_unstable                  # interactive prompt
    #   change_to_unstable kde|plasma       # non-interactive
    #   change_to_unstable cosmic
    #   change_to_unstable hyprvibe

    # Normalize a string to lowercase alphanumerics/underscores
    _norm() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g'; }

    local choice_raw="${1:-}"
    local choice norm choice_label image_suffix variant variant_id

    if [[ -z "$choice_raw" ]]; then
        echo "Select SoltrOS Unstable desktop:"
        echo "  1) KDE Plasma (default)"
        echo "  2) COSMIC"
        echo "  3) Gnome"
        echo "  4) Hyprvibe"
        echo "  5) Cancel"
        printf "Enter a number [1]: "
        read -r choice
        case "${choice:-1}" in
            1|'') norm="kde"    ; choice_label="KDE Plasma" ; image_suffix="soltros-os"                   ; variant="KDE Plasma" ; variant_id="kde"    ;;
            2)    norm="cosmic" ; choice_label="COSMIC"     ; image_suffix="soltros-unstable_cosmic"  ; variant="COSMIC"     ; variant_id="cosmic" ;;
            3)    norm="gnome" ; choice_label="Gnome" ; image_suffix="soltros-os-unstable_gnome" ; variant="gnome"     ; variant_id="gnome" ;;
            4)    norm="hyprvibe" ; choice_label="Hyprvibe" ; image_suffix="soltros-os-unstable_hyprvibe" ; variant="hyprvibe"     ; variant_id="hyprvibe" ;;
            5)    echo "Canceled."; return 1 ;;
            *)    echo "Invalid selection."; return 2 ;;
        esac
    else
        norm="$(_norm "$choice_raw")"
        case "$norm" in
            kde|plasma|kde_plasma|default)
                choice_label="KDE Plasma"
                image_suffix="soltros-os"
                variant="KDE Plasma"
                variant_id="kde"
                ;;
            cosmic)
                choice_label="COSMIC"
                image_suffix="soltros-unstable_cosmic"
                variant="COSMIC"
                variant_id="cosmic"
                ;;
            gnome)
                choice_label="Gnome"
                variant="gnome"
                image_suffix="soltros-os-unstable_gnome"
                variant_id="gnome"
                ;;
            hyprvibe)
                choice_label="Hyprvibe"
                variant="hyprvibe"
                image_suffix="soltros-os-unstable_hyprvibe"
                variant_id="hyprvibe"
                ;;
            *)
                echo "Unknown desktop '$choice_raw'. Use: kde|cosmic|gnome|hyprvibe"
                return 2
                ;;
        esac
    fi

    local target_ref="ghcr.io/soltros/${image_suffix}:latest"

    print_header "Swapping to ${choice_label} Unstable"
    print_info  "Target image: ${target_ref}"

    if sudo bootc switch "${target_ref}"; then
        print_success "Swapped releases successfully! Updating /etc/os-release…"

        # Prepare new os-release in a temp file
        tmp_osrel="$(mktemp /tmp/os-release.XXXXXX)"
        cat >"$tmp_osrel" <<EOF
NAME="SoltrOS"
VERSION="Rolling Rocket (Unstable)"
ID=fedora
ID_LIKE=fedora
VERSION_ID=Unstable
PLATFORM_ID="platform:f43"
PRETTY_NAME="SoltrOS Rolling Rocket (Unstable)"
ANSI_COLOR="0;36"
CPE_NAME="cpe:/o:fedoraproject:fedora:43"
HOME_URL="https://github.com/soltros/soltros-os"
SUPPORT_URL="https://github.com/soltros/soltros-os"
BUG_REPORT_URL="https://github.com/soltros/soltros-os/issues"
VARIANT="${variant}"
VARIANT_ID=${variant_id}
EOF

        # If /etc/os-release is a symlink, replace it with a real file
        if [ -L /etc/os-release ]; then
            sudo rm -f /etc/os-release
        fi

        # Backup existing file once (best-effort)
        if [ -e /etc/os-release ] && [ ! -e /etc/os-release.bak ]; then
            sudo cp -p /etc/os-release /etc/os-release.bak || true
        fi

        # Install atomically with correct ownership/permissions
        sudo install -o root -g root -m 0644 "$tmp_osrel" /etc/os-release
        rm -f "$tmp_osrel"

        # Restore SELinux context if available
        if command -v restorecon >/dev/null 2>&1; then
            sudo restorecon /etc/os-release
        fi

        echo
        print_success "Updated /etc/os-release (VARIANT=${variant_id}). Reboot recommended."
    else
        print_error "Failed to swap releases."
        return 1
    fi
}


install_homebrew() {
    print_header "Setting up Homebrew"
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        # Add Homebrew to PATH (the installer usually tells you the correct path)
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        print_success "Brew package manager installed!"
        echo "Please restart your terminal or run 'source ~/.bashrc' to use brew"
    else
        print_error "Failed to install the Brew package manager"
        return 1
    fi
}

install_nix() {
    print_header "Setting up Nix via Determinite Nix installer."
    if /bin/bash /nix/determinate-nix-installer.sh install && \
        mkdir -p ~/.config/nixpkgs-soltros/ && \
        wget https://raw.githubusercontent.com/soltros/random-stuff/refs/heads/main/configs/flake.nix -O ~/.config/nixpkgs-soltros/flake.nix; then
        print_success "Successfully installed and enabled the Nix package manager on SoltrOS."
    else
        print_error "Failed to install and enable the Nix package manager on SoltrOS."
        return 1
    fi
}

setup_nixmanager() {
    print_header "Setting up the nixmanager.sh script."
    if mkdir -p ~/scripts/ && \
        cp /usr/share/soltros/bin/nixmanager.sh ~/scripts/ && \
        chmod +x ~/scripts/nixmanager.sh; then
        print_success "nixmanager.sh installed! Please run sh ~/scripts/nixmanager.sh, or nixmanager in the Zsh shell!"
    else
        print_error "Failed to setup nixmanager.sh"
        return 1
    fi
}

add_helper() {
    local bashrc="$HOME/.bashrc"
    local alias_cmd='alias helper="sh /usr/share/soltros/bin/helper.sh"'

    # Check if the alias already exists
    if grep -Fxq "$alias_cmd" "$bashrc"; then
        echo "✓ Alias already exists in $bashrc"
    else
        echo "$alias_cmd" >> "$bashrc"
        echo "✓ Alias added to $bashrc"
    fi
}

add_nixmanager() {
    local bashrc="$HOME/.bashrc"
    local alias_cmd='alias nixmanager="sh /usr/share/soltros/bin/nixmanager.sh"'

    #Check if the alias already exists
    if grep -Fxq "$alias_cmd" "$bashrc"; then
        echo "✓ Alias already exists in $bashrc"
    else
        echo "$alias_cmd" >> "$bashrc"
        echo "✓ Alias added to $bashrc"
    fi
}

apply_soltros_look_plasma() {
    print_header "Applying SoltrOS theme for Plasma"

    if [ -f /usr/share/soltros/bin/soltros-os-theme_plasma.sh ]; then
        print_info "Running theme script..."
        sh /usr/share/soltros/bin/soltros-os-theme_plasma.sh
    else
        print_error "Theme script not found at /usr/share/soltros/bin/soltros-os-theme_plasma.sh"
        return 1
    fi
}

apply_soltros_look_cosmic() {
    print_header "Applying SoltrOS theme for COSMIC"

    if [ -f /usr/share/soltros/bin/soltros-os-theme_cosmic.sh ]; then
        print_info "Running theme script..."
        sh /usr/share/soltros/bin/soltros-os-theme_cosmic.sh
    else
        print_error "Theme script not found at /usr/share/soltros/bin/soltros-os-theme_cosmic.sh"
        return 1
    fi
}

change_to_fish() {
    print_header "Changing to Fish"
    if chsh -s /usr/bin/fish; then
        # Backup existing config if it exists
        if [ -f ~/.config/fish/config.fish ]; then
            print_info "Backing up existing Fish config..."
            cp ~/.config/fish/config.fish ~/.config/fish/config.fish.bak
        fi
        wget https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/system_files/etc/skel/.config/fish/config.fish -O ~/.config/fish/config.fish
        print_success "Changed shell to Fish"
    else
        print_error "Failed to change shell to Fish"
        return 1
    fi
}

change_to_zsh() {
    print_header "Changing shell to Zsh"
    if chsh -s /usr/bin/zsh; then
        print_success "Changed shell to Zsh"
    else
        print_error "Failed to change shell to Zsh"
        return 1
    fi
}

change_to_bash() {
    print_header "Changing shell to Bash"
    if chsh -s /usr/bin/bash; then
        # Backup existing bashrc if it exists
        if [ -f ~/.bashrc ]; then
            print_info "Backing up existing Bash config..."
            cp ~/.bashrc ~/.bashrc.bak
        fi
        wget https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/system_files/etc/skel/.bashrc -O ~/.bashrc
        print_success "Changed shell to Bash."
    else
        print_error "Failed to change to Bash."
        return 1
    fi
}

set_hyprvibe_theme() {
    print_header "Setting Hyprvibe Theme from /etc/skel"

    print_warning "This will overwrite your existing Hyprland, Dunst, and Waybar configurations!"
    print_warning "All current configs for these applications will be replaced with defaults from /etc/skel"
    echo
    read -p "Do you want to continue? (Y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled by user"
        return 0
    fi

    print_info "Copying configurations from /etc/skel to $HOME..."

    # Copy all configs from /etc/skel, forcing overwrite
    if sudo cp -rf /etc/skel/. "$HOME/"; then
        print_success "Hyprvibe theme configurations applied successfully!"
        print_info "Hyprland, Dunst, and Waybar configs have been updated"
        print_info "You may need to restart your session for all changes to take effect"
    else
        print_error "Failed to copy configurations from /etc/skel"
        return 1
    fi
}

install_dev_tools() {
    print_header "Installing development tools via Flatpak"

    print_info "Installing development tools..."
    if flatpak install -y flathub \
        com.visualstudio.code \
        io.podman_desktop.PodmanDesktop \
        rest.insomnia.Insomnia \
        com.getpostman.Postman \
        io.dbeaver.DBeaverCommunity; then
        print_success "Development tools installed!"
    else
        print_error "Failed to install development tools"
        return 1
    fi
}

install_gaming() {
    print_header "Installing gaming applications via Flatpak"

    print_info "Installing gaming applications..."
    if flatpak install -y flathub \
        com.valvesoftware.Steam \
        com.heroicgameslauncher.hgl \
        org.bottles.Bottles \
        net.lutris.Lutris \
        com.obsproject.Studio \
        com.discordapp.Discord; then
        print_success "Gaming setup complete!"
    else
        print_error "Failed to install gaming applications"
        return 1
    fi
}

download_appimages() {
    print_header "Downloading AppImages"

    print_info "Creating AppImages directory..."
    if ! mkdir -p ~/AppImages/; then
        print_error "Failed to create AppImages directory"
        return 1
    fi

    print_info "Downloading Feishin..."
    if ! wget https://github.com/jeffvli/feishin/releases/download/v0.17.0/Feishin-0.17.0-linux-x86_64.AppImage -O ~/AppImages/Feishin-0.17.0-linux-x86_64.AppImage; then
        print_warning "Failed to download Feishin AppImage"
    fi

    print_info "Downloading Ryujinx..."
    if ! wget https://git.ryujinx.app/api/v4/projects/1/packages/generic/Ryubing/1.3.2/ryujinx-1.3.2-x64.AppImage -O ~/AppImages/ryujinx-1.3.2-x64.AppImage; then
        print_warning "Failed to download Ryujinx AppImage"
    fi

    print_success "AppImage download process complete. Check ~/AppImages/ for downloaded files."
}

install_multimedia() {
    print_header "Installing multimedia applications via Flatpak"

    print_info "Installing multimedia applications..."
    if flatpak install -y flathub \
        org.audacityteam.Audacity \
        org.blender.Blender \
        org.gimp.GIMP \
        org.inkscape.Inkscape \
        org.kde.kdenlive \
        com.spotify.Client \
        org.videolan.VLC; then
        print_success "Multimedia tools installed!"
    else
        print_error "Failed to install multimedia tools"
        return 1
    fi
}

helper_off() {
    print_header "Disabling helper prompt"

    if touch ~/.no-helper-reminder; then
        print_success "Helper prompt disabled. Delete ~/.no-helper-reminder to re-enable."
    else
        print_error "Failed to disable helper prompt"
        return 1
    fi
}

# ───────────────────────────────────────────────
# SETUP FUNCTIONS
# ───────────────────────────────────────────────

soltros_setup_git() {
    print_header "Setting up Git configuration"
    
    print_info "Setting up Git config..."
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email

    git config --global color.ui true
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"

    if [ ! -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        print_info "SSH key not found. Generating..."
        ssh-keygen -t ed25519 -C "$git_email"
    fi

    print_info "Your SSH public key:"
    cat "${HOME}/.ssh/id_ed25519.pub"

    git config --global gpg.format ssh
    git config --global user.signingkey "key::$(cat ${HOME}/.ssh/id_ed25519.pub)"
    git config --global commit.gpgSign true

    print_info "Setting up Git aliases..."
    git config --global alias.add-nowhitespace '!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -'
    git config --global alias.graph 'log --decorate --oneline --graph'
    git config --global alias.ll 'log --oneline'
    git config --global alias.prune-all '!git remote | xargs -n 1 git remote prune'
    git config --global alias.pullr 'pull --rebase'
    git config --global alias.pushall '!git remote | xargs -L1 git push --all'
    git config --global alias.pushfwl 'push --force-with-lease'

    git config --global feature.manyFiles true
    git config --global init.defaultBranch main
    git config --global core.excludesFile '~/.gitignore'
    
    print_success "Git setup complete"
}

setup_distrobox() {
    print_header "Setting up distrobox containers for development"
    
    if ! command -v distrobox &> /dev/null; then
        print_error "Distrobox is not installed"
        exit 1
    fi
    
    # Ubuntu container for general development
    if ! distrobox list | grep -q "ubuntu-dev"; then
        print_info "Creating Ubuntu development container..."
        distrobox create --name ubuntu-dev --image ubuntu:latest
        distrobox enter ubuntu-dev -- sudo apt update && sudo apt install -y build-essential git curl wget
    else
        print_info "Ubuntu development container already exists"
    fi
    
    # Arch container for AUR packages
    if ! distrobox list | grep -q "arch-dev"; then
        print_info "Creating Arch development container..."
        distrobox create --name arch-dev --image archlinux:latest
        distrobox enter arch-dev -- sudo pacman -Syu --noconfirm base-devel git
    else
        print_info "Arch development container already exists"
    fi
    
    print_success "Distrobox setup complete!"
}

# ───────────────────────────────────────────────
# CONFIGURE FUNCTIONS
# ───────────────────────────────────────────────

soltros_enable_amdgpu_oc() {
    print_header "Enabling AMD GPU overclocking support"
    
    if ! command -v rpm-ostree &> /dev/null; then
        print_error "rpm-ostree is not available"
        exit 1
    fi
    
    print_info "Enabling AMD GPU overclocking..."
    
    if ! rpm-ostree kargs | grep -q "amdgpu.ppfeaturemask="; then
        sudo rpm-ostree kargs --append "amdgpu.ppfeaturemask=0xFFF7FFFF"
        print_success "Kernel argument set. Reboot required to take effect."
    else
        print_warning "Overclocking already enabled"
    fi
}

toggle_session() {
    print_header "Session Toggle Information"

    current_session=$(echo "$XDG_SESSION_TYPE")
    print_info "Current session: $current_session"
    
    if [ "$current_session" = "wayland" ]; then
        print_info "To switch to X11:"
        echo "1. Log out of your current session"
        echo "2. On the login screen, click the gear icon"
        echo "3. Select the X11 session option"
        echo "4. Log back in"
    else
        print_info "To switch to Wayland:"
        echo "1. Log out of your current session"
        echo "2. On the login screen, click the gear icon"
        echo "3. Select the Wayland session option"
        echo "4. Log back in"
    fi
}

# ───────────────────────────────────────────────
# UNIVERSAL BLUE FUNCTIONS
# ───────────────────────────────────────────────

ublue_update() {
    print_header "Updating the system"
       
    print_info "Updating SoltrOS with Bootc..."
    sudo bootc upgrade || true
    
    print_info "Updating Flatpaks..."
    flatpak update -y || true
    
    if command -v distrobox &> /dev/null; then
        print_info "Updating distrobox containers..."
        distrobox upgrade --all || true
    fi
    
    if command -v nix &> /dev/null; then
    print_info "Updating SoltrOS Nix Flake..."
    
    # Navigate to flake directory and update it
    cd ~/.config/nixpkgs-soltros || { echo "Failed to navigate to flake directory"; return 1; }
    
    # Update the flake inputs
    nix flake update
    
    # Upgrade all packages by index (0-6 based on your output)
    for i in {0..20}; do
        nix profile upgrade "$i" 2>/dev/null || true
    done
    
    print_info "Flake and packages updated successfully"
    fi
    
    print_success "System update complete"
}

ublue_clean() {
    print_header "Cleaning up the system"
    
    print_info "Cleaning rpm-ostree..."
    sudo rpm-ostree cleanup -p || true
    
    print_info "Cleaning Flatpak cache..."
    flatpak uninstall --unused -y || true
    
    print_info "Cleaning system cache..."
    sudo journalctl --vacuum-time=7d || true
    
    print_success "System cleanup complete"
}

ublue_distrobox() {
    print_header "Managing distrobox containers"
    
    if ! command -v distrobox &> /dev/null; then
        print_error "Distrobox is not installed"
        exit 1
    fi
    
    print_info "Available distrobox containers:"
    distrobox list
}

ublue_toolbox() {
    print_header "Managing toolbox containers"
    
    if ! command -v toolbox &> /dev/null; then
        print_error "Toolbox is not installed"
        exit 1
    fi
    
    print_info "Available toolbox containers:"
    toolbox list
}

# ───────────────────────────────────────────────
# MAIN SCRIPT LOGIC
# ───────────────────────────────────────────────

main() {
    case "${1:-help}" in
        "install")
            soltros_install
            ;;
        "install-flatpaks")
            soltros_install_flatpaks
            ;;
        "uninstall-flatpaks")
            soltros_uninstall_flatpaks
            ;;
        "install-dev-tools")
            install_dev_tools
            ;;
        "install-gaming")
            install_gaming
            ;;
        "install-multimedia")
            install_multimedia
            ;;
        "install-homebrew")
            install_homebrew
            ;;
        "install-nix")
            install_nix
            ;;
        "setup-nixmanager")
            setup_nixmanager
            ;;
        "apply-soltros-look_plasma")
            apply_soltros_look_plasma
            ;;
        "apply-soltros-look_cosmic")
            apply_soltros_look_cosmic
            ;;
        "add-helper")
            add_helper
            ;;
        "add-nixmanager")
            add_nixmanager
            ;;
        "change-to-zsh")
            change_to_zsh
            ;;
        "change-to-fish")
            change_to_fish
            ;;
        "change-to-bash")
            change_to_bash
            ;;
        "change-to-unstable")
            change_to_unstable
            ;;
        "change-to-stable")
            change_to_stable
            ;;
        "set-hyprvibe-theme")
            set_hyprvibe_theme
            ;;
        "download-appimages")
            download_appimages
            ;;
        "helper-off")
            helper_off
            ;;
        "setup-git")
            soltros_setup_git
            ;;
        "setup-distrobox")
            setup_distrobox
            ;;
        "enable-amdgpu-oc")
            soltros_enable_amdgpu_oc
            ;;
        "toggle-session")
            toggle_session
            ;;
        "update")
            ublue_update
            ;;
        "clean")
            ublue_clean
            ;;
        "distrobox")
            ublue_distrobox
            ;;
        "toolbox")
            ublue_toolbox
            ;;
        "list")
            list_commands
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'helper' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"